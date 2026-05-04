#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-human-decision-fixtures/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-fixtures.sh [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

mkdir -p "$artifact_root/fixtures"

payload=$(python3 - "$artifact_root" <<'PY'
import copy
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

artifact_root = Path(sys.argv[1])
fixtures_dir = artifact_root / "fixtures"
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

base_review = {
    "title": "",
    "lifecycle_state": "review_ready",
    "recommendation": "eligible_for_human_cleanup_approval",
    "cleanup_allowed_by_script": False,
    "human_decision_required": True,
    "blockers": [],
}


def review(ticket: str, title: str, worktree: str, branch: str) -> dict:
    lock = f".artemis/locks/{ticket.lower()}.lock"
    item = copy.deepcopy(base_review)
    item.update({
        "ticket": ticket,
        "title": title,
        "required_evidence": [
            f"artifacts/fixtures/{ticket}/STATUS.md",
            f"artifacts/fixtures/{ticket}/VALIDATION.md",
            f"artifacts/fixtures/{ticket}/HANDOFF.md",
            lock,
            worktree,
            branch,
        ],
        "commands_after_approval": [
            f"git worktree remove {worktree}",
            f"rm {lock}",
            f"git branch -d {branch}",
        ],
    })
    return item


def decision_payload(name: str, item: dict, record: dict) -> dict:
    fixture_review = copy.deepcopy(item)
    fixture_review["decision_record"] = record
    return {
        "schema_version": 1,
        "generated_at": generated_at,
        "source": "scripts/artemis-human-decision-fixtures.sh",
        "mode": "fixture_read_only",
        "fixture": name,
        "reviews": [fixture_review],
        "invariants": [
            "Fixture paths are synthetic and must not be used with --execute.",
            "Fixtures prove contract behavior only.",
            "Approved fixtures do not authorize cleanup of real workspaces.",
        ],
    }


cases = []

approved = review(
    "TKT-FIX-APPROVED",
    "Fixture approved exact cleanup decision",
    "../artemis-fixtures/worktrees/approved-exact",
    "artemis/fixture-approved-exact",
)
cases.append({
    "name": "approved-exact",
    "description": "Valid approval with exact commands.",
    "expected_contract_state": "approved_ready",
    "expected_executor_status": "ready_to_execute",
    "expected_overall": "passed",
    "payload": decision_payload("approved-exact", approved, {
        "decision": "approved",
        "decided_by": "ARTEMIS fixture",
        "decided_at": "2026-01-01T00:00:00Z",
        "reason": "Synthetic approval proving exact command matching.",
        "approved_commands": approved["commands_after_approval"],
    }),
})

deferred = review(
    "TKT-FIX-DEFERRED",
    "Fixture deferred cleanup decision",
    "../artemis-fixtures/worktrees/deferred",
    "artemis/fixture-deferred",
)
cases.append({
    "name": "deferred",
    "description": "Valid deferral with metadata and no approved commands.",
    "expected_contract_state": "deferred",
    "expected_executor_status": "human_gate",
    "expected_overall": "passed",
    "payload": decision_payload("deferred", deferred, {
        "decision": "deferred",
        "decided_by": "ARTEMIS fixture",
        "decided_at": "2026-01-01T00:00:00Z",
        "reason": "Synthetic deferral preserving the workspace for later review.",
        "approved_commands": [],
    }),
})

rejected = review(
    "TKT-FIX-REJECTED",
    "Fixture rejected cleanup decision",
    "../artemis-fixtures/worktrees/rejected",
    "artemis/fixture-rejected",
)
cases.append({
    "name": "rejected",
    "description": "Valid rejection with metadata and no approved commands.",
    "expected_contract_state": "rejected",
    "expected_executor_status": "human_gate",
    "expected_overall": "passed",
    "payload": decision_payload("rejected", rejected, {
        "decision": "rejected",
        "decided_by": "ARTEMIS fixture",
        "decided_at": "2026-01-01T00:00:00Z",
        "reason": "Synthetic rejection proving cleanup can be explicitly refused.",
        "approved_commands": [],
    }),
})

partial = review(
    "TKT-FIX-PARTIAL",
    "Fixture invalid partial approval",
    "../artemis-fixtures/worktrees/partial",
    "artemis/fixture-partial",
)
cases.append({
    "name": "invalid-partial-approval",
    "description": "Invalid approval because only part of the command list is approved.",
    "expected_contract_state": "invalid",
    "expected_executor_status": "human_gate",
    "expected_overall": "failed",
    "payload": decision_payload("invalid-partial-approval", partial, {
        "decision": "approved",
        "decided_by": "ARTEMIS fixture",
        "decided_at": "2026-01-01T00:00:00Z",
        "reason": "Synthetic invalid approval proving partial cleanup is rejected.",
        "approved_commands": partial["commands_after_approval"][:1],
    }),
})

missing = review(
    "TKT-FIX-MISSING",
    "Fixture invalid missing metadata",
    "../artemis-fixtures/worktrees/missing-metadata",
    "artemis/fixture-missing-metadata",
)
cases.append({
    "name": "invalid-missing-metadata",
    "description": "Invalid approval because required human metadata is missing.",
    "expected_contract_state": "invalid",
    "expected_executor_status": "human_gate",
    "expected_overall": "failed",
    "payload": decision_payload("invalid-missing-metadata", missing, {
        "decision": "approved",
        "decided_by": "",
        "decided_at": "",
        "reason": "",
        "approved_commands": missing["commands_after_approval"],
    }),
})

fixture_summaries = []
for case in cases:
    path = fixtures_dir / f"{case['name']}.json"
    path.write_text(json.dumps(case["payload"], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    fixture_summaries.append({
        "name": case["name"],
        "description": case["description"],
        "path": str(path),
        "expected_contract_state": case["expected_contract_state"],
        "expected_executor_status": case["expected_executor_status"],
        "expected_overall": case["expected_overall"],
        "execute_allowed": False,
    })

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-fixtures.sh",
    "mode": "read_only",
    "artifact_root": str(artifact_root),
    "summary": {
        "fixtures": len(fixture_summaries),
        "valid": sum(1 for item in fixture_summaries if item["expected_contract_state"] != "invalid"),
        "invalid": sum(1 for item in fixture_summaries if item["expected_contract_state"] == "invalid"),
        "execute_allowed": 0,
    },
    "fixtures": fixture_summaries,
    "invariants": [
        "Fixtures are synthetic and read-only.",
        "Fixtures must not be passed to cleanup with --execute.",
        "Approved fixtures prove exact command matching, not real cleanup authorization.",
        "Invalid fixtures must fail the contract before execution.",
    ],
}

(artifact_root / "human-decision-fixtures.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS HUMAN DECISION FIXTURES",
    "",
    f"- Generated at: {generated_at}",
    f"- Mode: `{payload['mode']}`",
    f"- Fixtures: {payload['summary']['fixtures']}",
    f"- Valid: {payload['summary']['valid']}",
    f"- Invalid: {payload['summary']['invalid']}",
    f"- Execute allowed: {payload['summary']['execute_allowed']}",
    "",
    "## Fixtures",
    "",
]
for item in fixture_summaries:
    lines.extend([
        f"### {item['name']}",
        "",
        f"- Description: {item['description']}",
        f"- Path: `{item['path']}`",
        f"- Expected contract state: `{item['expected_contract_state']}`",
        f"- Expected executor status: `{item['expected_executor_status']}`",
        f"- Expected overall: `{item['expected_overall']}`",
        f"- Execute allowed: {item['execute_allowed']}",
        "",
    ])

lines.extend(["## Invariants", ""])
for invariant in payload["invariants"]:
    lines.append(f"- {invariant}")

(artifact_root / "HUMAN_DECISION_FIXTURES.md").write_text(
    "\n".join(lines).rstrip() + "\n",
    encoding="utf-8",
)

print(json.dumps(payload, ensure_ascii=False, indent=2))
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
print("ARTEMIS Human Decision Fixtures")
print(
    "summary: "
    f"fixtures={summary['fixtures']} "
    f"valid={summary['valid']} "
    f"invalid={summary['invalid']} "
    f"execute_allowed={summary['execute_allowed']}"
)
for item in payload["fixtures"]:
    print(f"- {item['name']} [{item['expected_contract_state']}] {item['path']}")
PY
fi
