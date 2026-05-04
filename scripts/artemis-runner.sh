#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

ticket=""
command=""
execute=0
input="control-plane/tasks.json"
artifact_root_override=""
use_workspace=0
attempt_purpose="run"
retry_of=""

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-runner.sh --ticket TKT-000 --command "cmd" [--execute] [--use-workspace] [--attempt-purpose run|validation|fix|retry] [--retry-of attempt] [--input path] [--artifact-root path]

Without --execute, the runner only records a supervised execution plan.
With --execute, it runs the command after dry-run eligibility and guard checks.
With --use-workspace, --execute runs the command inside the materialized worktree for the ticket.
With --retry-of, the attempt records the previous attempt it is responding to.
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
    --use-workspace)
      use_workspace=1
      shift
      ;;
    --attempt-purpose)
      attempt_purpose="${2:-}"
      case "$attempt_purpose" in
        run|validation|fix|retry) ;;
        *)
          usage
          exit 2
          ;;
      esac
      shift 2
      ;;
    --retry-of)
      retry_of="${2:-}"
      if [ -z "$retry_of" ]; then
        usage
        exit 2
      fi
      shift 2
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

if [ "$use_workspace" -eq 1 ] && [ "$execute" -ne 1 ]; then
  echo "--use-workspace requires --execute" >&2
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

metadata=$(python3 - "$tmp" "$workspace_tmp" "$input" "$ticket" "$use_workspace" <<'PY'
import json
import os
from pathlib import Path
import re
import shlex
import sys

dry_run_path, workspace_path, input_path, ticket, use_workspace = sys.argv[1:6]
workspace_requested = use_workspace == "1"

with open(dry_run_path, "r", encoding="utf-8") as handle:
    dry_run = json.load(handle)

with open(workspace_path, "r", encoding="utf-8") as handle:
    workspace_payload = json.load(handle)

with open(input_path, "r", encoding="utf-8") as handle:
    tasks_payload = json.load(handle)

decision = next((item for item in dry_run.get("decisions", []) if item.get("ticket") == ticket), None)
task = next((item for item in tasks_payload.get("tasks", []) if item.get("ticket") == ticket), None)

if decision is None or task is None:
    raise SystemExit(f"ticket not found in task source: {ticket}")

workspace_plan = workspace_payload.get("workspaces", [None])[0]
if not workspace_plan:
    raise SystemExit(f"workspace plan not found for ticket: {ticket}")

workspace = workspace_plan["workspace"]
workspace_readiness = workspace_plan.get("readiness")
workspace_reason = workspace_plan.get("reason", "")

if decision.get("decision") != "eligible" and not (
    workspace_requested
    and decision.get("decision") == "human_gate"
    and str(decision.get("reason", "")).startswith("Workspace readiness human_gate:")
):
    raise SystemExit(
        f"ticket {ticket} is not eligible: {decision.get('decision')} - {decision.get('reason')}"
    )

execution_cwd = os.getcwd()
workspace_lock = {}
if workspace_requested:
    worktree_path = Path(workspace["worktree_path"])
    lock_path = Path(workspace["lock_path"])
    if workspace_readiness not in {"human_gate", "ready"}:
        raise SystemExit(f"ticket {ticket} workspace is not usable: {workspace_readiness} - {workspace_reason}")
    if not worktree_path.is_dir():
        raise SystemExit(f"materialized worktree not found: {worktree_path}")
    if not lock_path.is_file():
        raise SystemExit(f"workspace lock not found: {lock_path}")
    with lock_path.open("r", encoding="utf-8") as handle:
        workspace_lock = json.load(handle)
    if str(workspace_lock.get("ticket")) != ticket:
        raise SystemExit(
            f"workspace lock belongs to {workspace_lock.get('ticket')}, not {ticket}"
        )
    if str(workspace_lock.get("branch")) != str(workspace.get("branch")):
        raise SystemExit("workspace lock branch does not match workspace plan")
    if str(workspace_lock.get("worktree_path")) != str(workspace.get("worktree_path")):
        raise SystemExit("workspace lock worktree path does not match workspace plan")
    execution_cwd = str(worktree_path.resolve())
elif workspace_readiness != "ready":
    raise SystemExit(
        f"ticket {ticket} does not have ready workspace readiness: "
        f"{workspace_readiness} - {workspace_reason}"
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
    "EXECUTION_CWD": execution_cwd,
    "WORKSPACE_REQUESTED": "1" if workspace_requested else "0",
    "WORKSPACE_READINESS": workspace_readiness,
    "WORKSPACE_MODE": workspace.get("mode", ""),
    "WORKSPACE_LOCK_TICKET": workspace_lock.get("ticket", ""),
}.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)

eval "$metadata"

if [ -n "$artifact_root_override" ]; then
  ARTIFACT_ROOT="$artifact_root_override"
fi
workspace_lock_ticket_display="${WORKSPACE_LOCK_TICKET:-none}"
retry_of_display="${retry_of:-none}"

timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
attempt_dir="$ARTIFACT_ROOT/attempts/$timestamp-$$-$SAFE_TICKET"
case "$attempt_dir" in
  /*) attempt_dir_abs="$attempt_dir" ;;
  *) attempt_dir_abs="$root/$attempt_dir" ;;
esac
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
- Use materialized workspace: $use_workspace
- Attempt purpose: $attempt_purpose
- Retry of: $retry_of_display
- Execution cwd: $EXECUTION_CWD
- Main branch: $(git branch --show-current 2>/dev/null || true)
- Main head: $(git rev-parse --short HEAD 2>/dev/null || true)
- Main worktree status before: $(git status --short | wc -l | tr -d ' ')
- Execution branch: $(git -C "$EXECUTION_CWD" branch --show-current 2>/dev/null || true)
- Execution head: $(git -C "$EXECUTION_CWD" rev-parse --short HEAD 2>/dev/null || true)
- Execution worktree status before: $(git -C "$EXECUTION_CWD" status --short 2>/dev/null | wc -l | tr -d ' ')
- Workspace readiness: $WORKSPACE_READINESS
- Workspace mode: $WORKSPACE_MODE
- Workspace lock ticket: $workspace_lock_ticket_display
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

## Attempt purpose

\`\`\`text
$attempt_purpose
\`\`\`

## Retry of

\`\`\`text
$retry_of_display
\`\`\`

## Execution cwd

\`\`\`text
$EXECUTION_CWD
\`\`\`

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Materialized workspace execution requires --use-workspace and a matching lock.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
EOF

if [ "$execute" -eq 1 ]; then
  set +e
  (cd "$EXECUTION_CWD" && sh -c "$command") >"$attempt_dir_abs/COMMAND.txt" 2>&1
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
- Execution cwd: $EXECUTION_CWD
- Attempt purpose: $attempt_purpose
- Retry of: $retry_of_display
EOF

python3 - "$attempt_dir" "$ticket" "$SAFE_TICKET" "$TITLE" "$EXEC_PACK" "$ARTIFACT_ROOT" "$timestamp" "$execute" "$code" "$command" "$EXECUTION_CWD" "$use_workspace" "$attempt_purpose" "$retry_of" <<'PY'
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
    execution_cwd,
    use_workspace,
    attempt_purpose,
    retry_of,
) = sys.argv[1:15]

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
    "execution_cwd": execution_cwd,
    "use_workspace": use_workspace == "1",
    "attempt_purpose": attempt_purpose,
    "retry_of": retry_of or None,
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
  echo "$attempt_dir"
  echo "runner command failed with exit code $code; see $attempt_dir/COMMAND.txt" >&2
  exit "$code"
fi

echo "$attempt_dir"
