#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

decision="artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json"
artifact_root=""
ticket=""
format="text"

usage() {
  echo "usage: scripts/artemis-human-cleanup-approval-contract.sh [--decision path] [--ticket TKT-000] [--artifact-root path] [--json]" >&2
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

payload=$(python3 - "$decision" "$ticket" <<'PY'
import json
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

decision_path = Path(sys.argv[1])
ticket_filter = sys.argv[2]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

source = json.loads(decision_path.read_text(encoding="utf-8"))
reviews = source.get("reviews", [])
if ticket_filter:
    reviews = [item for item in reviews if str(item.get("ticket")) == ticket_filter]
    if not reviews:
        raise SystemExit(f"ticket not found in cleanup decision: {ticket_filter}")

VALID_DECISIONS = ["pending", "approved", "deferred", "rejected"]
REQUIRED_METADATA = ["decided_by", "decided_at", "reason"]


def split_command(command: str) -> list[str]:
    try:
        return shlex.split(command)
    except ValueError:
        return command.split()


def expected_values(review: dict) -> tuple[str, str, str]:
    evidence = list(review.get("required_evidence") or [])
    worktree = str(evidence[4]) if len(evidence) > 4 else ""
    branch = str(evidence[5]) if len(evidence) > 5 else ""
    lock = f".artemis/locks/{str(review.get('ticket', '')).lower()}.lock"
    return worktree, lock, branch


def allowed_shape(command: str, review: dict) -> bool:
    worktree, lock, branch = expected_values(review)
    parts = split_command(command)
    return (
        parts == ["git", "worktree", "remove", worktree]
        or parts == ["rm", lock]
        or parts == ["git", "branch", "-d", branch]
    )


def valid_timestamp(value: str) -> bool:
    if not value:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def validate_review(review: dict) -> dict:
    record = review.get("decision_record") or {}
    decision = str(record.get("decision") or "pending").strip()
    approved_commands = [str(item) for item in record.get("approved_commands") or []]
    expected_commands = [str(item) for item in review.get("commands_after_approval") or []]
    blockers = []
    warnings = []

    if decision not in VALID_DECISIONS:
        blockers.append(f"decision must be one of: {', '.join(VALID_DECISIONS)}")

    if decision in {"approved", "deferred", "rejected"}:
        for field in REQUIRED_METADATA:
            if not str(record.get(field) or "").strip():
                blockers.append(f"{field} is required for {decision}")
        if not valid_timestamp(str(record.get("decided_at") or "").strip()):
            blockers.append("decided_at must be ISO-8601")

    if decision == "approved":
        if review.get("recommendation") != "eligible_for_human_cleanup_approval":
            blockers.append("approved cleanup requires eligible_for_human_cleanup_approval")
        if approved_commands != expected_commands:
            blockers.append("approved_commands must exactly match commands_after_approval")
        if not approved_commands:
            blockers.append("approved cleanup requires all expected commands")
    elif approved_commands:
        blockers.append("pending, deferred, and rejected decisions must not include approved_commands")

    for command in approved_commands:
        if not allowed_shape(command, review):
            blockers.append(f"command is outside cleanup allowlist: {command}")

    if decision == "pending":
        contract_state = "pending"
        execution_allowed = False
        warnings.append("pending is an open human decision and cannot execute cleanup")
    elif decision == "approved" and not blockers:
        contract_state = "approved_ready"
        execution_allowed = True
    elif decision == "deferred" and not blockers:
        contract_state = "deferred"
        execution_allowed = False
    elif decision == "rejected" and not blockers:
        contract_state = "rejected"
        execution_allowed = False
    else:
        contract_state = "invalid"
        execution_allowed = False

    return {
        "ticket": review.get("ticket"),
        "decision": decision,
        "contract_state": contract_state,
        "execution_allowed": execution_allowed,
        "required_fields": REQUIRED_METADATA if decision in {"approved", "deferred", "rejected"} else [],
        "expected_commands": expected_commands,
        "approved_commands": approved_commands,
        "blockers": blockers,
        "warnings": warnings,
    }


results = [validate_review(review) for review in reviews]
summary = {
    "reviewed": len(results),
    "pending": sum(1 for item in results if item["contract_state"] == "pending"),
    "approved_ready": sum(1 for item in results if item["contract_state"] == "approved_ready"),
    "deferred": sum(1 for item in results if item["contract_state"] == "deferred"),
    "rejected": sum(1 for item in results if item["contract_state"] == "rejected"),
    "invalid": sum(1 for item in results if item["contract_state"] == "invalid"),
    "execution_allowed": sum(1 for item in results if item["execution_allowed"]),
}
overall = "failed" if summary["invalid"] else ("human_gate" if summary["pending"] else "passed")

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-cleanup-approval-contract.sh",
    "mode": "read_only",
    "decision": str(decision_path),
    "ticket_filter": ticket_filter or None,
    "overall": overall,
    "contract": {
        "valid_decisions": VALID_DECISIONS,
        "metadata_required_for": ["approved", "deferred", "rejected"],
        "required_metadata_fields": REQUIRED_METADATA,
        "approved_requires_exact_commands": True,
        "partial_approval_executes": False,
        "non_approved_commands_allowed": False,
        "timestamp_format": "ISO-8601",
        "execution_scope": [
            "git worktree remove <review worktree>",
            "rm <review lock>",
            "git branch -d <review branch>",
        ],
    },
    "summary": summary,
    "results": results,
    "invariants": [
        "Approval requires identity, timestamp, reason, and exact commands.",
        "Deferred and rejected are explicit human decisions but never execute cleanup.",
        "Partial command approval is not executable approval.",
        "Pending remains an open Human Gate.",
        "Remote operations are out of scope.",
    ],
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/cleanup-approval-contract.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "cleanup-approval-contract.json").read_text(encoding="utf-8"))
contract = payload["contract"]
summary = payload["summary"]

lines = [
    "# ARTEMIS HUMAN CLEANUP APPROVAL CONTRACT",
    "",
    f"- Generated at: {payload['generated_at']}",
    f"- Overall: `{payload['overall']}`",
    f"- Decision source: `{payload['decision']}`",
    "",
    "## Contract",
    "",
    f"- Valid decisions: {', '.join(f'`{item}`' for item in contract['valid_decisions'])}",
    f"- Metadata required for: {', '.join(f'`{item}`' for item in contract['metadata_required_for'])}",
    f"- Required metadata fields: {', '.join(f'`{item}`' for item in contract['required_metadata_fields'])}",
    "- `approved` requires `approved_commands` to exactly match `commands_after_approval`.",
    "- Partial approval does not execute; use `deferred` with a reason.",
    "- `pending`, `deferred`, and `rejected` must not include approved commands.",
    "",
    "## Summary",
    "",
    f"- Reviewed: {summary['reviewed']}",
    f"- Pending: {summary['pending']}",
    f"- Approved ready: {summary['approved_ready']}",
    f"- Deferred: {summary['deferred']}",
    f"- Rejected: {summary['rejected']}",
    f"- Invalid: {summary['invalid']}",
    f"- Execution allowed: {summary['execution_allowed']}",
    "",
    "## Results",
    "",
]

for item in payload["results"]:
    lines.extend([
        f"### {item['ticket']} - {item['contract_state']}",
        "",
        f"- Decision: `{item['decision']}`",
        f"- Execution allowed: {item['execution_allowed']}",
        "",
    ])
    if item["warnings"]:
        lines.append("Warnings:")
        for warning in item["warnings"]:
            lines.append(f"- {warning}")
        lines.append("")
    if item["blockers"]:
        lines.append("Blockers:")
        for blocker in item["blockers"]:
            lines.append(f"- {blocker}")
        lines.append("")

lines.extend(["## Invariants", ""])
for invariant in payload["invariants"]:
    lines.append(f"- {invariant}")

(root / "CLEANUP_APPROVAL_CONTRACT.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
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
print(f"ARTEMIS Human Cleanup Approval Contract: {payload['overall']}")
print(
    "summary: "
    f"reviewed={summary['reviewed']} "
    f"pending={summary['pending']} "
    f"approved_ready={summary['approved_ready']} "
    f"deferred={summary['deferred']} "
    f"rejected={summary['rejected']} "
    f"invalid={summary['invalid']} "
    f"execution_allowed={summary['execution_allowed']}"
)
for item in payload["results"]:
    print(f"- {item['ticket']} [{item['contract_state']}] execution_allowed={item['execution_allowed']}")
PY
fi
