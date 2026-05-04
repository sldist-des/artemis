#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

lifecycle="artifacts/artemis-workspace-lifecycle/run-01/workspace-lifecycle.json"
cleanup="artifacts/artemis-approved-workspace-cleanup/run-01/approved-cleanup.json"
approval_contract="artifacts/artemis-human-cleanup-approval-contract/run-01/cleanup-approval-contract.json"
approval_contract_explicit=0
artifact_root=""
format="text"

usage() {
  echo "usage: scripts/artemis-workspace-runtime-handoff.sh [--lifecycle path] [--cleanup path] [--approval-contract path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lifecycle)
      lifecycle="${2:-}"
      if [ -z "$lifecycle" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --approval-contract)
      approval_contract="${2:-}"
      if [ -z "$approval_contract" ]; then
        usage
        exit 2
      fi
      approval_contract_explicit=1
      shift 2
      ;;
    --cleanup)
      cleanup="${2:-}"
      if [ -z "$cleanup" ]; then
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

if [ ! -f "$lifecycle" ]; then
  echo "lifecycle file not found: $lifecycle" >&2
  exit 2
fi
if [ ! -f "$cleanup" ]; then
  echo "cleanup result file not found: $cleanup" >&2
  exit 2
fi
if [ "$approval_contract_explicit" -eq 1 ] && [ ! -f "$approval_contract" ]; then
  echo "approval contract file not found: $approval_contract" >&2
  exit 2
fi

payload=$(python3 - "$lifecycle" "$cleanup" "$approval_contract" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

lifecycle_path = Path(sys.argv[1])
cleanup_path = Path(sys.argv[2])
approval_contract_path = Path(sys.argv[3])
lifecycle = json.loads(lifecycle_path.read_text(encoding="utf-8"))
cleanup = json.loads(cleanup_path.read_text(encoding="utf-8"))
approval_contract = {}
if approval_contract_path.is_file():
    approval_contract = json.loads(approval_contract_path.read_text(encoding="utf-8"))
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

cleanup_by_ticket = {
    str(item.get("ticket")): item
    for item in cleanup.get("results", [])
}
contract_by_ticket = {
    str(item.get("ticket")): item
    for item in approval_contract.get("results", [])
}

items = []
for lock in lifecycle.get("locks", []):
    ticket = str(lock.get("ticket"))
    cleanup_result = cleanup_by_ticket.get(ticket, {})
    contract_result = contract_by_ticket.get(ticket, {})
    cleanup_status = str(cleanup_result.get("status") or "missing")
    contract_status = str(
        contract_result.get("contract_state")
        or cleanup_result.get("contract_status")
        or "unknown"
    )
    decision = str(contract_result.get("decision") or contract_status)
    execution_allowed = bool(contract_result.get("execution_allowed"))
    executed = bool(cleanup_result.get("executed"))
    lifecycle_state = str(lock.get("lifecycle_state") or "unknown")

    if cleanup_status == "failed":
        final_state = "needs_decision"
        reason = "cleanup executor reported failure"
    elif executed and cleanup_status == "ready_to_execute":
        final_state = "cleaned"
        reason = "approved cleanup executed and reported success"
    elif contract_status == "approved_ready" and cleanup_status == "ready_to_execute":
        final_state = "approved_ready"
        reason = "human approval is valid, but cleanup has not executed"
    elif contract_status == "deferred":
        final_state = "deferred"
        reason = "human decision deferred cleanup"
    elif contract_status == "rejected":
        final_state = "rejected"
        reason = "human decision rejected cleanup"
    elif contract_status == "invalid":
        final_state = "needs_decision"
        reason = "human decision contract is invalid"
    elif cleanup_status == "human_gate":
        final_state = "pending"
        reason = "cleanup decision remains gated by human approval"
    elif lifecycle_state == "review_ready":
        final_state = "kept"
        reason = "workspace remains present and review-ready"
    else:
        final_state = "needs_decision"
        reason = f"lifecycle={lifecycle_state}, cleanup_status={cleanup_status}"

    items.append({
        "ticket": ticket,
        "title": lock.get("title", ""),
        "final_state": final_state,
        "reason": reason,
        "lifecycle_state": lifecycle_state,
        "cleanup_status": cleanup_status,
        "decision": decision,
        "contract_status": contract_status,
        "execution_allowed": execution_allowed,
        "cleanup_executed": executed,
        "worktree_path": lock.get("worktree_path", ""),
        "worktree_exists": lock.get("worktree_exists"),
        "worktree_registered": lock.get("worktree_registered"),
        "lock_path": lock.get("lock_path", ""),
        "branch": lock.get("branch", ""),
        "branch_exists": lock.get("branch_exists"),
        "artifact_root": lock.get("artifact_root", ""),
        "evidence": {
            "lifecycle": str(lifecycle_path),
            "cleanup": str(cleanup_path),
            "approval_contract": str(approval_contract_path) if approval_contract else "",
            "status": f"{lock.get('artifact_root', '')}/STATUS.md",
            "validation": f"{lock.get('artifact_root', '')}/VALIDATION.md",
            "handoff": f"{lock.get('artifact_root', '')}/HANDOFF.md",
        },
        "blockers": cleanup_result.get("blockers", []),
    })

summary = {
    "total": len(items),
    "cleaned": sum(1 for item in items if item["final_state"] == "cleaned"),
    "kept": sum(1 for item in items if item["final_state"] == "kept"),
    "pending": sum(1 for item in items if item["final_state"] == "pending"),
    "approved_ready": sum(1 for item in items if item["final_state"] == "approved_ready"),
    "deferred": sum(1 for item in items if item["final_state"] == "deferred"),
    "rejected": sum(1 for item in items if item["final_state"] == "rejected"),
    "needs_decision": sum(1 for item in items if item["final_state"] == "needs_decision"),
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-workspace-runtime-handoff.sh",
    "mode": "read_only",
    "summary": summary,
    "workspaces": items,
    "invariants": [
        "This handoff does not remove worktrees, branches, locks, or artifacts.",
        "Artifacts are the durable memory of local runtime decisions.",
        "A workspace with pending cleanup remains visible in lifecycle inventory.",
        "Deferred and rejected decisions remain visible and never imply cleanup execution.",
        "Approved-ready is not cleaned until the executor records command execution.",
        "A cleaned workspace must still appear in handoff evidence.",
    ],
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/runtime-handoff.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "runtime-handoff.json").read_text(encoding="utf-8"))
summary = payload["summary"]

lines = [
    "# ARTEMIS WORKSPACE RUNTIME HANDOFF",
    "",
    f"- Generated at: {payload['generated_at']}",
    f"- Mode: `{payload['mode']}`",
    f"- Total: {summary['total']}",
    f"- Cleaned: {summary['cleaned']}",
    f"- Kept: {summary['kept']}",
    f"- Pending: {summary['pending']}",
    f"- Approved ready: {summary['approved_ready']}",
    f"- Deferred: {summary['deferred']}",
    f"- Rejected: {summary['rejected']}",
    f"- Needs decision: {summary['needs_decision']}",
    "",
    "## Workspaces",
    "",
]

for item in payload["workspaces"]:
    lines.extend([
        f"### {item['ticket']} - {item['final_state']}",
        "",
        f"- Title: {item['title']}",
        f"- Reason: {item['reason']}",
        f"- Lifecycle state: `{item['lifecycle_state']}`",
        f"- Cleanup status: `{item['cleanup_status']}`",
        f"- Decision: `{item['decision']}`",
        f"- Contract status: `{item['contract_status']}`",
        f"- Execution allowed: {item['execution_allowed']}",
        f"- Cleanup executed: {item['cleanup_executed']}",
        f"- Worktree: `{item['worktree_path']}` (exists: {item['worktree_exists']}, registered: {item['worktree_registered']})",
        f"- Lock: `{item['lock_path']}`",
        f"- Branch: `{item['branch']}` (exists: {item['branch_exists']})",
        f"- Artifact root: `{item['artifact_root']}`",
        "",
    ])
    if item["blockers"]:
        lines.append("Blockers:")
        for blocker in item["blockers"]:
            lines.append(f"- {blocker}")
        lines.append("")

lines.extend([
    "## Invariants",
    "",
])
for invariant in payload["invariants"]:
    lines.append(f"- {invariant}")

(root / "RUNTIME_HANDOFF.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
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
print("ARTEMIS Workspace Runtime Handoff")
print(
    "summary: "
    f"total={summary['total']} "
    f"cleaned={summary['cleaned']} "
    f"kept={summary['kept']} "
    f"pending={summary['pending']} "
    f"approved_ready={summary['approved_ready']} "
    f"deferred={summary['deferred']} "
    f"rejected={summary['rejected']} "
    f"needs_decision={summary['needs_decision']}"
)
for item in payload["workspaces"]:
    print(f"- {item['ticket']} [{item['final_state']}] {item['reason']}")
PY
fi
