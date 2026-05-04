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
workspace_tmp=$(mktemp "${TMPDIR:-/tmp}/artemis-workspace.XXXXXX.json")
scripts/artemis-dry-run.sh --input "$input" --json >"$tmp"
scripts/artemis-workspace.sh --input "$input" --ticket "$ticket" --json >"$workspace_tmp"

if ! grep -q '"readiness": "ready"' "$workspace_tmp"; then
  echo "ticket $ticket does not have ready workspace readiness; see workspace plan:" >&2
  cat "$workspace_tmp" >&2
  rm -f "$tmp" "$workspace_tmp"
  exit 3
fi

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
cp "$workspace_tmp" "$attempt_dir/workspace.json"
rm -f "$tmp" "$workspace_tmp"

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
- Workspace plan: $attempt_dir/workspace.json
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
- Workspace readiness required.
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

python3 - "$attempt_dir" "$ticket" "$SAFE_TICKET" "$TITLE" "$EXEC_PACK" "$ARTIFACT_ROOT" "$timestamp" "$execute" "$code" "$command" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

(
    attempt_dir,
    ticket,
    safe_ticket,
    title,
    exec_pack,
    artifact_root,
    timestamp,
    execute,
    code,
    command,
) = sys.argv[1:11]

attempt_path = Path(attempt_dir)
attempt_id = attempt_path.name
event_id_prefix = "evt_" + attempt_id.lower().replace("_", "-")
generated_at = now_utc()
exit_code = int(code)
executed = execute == "1"

workspace_payload = json.loads((attempt_path / "workspace.json").read_text(encoding="utf-8"))
workspace = workspace_payload["workspaces"][0]["workspace"]

logs = [
    f"{attempt_dir}/dry-run.json",
    f"{attempt_dir}/workspace.json",
    f"{attempt_dir}/RUNNER.md",
    f"{attempt_dir}/ENVIRONMENT.md",
    f"{attempt_dir}/COMMAND.txt",
    f"{attempt_dir}/RESULT.md",
]

producer = {
    "adapter": "local_runner",
    "name": "scripts/artemis-runner.sh",
    "mode": "supervised",
}
runner = {
    "kind": "codex_cli",
    "attempt_id": attempt_id,
    "command": command,
}
common_payload = {
    "attempt_id": attempt_id,
    "execute": executed,
    "command": command,
    "workspace": workspace,
    "artifact_root": artifact_root,
}

events = []

planned = event(
    event_id=f"{event_id_prefix}_planned",
    event_type="runner.attempt_planned",
    generated_at=generated_at,
    producer=producer,
    ticket=ticket,
    title=title,
    exec_pack=exec_pack,
    artifact_root=attempt_dir,
    state_from="ready",
    state_to="running",
    runner=runner,
    logs=logs,
    payload={
        **common_payload,
        "reason": "Supervised runner attempt planned with workspace readiness.",
    },
)
planned["subject"]["branch"] = workspace["branch"]
planned["subject"]["worktree"] = workspace["worktree_path"]
events.append(planned)

if executed:
    started = event(
        event_id=f"{event_id_prefix}_started",
        event_type="runner.attempt_started",
        generated_at=generated_at,
        producer=producer,
        ticket=ticket,
        title=title,
        exec_pack=exec_pack,
        artifact_root=attempt_dir,
        state_from="running",
        state_to="running",
        runner=runner,
        logs=logs,
        payload={
            **common_payload,
            "reason": "Supervised runner command started.",
        },
    )
    started["subject"]["branch"] = workspace["branch"]
    started["subject"]["worktree"] = workspace["worktree_path"]
    events.append(started)

completed_state = "review" if exit_code == 0 else "blocked"
completed = event(
    event_id=f"{event_id_prefix}_completed",
    event_type="runner.attempt_completed",
    generated_at=generated_at,
    producer=producer,
    ticket=ticket,
    title=title,
    exec_pack=exec_pack,
    artifact_root=attempt_dir,
    state_from="running",
    state_to=completed_state,
    runner=runner,
    severity="info" if exit_code == 0 else "error",
    logs=logs,
    payload={
        **common_payload,
        "exit_code": exit_code,
        "command_log": f"{attempt_dir}/COMMAND.txt",
        "reason": (
            "Supervised runner command completed."
            if executed
            else "Supervised runner plan completed without command execution."
        ),
    },
)
completed["subject"]["branch"] = workspace["branch"]
completed["subject"]["worktree"] = workspace["worktree_path"]
events.append(completed)

write_event_log(
    attempt_path / "events.json",
    event_log(source="scripts/artemis-runner.sh", generated_at=generated_at, events=events),
)
PY

if [ "$code" -ne 0 ]; then
  echo "runner command failed with exit code $code; see $attempt_dir/COMMAND.txt" >&2
  exit "$code"
fi

echo "$attempt_dir"
