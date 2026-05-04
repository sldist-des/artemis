#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

decision="artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json"
runbook_root="artifacts/artemis-assisted-human-decision-runbook/run-01"
artifact_root="artifacts/artemis-human-decision-runbook-consistency/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-runbook-consistency.sh [--decision path] [--runbook-root path] [--artifact-root path] [--json]" >&2
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
    --runbook-root)
      runbook_root="${2:-}"
      if [ -z "$runbook_root" ]; then
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

if [ ! -d "$runbook_root" ]; then
  echo "runbook root not found: $runbook_root" >&2
  exit 2
fi

mkdir -p "$artifact_root"

payload=$(python3 - "$decision" "$runbook_root" "$artifact_root" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

decision_path = Path(sys.argv[1])
runbook_root = Path(sys.argv[2])
artifact_root = Path(sys.argv[3])
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

criteria_path = runbook_root / "DECISION_CRITERIA.md"
examples_path = runbook_root / "HUMAN_DECISION_EXAMPLES.md"
runbook_path = runbook_root / "RUNBOOK.md"

required_docs = [criteria_path, examples_path, runbook_path]
missing_docs = [str(path) for path in required_docs if not path.is_file()]

decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))
criteria = criteria_path.read_text(encoding="utf-8") if criteria_path.is_file() else ""
examples = examples_path.read_text(encoding="utf-8") if examples_path.is_file() else ""
runbook = runbook_path.read_text(encoding="utf-8") if runbook_path.is_file() else ""

results = []
blockers = []

if missing_docs:
    blockers.extend(f"missing runbook document: {path}" for path in missing_docs)

reviews = decision_payload.get("reviews", [])
expected_tickets = ["TKT-021", "TKT-022", "TKT-023"]
actual_tickets = [str(item.get("ticket")) for item in reviews]
if actual_tickets != expected_tickets:
    blockers.append(f"decision tickets differ from expected order: {actual_tickets}")


def contains_literal(document: str, value: str) -> bool:
    return value in document


for review in reviews:
    ticket = str(review.get("ticket"))
    item_blockers = []
    required_evidence = [str(item) for item in review.get("required_evidence") or []]
    commands = [str(item) for item in review.get("commands_after_approval") or []]
    decision_record = review.get("decision_record") or {}

    if not contains_literal(criteria, f"## {ticket}"):
        item_blockers.append("ticket section missing from DECISION_CRITERIA.md")
    if not contains_literal(criteria, str(review.get("title", ""))):
        item_blockers.append("ticket title missing from DECISION_CRITERIA.md")
    for evidence in required_evidence:
        if not contains_literal(criteria, evidence):
            item_blockers.append(f"required evidence missing from DECISION_CRITERIA.md: {evidence}")
    for command in commands:
        if not contains_literal(criteria, command):
            item_blockers.append(f"approval command missing from DECISION_CRITERIA.md: {command}")

    if decision_record.get("decision") != "pending":
        item_blockers.append("real decision is no longer pending")
    if decision_record.get("approved_commands"):
        item_blockers.append("real decision has approved_commands before human approval")

    results.append({
        "ticket": ticket,
        "required_evidence": len(required_evidence),
        "commands_after_approval": len(commands),
        "decision": decision_record.get("decision"),
        "blockers": item_blockers,
    })
    blockers.extend(f"{ticket}: {item}" for item in item_blockers)

example_checks = {
    "examples_warn_not_authorization": "Os exemplos abaixo mostram formato, nao autorizacao." in examples,
    "examples_include_invalid_partial": "Este exemplo e invalido porque aprova parcialmente" in examples,
    "examples_say_deferred_for_partial": "Use `deferred` quando a aprovacao for parcial." in examples,
    "runbook_says_agent_must_not_decide": "a decisao permanece humana" in runbook,
    "runbook_keeps_execute_out_of_scope": "Este TKT nao usa `--execute`." in runbook,
}
for name, passed in example_checks.items():
    if not passed:
        blockers.append(f"runbook/example invariant failed: {name}")

summary = {
    "tickets_checked": len(results),
    "expected_tickets": len(expected_tickets),
    "commands_checked": sum(item["commands_after_approval"] for item in results),
    "evidence_checked": sum(item["required_evidence"] for item in results),
    "example_checks": len(example_checks),
    "blockers": len(blockers),
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-runbook-consistency.sh",
    "mode": "read_only",
    "decision": str(decision_path),
    "runbook_root": str(runbook_root),
    "overall": "passed" if not blockers else "failed",
    "summary": summary,
    "results": results,
    "example_checks": example_checks,
    "blockers": blockers,
    "invariants": [
        "The runbook is not authorization.",
        "The real decision JSON remains canonical for human decisions.",
        "Examples must not be treated as executable decisions.",
        "This check never removes worktrees, locks, or branches.",
    ],
}

(artifact_root / "runbook-consistency.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS HUMAN DECISION RUNBOOK CONSISTENCY",
    "",
    f"- Generated at: {generated_at}",
    f"- Overall: `{payload['overall']}`",
    f"- Decision: `{decision_path}`",
    f"- Runbook root: `{runbook_root}`",
    f"- Tickets checked: {summary['tickets_checked']}",
    f"- Commands checked: {summary['commands_checked']}",
    f"- Evidence checked: {summary['evidence_checked']}",
    f"- Example checks: {summary['example_checks']}",
    f"- Blockers: {summary['blockers']}",
    "",
    "## Results",
    "",
]
for item in results:
    lines.extend([
        f"### {item['ticket']}",
        "",
        f"- Decision: `{item['decision']}`",
        f"- Required evidence checked: {item['required_evidence']}",
        f"- Commands checked: {item['commands_after_approval']}",
    ])
    if item["blockers"]:
        lines.append("- Blockers:")
        lines.extend(f"  - {blocker}" for blocker in item["blockers"])
    lines.append("")

lines.extend(["## Example Checks", ""])
for name, passed in example_checks.items():
    lines.append(f"- `{name}`: {passed}")

if blockers:
    lines.extend(["", "## Blockers", ""])
    lines.extend(f"- {blocker}" for blocker in blockers)

(artifact_root / "RUNBOOK_CONSISTENCY.md").write_text(
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
print("ARTEMIS Human Decision Runbook Consistency")
print(
    "summary: "
    f"overall={payload['overall']} "
    f"tickets={summary['tickets_checked']} "
    f"commands={summary['commands_checked']} "
    f"evidence={summary['evidence_checked']} "
    f"blockers={summary['blockers']}"
)
for item in payload["results"]:
    print(f"- {item['ticket']} [{item['decision']}] blockers={len(item['blockers'])}")
PY
fi
