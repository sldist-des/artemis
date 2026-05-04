#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

decision="artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json"
artifact_root=""
ticket=""
format="text"
execute=0

usage() {
  echo "usage: scripts/artemis-approved-workspace-cleanup.sh [--decision path] [--ticket TKT-000] [--artifact-root path] [--execute] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --decision)
      decision="${2:-}"
      if [ -z "$decision" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --ticket)
      ticket="${2:-}"
      if [ -z "$ticket" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --execute)
      execute=1
      shift
      ;;
    --json)
      format="json"
      shift
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

if [ ! -f "$decision" ]; then
  echo "decision file not found: $decision" >&2
  exit 2
fi

payload=$(python3 - "$decision" "$ticket" "$execute" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

decision_path = Path(sys.argv[1])
ticket_filter = sys.argv[2]
execute = sys.argv[3] == "1"
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
root = Path.cwd()

decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))
reviews = decision_payload.get("reviews", [])
if ticket_filter:
    reviews = [item for item in reviews if str(item.get("ticket")) == ticket_filter]
    if not reviews:
        raise SystemExit(f"ticket not found in cleanup decision: {ticket_filter}")


def split_command(command: str) -> list[str]:
    return command.split()


def allowed_shape(command: str, review: dict) -> bool:
    parts = split_command(command)
    expected_worktree = str(review.get("required_evidence", ["", "", "", "", ""])[4])
    expected_lock = f".artemis/locks/{str(review.get('ticket', '')).lower()}.lock"
    expected_branch = str(review.get("required_evidence", ["", "", "", "", "", ""])[5])

    return (
        parts == ["git", "worktree", "remove", expected_worktree]
        or parts == ["rm", expected_lock]
        or parts == ["git", "branch", "-d", expected_branch]
    )


def validate_review(review: dict) -> tuple[str, list[str]]:
    blockers = list(review.get("blockers", []))
    record = review.get("decision_record") or {}
    decision = str(record.get("decision") or "pending")
    approved_commands = [str(item) for item in record.get("approved_commands") or []]
    expected_commands = [str(item) for item in review.get("commands_after_approval") or []]

    if review.get("recommendation") != "eligible_for_human_cleanup_approval":
        blockers.append("review is not eligible for human cleanup approval")
    if decision != "approved":
        blockers.append(f"decision is {decision}, not approved")
    if not str(record.get("decided_by") or "").strip():
        blockers.append("decided_by is missing")
    if not str(record.get("decided_at") or "").strip():
        blockers.append("decided_at is missing")
    if not str(record.get("reason") or "").strip():
        blockers.append("decision reason is missing")
    if approved_commands != expected_commands:
        blockers.append("approved_commands do not exactly match expected cleanup commands")
    for command in approved_commands:
        if not allowed_shape(command, review):
            blockers.append(f"command is outside cleanup allowlist: {command}")

    return ("ready_to_execute" if not blockers else "human_gate"), blockers


results = []
executed_commands = []
for review in reviews:
    status, blockers = validate_review(review)
    command_results = []
    if execute and status == "ready_to_execute":
        for command in review.get("decision_record", {}).get("approved_commands", []):
            parts = split_command(str(command))
            completed = subprocess.run(
                parts,
                cwd=root,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            command_result = {
                "command": command,
                "exit_code": completed.returncode,
                "stdout": completed.stdout,
                "stderr": completed.stderr,
            }
            command_results.append(command_result)
            executed_commands.append(command_result)
            if completed.returncode != 0:
                blockers.append(f"command failed: {command}")
                status = "failed"
                break
    results.append({
        "ticket": review.get("ticket"),
        "status": status,
        "execute_requested": execute,
        "executed": bool(command_results),
        "blockers": blockers,
        "expected_commands": review.get("commands_after_approval", []),
        "approved_commands": review.get("decision_record", {}).get("approved_commands", []),
        "command_results": command_results,
    })

summary = {
    "reviewed": len(results),
    "ready_to_execute": sum(1 for item in results if item["status"] == "ready_to_execute"),
    "human_gate": sum(1 for item in results if item["status"] == "human_gate"),
    "failed": sum(1 for item in results if item["status"] == "failed"),
    "executed_commands": len(executed_commands),
}
overall = "failed" if summary["failed"] else ("human_gate" if summary["human_gate"] else "passed")

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-approved-workspace-cleanup.sh",
    "mode": "execute" if execute else "dry_run",
    "decision": str(decision_path),
    "ticket_filter": ticket_filter or None,
    "overall": overall,
    "summary": summary,
    "results": results,
    "invariants": [
        "Default mode is dry-run.",
        "pending and deferred decisions never execute.",
        "approved_commands must exactly match the generated cleanup review commands.",
        "Only local git worktree remove, lock rm, and git branch -d commands are allowlisted.",
        "Remote GitHub operations are out of scope.",
    ],
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

cleanup_exit=$(python3 - "$payload" "$execute" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
execute = sys.argv[2] == "1"
print("3" if execute and payload.get("overall") != "passed" else "0")
PY
)

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/approved-cleanup.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "approved-cleanup.json").read_text(encoding="utf-8"))
summary = payload["summary"]

lines = [
    "# ARTEMIS APPROVED WORKSPACE CLEANUP",
    "",
    f"- Generated at: {payload['generated_at']}",
    f"- Mode: `{payload['mode']}`",
    f"- Overall: `{payload['overall']}`",
    f"- Reviewed: {summary['reviewed']}",
    f"- Ready to execute: {summary['ready_to_execute']}",
    f"- Human Gate: {summary['human_gate']}",
    f"- Failed: {summary['failed']}",
    f"- Executed commands: {summary['executed_commands']}",
    "",
    "## Results",
    "",
]
for item in payload["results"]:
    lines.extend([
        f"### {item['ticket']} - {item['status']}",
        "",
        f"- Execute requested: {item['execute_requested']}",
        f"- Executed: {item['executed']}",
        "",
    ])
    if item["blockers"]:
        lines.append("Blockers:")
        for blocker in item["blockers"]:
            lines.append(f"- {blocker}")
        lines.append("")
    if item["approved_commands"]:
        lines.append("Approved commands:")
        for command in item["approved_commands"]:
            lines.append(f"- `{command}`")
        lines.append("")

lines.extend([
    "## Invariants",
    "",
])
for invariant in payload["invariants"]:
    lines.append(f"- {invariant}")

(root / "APPROVED_CLEANUP.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
summary = payload["summary"]
print(f"ARTEMIS Approved Workspace Cleanup: {payload['overall']}")
print(
    "summary: "
    f"reviewed={summary['reviewed']} "
    f"ready_to_execute={summary['ready_to_execute']} "
    f"human_gate={summary['human_gate']} "
    f"failed={summary['failed']} "
    f"executed_commands={summary['executed_commands']}"
)
for item in payload["results"]:
    print(f"- {item['ticket']} [{item['status']}] executed={item['executed']}")
PY
fi

exit "$cleanup_exit"
