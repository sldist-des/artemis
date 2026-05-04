#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

source_review="artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json"
artifact_root="artifacts/artemis-real-cleanup-decision-package/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-real-cleanup-decision-package.sh [--source path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      source_review="${2:-}"
      if [ -z "$source_review" ]; then
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

if [ ! -f "$source_review" ]; then
  echo "source cleanup review not found: $source_review" >&2
  exit 2
fi

mkdir -p "$artifact_root"

payload=$(python3 - "$source_review" "$artifact_root" <<'PY'
import copy
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

source_review = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

source = json.loads(source_review.read_text(encoding="utf-8"))
reviews = []

for item in source.get("reviews", []):
    review = copy.deepcopy(item)
    review["decision_record"] = {
        "decision": "pending",
        "decided_by": "",
        "decided_at": "",
        "reason": "",
        "approved_commands": [],
    }
    review["human_decision_options"] = {
        "pending": "Decision still open; no cleanup can execute.",
        "approved": "Requires decided_by, decided_at, reason, and exact approved_commands.",
        "deferred": "Requires metadata and reason; keeps workspace for later review.",
        "rejected": "Requires metadata and reason; refuses cleanup while preserving the record.",
    }
    review["fillable_fields"] = [
        "decision_record.decision",
        "decision_record.decided_by",
        "decision_record.decided_at",
        "decision_record.reason",
        "decision_record.approved_commands",
    ]
    reviews.append(review)

decision_path = artifact_root / "real-cleanup-decision.json"
contract_artifact = artifact_root / "validation" / "approval-contract"
dry_run_artifact = artifact_root / "validation" / "approved-cleanup-dry-run"

decision_payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-real-cleanup-decision-package.sh",
    "mode": "human_fillable_pending",
    "based_on": str(source_review),
    "summary": {
        "reviewed": len(reviews),
        "pending": len(reviews),
        "approved": 0,
        "deferred": 0,
        "rejected": 0,
        "execute_allowed": 0,
    },
    "reviews": reviews,
    "invariants": [
        "This file is a human-fillable decision package, not approval.",
        "All generated decisions start as pending.",
        "Agents must not approve cleanup on behalf of humans.",
        "Real execution remains out of scope until a human fills and validates the package.",
    ],
}

package_payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-real-cleanup-decision-package.sh",
    "mode": "read_only",
    "source_review": str(source_review),
    "artifact_root": str(artifact_root),
    "decision_file": str(decision_path),
    "summary": decision_payload["summary"],
    "validation_commands": [
        f"scripts/artemis-human-cleanup-approval-contract.sh --decision {decision_path} --artifact-root {contract_artifact} --json",
        f"scripts/artemis-approved-workspace-cleanup.sh --decision {decision_path} --artifact-root {dry_run_artifact} --json",
    ],
    "human_fill_instructions": [
        "Choose exactly one decision per workspace: pending, approved, deferred, or rejected.",
        "For approved, deferred, and rejected, fill decided_by, decided_at, and reason.",
        "For approved, copy every commands_after_approval entry into approved_commands in the same order.",
        "Leave approved_commands empty for pending, deferred, and rejected.",
        "Run the validation commands before any cleanup executor is considered.",
    ],
    "reviews": [
        {
            "ticket": item.get("ticket"),
            "title": item.get("title"),
            "recommendation": item.get("recommendation"),
            "lifecycle_state": item.get("lifecycle_state"),
            "decision": item.get("decision_record", {}).get("decision"),
            "commands_after_approval": item.get("commands_after_approval", []),
            "required_evidence": item.get("required_evidence", []),
        }
        for item in reviews
    ],
    "invariants": [
        "No worktree, lock, or branch is removed by this package generator.",
        "The generated decision file is pending by default.",
        "Validation may report Human Gate; that is expected until a human fills a final decision.",
        "The package never emits --execute commands.",
    ],
}

decision_path.write_text(json.dumps(decision_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(artifact_root / "real-cleanup-decision-package.json").write_text(
    json.dumps(package_payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

package_lines = [
    "# ARTEMIS REAL CLEANUP DECISION PACKAGE",
    "",
    f"- Generated at: {generated_at}",
    f"- Mode: `{package_payload['mode']}`",
    f"- Source review: `{source_review}`",
    f"- Decision file: `{decision_path}`",
    f"- Reviewed workspaces: {package_payload['summary']['reviewed']}",
    f"- Pending decisions: {package_payload['summary']['pending']}",
    f"- Execute allowed now: {package_payload['summary']['execute_allowed']}",
    "",
    "## Human Fill Instructions",
    "",
]
for instruction in package_payload["human_fill_instructions"]:
    package_lines.append(f"- {instruction}")

package_lines.extend([
    "",
    "## Validation Commands",
    "",
])
for command in package_payload["validation_commands"]:
    package_lines.extend(["```bash", command, "```", ""])

package_lines.extend(["## Workspaces", ""])
for item in reviews:
    package_lines.extend([
        f"### {item.get('ticket')} - {item.get('title')}",
        "",
        f"- Recommendation: `{item.get('recommendation')}`",
        f"- Lifecycle state: `{item.get('lifecycle_state')}`",
        "- Decision options: `pending`, `approved`, `deferred`, `rejected`",
        "",
        "Required evidence:",
    ])
    for evidence in item.get("required_evidence", []):
        package_lines.append(f"- `{evidence}`")
    package_lines.extend(["", "Commands after explicit human approval:"])
    for command in item.get("commands_after_approval", []):
        package_lines.append(f"- `{command}`")
    package_lines.append("")

template_lines = [
    "# REAL CLEANUP DECISION TEMPLATE",
    "",
    f"Edit `{decision_path}` only after reviewing each workspace evidence.",
    "",
    "For each `decision_record`:",
    "",
    "- Keep `decision` as `pending` while the decision is open.",
    "- Use `approved` only when all cleanup commands are accepted exactly.",
    "- Use `deferred` when cleanup should wait.",
    "- Use `rejected` when cleanup should not happen.",
    "- Fill `decided_by`, ISO-8601 `decided_at`, and `reason` for approved, deferred, or rejected.",
    "- Keep `approved_commands` empty unless decision is approved.",
    "",
    "Validation:",
    "",
]
for command in package_payload["validation_commands"]:
    template_lines.extend(["```bash", command, "```", ""])

checklist_lines = [
    "# REAL CLEANUP DECISION CHECKLIST",
    "",
    "Before changing any decision from `pending`:",
    "",
    "- Confirm the required STATUS, VALIDATION, and HANDOFF artifacts exist.",
    "- Confirm the worktree path matches `git worktree list --porcelain`.",
    "- Confirm the branch is already merged into current `HEAD`.",
    "- Confirm the local worktree has no pending changes.",
    "- Confirm the lock path matches the ticket.",
    "- Copy cleanup commands exactly when approving.",
    "- Run the validation commands and inspect their output.",
    "",
    "Out of scope for this package:",
    "",
    "- Running cleanup with `--execute`.",
    "- Removing worktrees, branches, or locks.",
    "- Pushing, merging, or changing remote GitHub settings.",
]

(artifact_root / "REAL_CLEANUP_DECISION_PACKAGE.md").write_text(
    "\n".join(package_lines).rstrip() + "\n",
    encoding="utf-8",
)
(artifact_root / "REAL_CLEANUP_DECISION_TEMPLATE.md").write_text(
    "\n".join(template_lines).rstrip() + "\n",
    encoding="utf-8",
)
(artifact_root / "REAL_CLEANUP_DECISION_CHECKLIST.md").write_text(
    "\n".join(checklist_lines).rstrip() + "\n",
    encoding="utf-8",
)

print(json.dumps(package_payload, ensure_ascii=False, indent=2))
PY
)

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
summary = payload["summary"]
print("ARTEMIS Real Cleanup Decision Package")
print(
    "summary: "
    f"reviewed={summary['reviewed']} "
    f"pending={summary['pending']} "
    f"execute_allowed={summary['execute_allowed']}"
)
print(f"decision_file: {payload['decision_file']}")
for item in payload["reviews"]:
    print(f"- {item['ticket']} [{item['decision']}] {item['recommendation']}")
PY
fi
