#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
ticket=""
format="text"

usage() {
  echo "usage: scripts/artemis-workspace-cleanup-review.sh [--ticket TKT-000] [--artifact-root path] [--json]" >&2
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

lifecycle_tmp=$(mktemp "${TMPDIR:-/tmp}/artemis-workspace-lifecycle.XXXXXX.json")
scripts/artemis-workspace-lifecycle.sh --json >"$lifecycle_tmp"

payload=$(python3 - "$lifecycle_tmp" "$ticket" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

lifecycle_path = Path(sys.argv[1])
ticket_filter = sys.argv[2]
lifecycle = json.loads(lifecycle_path.read_text(encoding="utf-8"))
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

locks = lifecycle.get("locks", [])
if ticket_filter:
    locks = [item for item in locks if str(item.get("ticket")) == ticket_filter]
    if not locks:
        raise SystemExit(f"ticket not found in lifecycle inventory: {ticket_filter}")

reviews = []
for item in locks:
    state = item.get("lifecycle_state")
    required_evidence = [
        item.get("artifact_root", "") + "/STATUS.md",
        item.get("artifact_root", "") + "/VALIDATION.md",
        item.get("artifact_root", "") + "/HANDOFF.md",
        item.get("lock_path", ""),
        item.get("worktree_path", ""),
        item.get("branch", ""),
    ]
    blockers = []
    if state != "review_ready":
        blockers.append(f"workspace lifecycle state is {state}")
    if item.get("dirty"):
        blockers.append("worktree has pending changes")
    if item.get("branch_merged_into_head") is not True:
        blockers.append("branch is not merged into current HEAD")
    if item.get("status_md_exists") is not True:
        blockers.append("STATUS.md evidence is missing")
    if item.get("worktree_registered") is not True:
        blockers.append("worktree is not registered by git")

    recommendation = "eligible_for_human_cleanup_approval" if not blockers else "defer_cleanup"
    reviews.append({
        "ticket": item.get("ticket"),
        "title": item.get("title"),
        "lifecycle_state": state,
        "recommendation": recommendation,
        "cleanup_allowed_by_script": False,
        "human_decision_required": True,
        "required_evidence": required_evidence,
        "blockers": blockers,
        "commands_after_approval": [
            f"git worktree remove {item.get('worktree_path')}",
            f"rm .artemis/locks/{str(item.get('ticket', '')).lower()}.lock",
            f"git branch -d {item.get('branch')}",
        ] if recommendation == "eligible_for_human_cleanup_approval" else [],
        "decision_record": {
            "decision": "pending",
            "decided_by": "",
            "decided_at": "",
            "reason": "",
            "approved_commands": [],
        },
    })

summary = {
    "reviewed": len(reviews),
    "eligible_for_human_cleanup_approval": sum(1 for item in reviews if item["recommendation"] == "eligible_for_human_cleanup_approval"),
    "defer_cleanup": sum(1 for item in reviews if item["recommendation"] == "defer_cleanup"),
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-workspace-cleanup-review.sh",
    "mode": "read_only",
    "ticket_filter": ticket_filter or None,
    "summary": summary,
    "reviews": reviews,
    "invariants": [
        "This command never removes worktrees, branches, or locks.",
        "A pending decision is not approval.",
        "A human decision must name the exact commands approved for local cleanup.",
        "Dirty worktrees, unmerged branches, and missing evidence defer cleanup.",
    ],
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

rm -f "$lifecycle_tmp"

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/cleanup-review.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "cleanup-review.json").read_text(encoding="utf-8"))
summary = payload["summary"]

lines = [
    "# ARTEMIS WORKSPACE CLEANUP REVIEW",
    "",
    f"- Generated at: {payload['generated_at']}",
    f"- Mode: `{payload['mode']}`",
    f"- Reviewed: {summary['reviewed']}",
    f"- Eligible for human cleanup approval: {summary['eligible_for_human_cleanup_approval']}",
    f"- Deferred: {summary['defer_cleanup']}",
    "",
    "## Reviews",
    "",
]

for item in payload["reviews"]:
    lines.extend([
        f"### {item['ticket']} - {item['recommendation']}",
        "",
        f"- Title: {item['title']}",
        f"- Lifecycle state: `{item['lifecycle_state']}`",
        f"- Cleanup allowed by script: {item['cleanup_allowed_by_script']}",
        f"- Human decision required: {item['human_decision_required']}",
        "",
        "Required evidence:",
    ])
    for evidence in item["required_evidence"]:
        lines.append(f"- `{evidence}`")
    if item["blockers"]:
        lines.extend(["", "Blockers:"])
        for blocker in item["blockers"]:
            lines.append(f"- {blocker}")
    if item["commands_after_approval"]:
        lines.extend(["", "Commands after explicit approval:"])
        for command in item["commands_after_approval"]:
            lines.append(f"- `{command}`")
    lines.append("")

lines.extend([
    "## Invariants",
    "",
])
for invariant in payload["invariants"]:
    lines.append(f"- {invariant}")

decision_lines = [
    "# HUMAN CLEANUP DECISION TEMPLATE",
    "",
    "Use this template only after reviewing `cleanup-review.json` and the required evidence.",
    "Validate the filled decision with `scripts/artemis-human-cleanup-approval-contract.sh` before any executor run.",
    "",
    "Rules: `approved` requires `decided_by`, ISO-8601 `decided_at`, `reason`, and every command exactly as listed. Partial approval must stay `deferred` with a reason and does not execute.",
    "",
]
for item in payload["reviews"]:
    decision_lines.extend([
        f"## {item['ticket']}",
        "",
        "- Decision: pending | approved | deferred | rejected",
        "- Decided by:",
        "- Decided at:",
        "- Reason:",
        "- Approved commands (copy all only when Decision is approved; leave empty for pending/deferred/rejected):",
    ])
    for command in item["commands_after_approval"]:
        decision_lines.append(f"  - `{command}`")
    decision_lines.append("")

(root / "CLEANUP_REVIEW.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
(root / "DECISION_TEMPLATE.md").write_text("\n".join(decision_lines).rstrip() + "\n", encoding="utf-8")
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
print("ARTEMIS Workspace Cleanup Review")
print(
    "summary: "
    f"reviewed={summary['reviewed']} "
    f"eligible={summary['eligible_for_human_cleanup_approval']} "
    f"deferred={summary['defer_cleanup']}"
)
print("")
for item in payload["reviews"]:
    print(f"- {item['ticket']} [{item['recommendation']}]")
    print(f"  cleanup_allowed_by_script: {item['cleanup_allowed_by_script']}")
    print(f"  human_decision_required: {item['human_decision_required']}")
    if item["blockers"]:
        print("  blockers: " + "; ".join(item["blockers"]))
PY
fi
