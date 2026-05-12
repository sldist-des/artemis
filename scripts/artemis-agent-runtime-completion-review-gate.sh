#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-completion-review-gate/run-01"
completion_handoff_path="artifacts/artemis-agent-runtime-completion-handoff/run-01/completion-handoff.json"
decision_path=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-completion-review-gate.sh [--artifact-root path] [--completion-handoff path] [--decision path] [--json]

Builds the ARTEMIS Agent Runtime Completion Review Gate from the Completion
Handoff. This script is read-only: it never accepts a review on behalf of a
human, marks Done, starts agents, runs commands, writes remotely, deploys, or
touches secrets.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --completion-handoff)
      completion_handoff_path="${2:-}"
      if [ -z "$completion_handoff_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision)
      decision_path="${2:-}"
      if [ -z "$decision_path" ]; then usage; exit 2; fi
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

mkdir -p "$artifact_root"
if [ -z "$decision_path" ]; then
  decision_path="$artifact_root/completion-review-decision.json"
fi

python3 - "$artifact_root" "$completion_handoff_path" "$decision_path" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
completion_handoff_path = Path(sys.argv[2])
decision_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()
blockers = []
warnings = []


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        blockers.append(f"missing JSON: {path}")
    except json.JSONDecodeError as exc:
        blockers.append(f"invalid JSON at {path}: {exc}")
    return {}


handoff = read_json(completion_handoff_path)
summary_in = handoff.get("summary") or {}
package = handoff.get("completion_package") or {}
residual_risks = list(package.get("residual_risks") or [])

handoff_ready = (
    handoff.get("overall") == "completion_handoff_ready"
    and summary_in.get("completion_handoff_ready") is True
    and summary_in.get("ready_for_done") is True
    and package.get("ready_for_human_acceptance") is True
)
handoff_failed = handoff.get("overall") == "failed"
rollback_required = summary_in.get("rollback_required") is True
failed_commands = int(summary_in.get("failed_commands", 0) or 0)
commands_executed = int(summary_in.get("commands_executed", 0) or 0)
validations_executed = int(summary_in.get("validations_executed", 0) or 0)
remote_writes_allowed = summary_in.get("remote_writes_allowed") is True
production_allowed = summary_in.get("production_allowed") is True
secrets_allowed = summary_in.get("secrets_allowed") is True

default_decision = {
    "schema_version": 1,
    "decision_record": {
        "decision": "pending",
        "decided_by": "",
        "decided_at": "",
        "reason": "",
        "accepted_evidence": [],
        "accepted_residual_risks": [],
        "done_authorized": False,
        "remote_close_authorized": False,
    },
}
if decision_path.exists():
    decision = read_json(decision_path)
else:
    decision = default_decision
    decision_path.write_text(json.dumps(decision, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

decision_record = decision.get("decision_record") or {}
decision_value = decision_record.get("decision", "pending")
valid_decisions = {"pending", "accepted", "changes_requested", "rejected"}
if decision_value not in valid_decisions:
    blockers.append(f"invalid completion review decision: {decision_value}")

accepted_ready = (
    handoff_ready
    and decision_value == "accepted"
    and bool(decision_record.get("decided_by"))
    and bool(decision_record.get("decided_at"))
    and bool(decision_record.get("reason"))
    and decision_record.get("done_authorized") is True
    and decision_record.get("remote_close_authorized") is False
)

if blockers:
    overall = "failed"
    review_state = "completion_review_contract_failed"
    next_action = "fix_completion_review_contract"
elif remote_writes_allowed or production_allowed or secrets_allowed:
    overall = "failed"
    review_state = "completion_review_scope_failed"
    next_action = "block_review_and_remove_remote_or_secret_scope"
elif not handoff_ready:
    overall = "human_gate"
    review_state = "waiting_for_completion_handoff_ready"
    next_action = "wait_for_completion_handoff_ready"
elif rollback_required or failed_commands:
    overall = "human_gate"
    review_state = "waiting_for_repair_or_rollback_review"
    next_action = "review_failed_commands_or_rollback_before_acceptance"
elif decision_value == "accepted" and not accepted_ready:
    overall = "human_gate"
    review_state = "waiting_for_complete_human_acceptance_record"
    next_action = "complete_human_acceptance_record"
elif accepted_ready:
    overall = "completion_review_accepted"
    review_state = "accepted_for_done_ledger"
    next_action = "record_done_in_agent_runtime_done_ledger"
elif decision_value in {"changes_requested", "rejected"}:
    overall = "human_gate"
    review_state = f"review_{decision_value}"
    next_action = "preserve_review_decision_and_prepare_follow_up"
else:
    overall = "human_gate"
    review_state = "waiting_for_human_completion_review"
    next_action = "collect_human_completion_review_decision"

review_checks = [
    {
        "id": "completion_handoff_exists",
        "status": "passed" if completion_handoff_path.is_file() else "failed",
        "proof": str(completion_handoff_path),
    },
    {
        "id": "completion_handoff_ready",
        "status": "passed" if handoff_ready else ("failed" if handoff_failed else "human_gate"),
        "proof": f"overall={handoff.get('overall')} ready={summary_in.get('completion_handoff_ready')}",
    },
    {
        "id": "human_decision_record_exists",
        "status": "passed" if decision_path.is_file() else "failed",
        "proof": str(decision_path),
    },
    {
        "id": "human_decision_pending_or_valid",
        "status": "passed" if decision_value in valid_decisions else "failed",
        "proof": f"decision={decision_value}",
    },
    {
        "id": "done_not_authorized_without_human_acceptance",
        "status": "passed" if (accepted_ready or decision_record.get("done_authorized") is not True) else "failed",
        "proof": f"accepted_ready={str(accepted_ready).lower()} done_authorized={decision_record.get('done_authorized')}",
    },
    {
        "id": "runtime_and_validation_evidence_reviewed",
        "status": "passed" if commands_executed >= 0 and validations_executed >= 0 else "failed",
        "proof": f"commands_executed={commands_executed} validations_executed={validations_executed}",
    },
    {
        "id": "remote_close_blocked",
        "status": "passed" if decision_record.get("remote_close_authorized") is not True else "failed",
        "proof": f"remote_close_authorized={decision_record.get('remote_close_authorized')}",
    },
]
failed_checks = [item for item in review_checks if item["status"] == "failed"]
human_gate_checks = [item for item in review_checks if item["status"] == "human_gate"]
if failed_checks and overall != "failed":
    overall = "failed"
    review_state = "completion_review_contract_failed"
    next_action = "fix_completion_review_contract"
    accepted_ready = False

summary = {
    "completion_handoff_ready": handoff_ready,
    "completion_review_ready": handoff_ready and not rollback_required and failed_commands == 0,
    "completion_review_accepted": accepted_ready,
    "ready_for_done_ledger": accepted_ready,
    "decision": decision_value,
    "commands_executed": commands_executed,
    "failed_commands": failed_commands,
    "validations_executed": validations_executed,
    "rollback_required": rollback_required,
    "residual_risks": len(residual_risks),
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(summary_in.get("paid_tokens_authorized", 0) or 0) if handoff_ready else 0,
    "review_checks": len(review_checks),
    "review_passed": sum(1 for item in review_checks if item["status"] == "passed"),
    "review_failed": len(failed_checks),
    "review_human_gate": len(human_gate_checks),
}

review_package = {
    "ready_for_done_ledger": accepted_ready,
    "ready_for_human_review": handoff_ready and not rollback_required and failed_commands == 0,
    "decision_file": str(decision_path),
    "decision_record": decision_record,
    "completion_handoff": {
        "overall": handoff.get("overall"),
        "handoff_state": handoff.get("handoff_state"),
        "next_action": handoff.get("next_action"),
    },
    "evidence_artifacts": package.get("evidence_artifacts") or {},
    "residual_risks": residual_risks,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-completion-review-gate.sh",
    "mode": "agent_runtime_completion_review_gate",
    "overall": overall,
    "reason": "Completion review gate was derived from completion handoff evidence and human review decision state.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "completion_handoff": str(completion_handoff_path),
        "decision": str(decision_path),
    },
    "review_state": review_state,
    "next_action": next_action,
    "summary": summary,
    "completion_handoff": review_package["completion_handoff"],
    "review_checks": review_checks,
    "review_package": review_package,
    "human_summary": {
        "status": overall,
        "plain_language": (
            "A revisao humana aceitou o pacote e ele pode seguir para o Done Ledger."
            if accepted_ready
            else "A revisao final ainda nao pode aceitar Done porque falta handoff pronto ou decisao humana completa."
        ),
        "operator_next_step": next_action,
    },
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Completion Review Gate consumes only Completion Handoff evidence plus a human-owned decision record.",
        "Agents must not accept final review on behalf of humans.",
        "Done Ledger is blocked until completion_review_accepted=true.",
        "Remote close remains blocked unless a later separate gate authorizes it.",
        "The review gate never runs commands, starts agents, pushes, deploys, or touches secrets.",
    ],
    "next_cut": "TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony",
}

(artifact_root / "completion-review-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION REVIEW GATE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Review state: `{review_state}`",
    f"- Next action: `{next_action}`",
    f"- Completion handoff ready: `{str(handoff_ready).lower()}`",
    f"- Human decision: `{decision_value}`",
    f"- Completion review accepted: `{str(accepted_ready).lower()}`",
    f"- Ready for Done Ledger: `{str(summary['ready_for_done_ledger']).lower()}`",
    f"- Residual risks: `{len(residual_risks)}`",
    "",
    "## Blockers",
    "",
]
if blockers:
    status_lines.extend(f"- {blocker}" for blocker in blockers)
else:
    status_lines.append("- Nenhum blocker tecnico local.")
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION REVIEW GATE VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Review state: `{review_state}`",
    f"- Human Gate: `{summary['review_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in review_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

review_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION REVIEW GATE",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Review state: `{review_state}`",
    f"- Ready for Done Ledger: `{str(summary['ready_for_done_ledger']).lower()}`",
    "",
    "## Decisao humana",
    "",
    f"- Decision: `{decision_value}`",
    f"- Decided by: `{decision_record.get('decided_by', '')}`",
    f"- Done authorized: `{str(decision_record.get('done_authorized')).lower()}`",
    f"- Remote close authorized: `{str(decision_record.get('remote_close_authorized')).lower()}`",
    "",
    "## Riscos residuais",
    "",
]
if residual_risks:
    review_lines.extend(f"- `{risk}`" for risk in residual_risks)
else:
    review_lines.append("- Nenhum risco residual reportado pelo Completion Handoff.")
(artifact_root / "COMPLETION_REVIEW_GATE.md").write_text("\n".join(review_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION REVIEW GATE HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-069 avaliou a revisao final como `{overall}` com estado `{review_state}`.",
    "",
    "## Proximo corte",
    "",
]
if accepted_ready:
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony` registrando Done tecnico sem fechamento remoto automatico.")
else:
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony`, mantendo Done bloqueado ate existir revisao aceita.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao aceitar revisao humana automaticamente.",
    "- Nao marcar Done sem `completion_review_accepted`.",
    "- Nao fechar GitHub, PR, issue, deploy ou remoto a partir deste gate.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

state_to = "review" if overall == "completion_review_accepted" else ("blocked" if overall == "failed" else "human_gate")
gate = {
    "kind": "human",
    "status": "resolved" if overall == "completion_review_accepted" else ("failed" if overall == "failed" else "human_gate"),
    "reason": "Completion review result.",
}
review_event = event(
    event_id="evt_tkt-069_agent_runtime_completion_review_gate",
    event_type="approval.requested" if overall != "completion_review_accepted" else "approval.resolved",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_completion_review_gate", "name": "scripts/artemis-agent-runtime-completion-review-gate.sh", "mode": "read_only"},
    ticket="TKT-069",
    title="Agent Runtime Completion Review Gate do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-069-artemis-agent-runtime-completion-review-gate.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to=state_to,
    severity="info" if overall == "completion_review_accepted" else ("error" if overall == "failed" else "warning"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "review_state": review_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={"kind": "none"},
    gate=gate,
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-completion-review-gate.sh", generated_at=generated_at, events=[review_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Completion Review Gate: {overall}")
    print(
        "summary: "
        f"review_state={review_state} "
        f"decision={decision_value} "
        f"ready_for_done_ledger={str(summary['ready_for_done_ledger']).lower()}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
