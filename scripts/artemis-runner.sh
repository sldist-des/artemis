#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

ticket=""
command=""
execute=0
input="control-plane/tasks.json"
artifact_root_override=""

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-runner.sh --ticket TKT-000 --command "cmd" [--execute] [--input path] [--artifact-root path]

Without --execute, the runner only records a supervised execution plan.
With --execute, it runs the command after dry-run eligibility and guard checks.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ticket)
      ticket="${2:-}"
      if [ -z "$ticket" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --command)
      command="${2:-}"
      if [ -z "$command" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --execute)
      execute=1
      shift
      ;;
    --input)
      input="${2:-}"
      if [ -z "$input" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --artifact-root)
      artifact_root_override="${2:-}"
      if [ -z "$artifact_root_override" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ -z "$ticket" ] || [ -z "$command" ]; then
  usage
  exit 2
fi

case "$command" in
  *"git push"*|*"git merge"*|*"git pull"*|*"gh "*|*"gh	"*|*"curl "*|*"wget "*|*"scp "*|*"ssh "*|*"rsync "*|*"rm -rf"*|*"rm -fr"*|*"docker push"*|*"kubectl "*|*"terraform apply"*|*"firebase deploy"*|*"vercel "*|*"netlify "*)
    echo "blocked command: remote, destructive, or deployment-like command requires Human Gate" >&2
    exit 3
    ;;
esac

tmp=$(mktemp "${TMPDIR:-/tmp}/artemis-runner.XXXXXX.json")
scripts/artemis-dry-run.sh --input "$input" --json >"$tmp"

metadata=$(python3 - "$tmp" "$input" "$ticket" <<'PY'
import json
import os
import re
import shlex
import sys

dry_run_path, input_path, ticket = sys.argv[1:4]

with open(dry_run_path, "r", encoding="utf-8") as handle:
    dry_run = json.load(handle)

with open(input_path, "r", encoding="utf-8") as handle:
    tasks_payload = json.load(handle)

decision = next((item for item in dry_run.get("decisions", []) if item.get("ticket") == ticket), None)
task = next((item for item in tasks_payload.get("tasks", []) if item.get("ticket") == ticket), None)

if decision is None or task is None:
    raise SystemExit(f"ticket not found in task source: {ticket}")

if decision.get("decision") != "eligible":
    raise SystemExit(
        f"ticket {ticket} is not eligible: {decision.get('decision')} - {decision.get('reason')}"
    )

evidence = str(task.get("evidence", "artifacts/artemis-local-runner/run-01/STATUS.md"))
if evidence.endswith(".md"):
    artifact_root = os.path.dirname(evidence)
else:
    artifact_root = evidence
if not artifact_root.startswith("artifacts/"):
    artifact_root = f"artifacts/{ticket.lower()}/run-01"

safe_ticket = re.sub(r"[^A-Za-z0-9_.-]+", "-", ticket.lower()).strip("-")
for key, value in {
    "ARTIFACT_ROOT": artifact_root,
    "SAFE_TICKET": safe_ticket,
    "EXEC_PACK": task.get("exec_pack", ""),
    "TITLE": task.get("title", ""),
}.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)

eval "$metadata"

if [ -n "$artifact_root_override" ]; then
  ARTIFACT_ROOT="$artifact_root_override"
fi

timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
attempt_dir="$ARTIFACT_ROOT/attempts/$timestamp-$$-$SAFE_TICKET"
mkdir -p "$attempt_dir"

cp "$tmp" "$attempt_dir/dry-run.json"
rm -f "$tmp"

cat >"$attempt_dir/ENVIRONMENT.md" <<EOF
# ENVIRONMENT - $ticket

- Generated at: $timestamp
- Repository: $root
- Ticket: $ticket
- Exec Pack: $EXEC_PACK
- Execute mode: $execute
- Branch: $(git branch --show-current 2>/dev/null || true)
- Head: $(git rev-parse --short HEAD 2>/dev/null || true)
- Worktree status before: $(git status --short | wc -l | tr -d ' ')
EOF

cat >"$attempt_dir/RUNNER.md" <<EOF
# RUNNER - $ticket

## Title

$TITLE

## Command

\`\`\`bash
$command
\`\`\`

## Mode

$(if [ "$execute" -eq 1 ]; then echo "execute"; else echo "plan-only"; fi)

## Guardrails

- Dry-run eligibility required.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
EOF

if [ "$execute" -eq 1 ]; then
  set +e
  sh -c "$command" >"$attempt_dir/COMMAND.txt" 2>&1
  code=$?
  set -e
else
  code=0
  printf 'plan-only: command was not executed\n' >"$attempt_dir/COMMAND.txt"
fi

cat >"$attempt_dir/RESULT.md" <<EOF
# RESULT - $ticket

- Exit code: $code
- Command log: $attempt_dir/COMMAND.txt
EOF

if [ "$code" -ne 0 ]; then
  echo "runner command failed with exit code $code; see $attempt_dir/COMMAND.txt" >&2
  exit "$code"
fi

echo "$attempt_dir"
