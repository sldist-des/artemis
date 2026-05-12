#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-done-ledger/run-01"
completion_review_gate_path="artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-done-ledger.sh [--artifact-root path] [--completion-review-gate path] [--json]

Builds the ARTEMIS Agent Runtime Done Ledger from the Completion Review Gate.
This script is read-only with respect to external systems: it never accepts a
review, starts agents, runs commands, closes GitHub work, pushes, deploys,
touches production, or touches secrets.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --completion-review-gate)
      completion_review_gate_path="${2:-}"
      if [ -z "$completion_review_gate_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$completion_review_gate_path" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
completion_review_gate_path = Path(sys.argv[2])
output_format = sys.argv[3]
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


review = read_json(completion_review_gate_path)
summary_in = review.get("summary") or {}
review_package = review.get("review_package") or {}
decision_record = review_package.get("decision_record") or {}
completion_handoff = review.get("completion_handoff") or {}
residual_risks = list(review_package.get("residual_risks") or [])

review_accepted = (
    review.get("overall") == "completion_review_accepted"
    and summary_in.get("completion_review_accepted") is True
    and summary_in.get("ready_for_done_ledger") is True
    and review_package.get("ready_for_done_ledger") is True
)
review_failed = review.get("overall") == "failed"
decision_value = decision_record.get("decision", summary_in.get("decision", "pending"))
done_authorized = decision_record.get("done_authorized") is True
remote_close_authorized = decision_record.get("remote_close_authorized") is True
commands_executed = int(summary_in.get("commands_executed", 0) or 0)
failed_commands = int(summary_in.get("failed_commands", 0) or 0)
validations_executed = int(summary_in.get("validations_executed", 0) or 0)
rollback_required = summary_in.get("rollback_required") is True
remote_writes_allowed = summary_in.get("remote_writes_allowed") is True
production_allowed = summary_in.get("production_allowed") is True
secrets_allowed = summary_in.get("secrets_allowed") is True

done_ledger_recorded = (
    review_accepted
    and done_authorized
    and not remote_close_authorized
    and not rollback_required
    and failed_commands == 0
)

if blockers:
    overall = "failed"
    ledger_state = "done_ledger_contract_failed"
    next_action = "fix_done_ledger_contract"
elif remote_writes_allowed or production_allowed or secrets_allowed or remote_close_authorized:
    overall = "failed"
    ledger_state = "done_ledger_scope_failed"
    next_action = "block_done_ledger_and_remove_remote_or_secret_scope"
elif not review_accepted:
    overall = "human_gate"
    ledger_state = "waiting_for_completion_review_accepted"
    next_action = "wait_for_completion_review_accepted"
elif rollback_required or failed_commands:
    overall = "human_gate"
    ledger_state = "waiting_for_repair_or_rollback_before_done"
    next_action = "review_failed_commands_or_rollback_before_done"
elif done_ledger_recorded:
    overall = "done_ledger_recorded"
    ledger_state = "local_done_recorded"
    next_action = "runtime_spine_complete"
else:
    overall = "human_gate"
    ledger_state = "waiting_for_done_authorization_consistency"
    next_action = "complete_done_authorization_record"

ledger_checks = [
    {
        "id": "completion_review_gate_exists",
        "status": "passed" if completion_review_gate_path.is_file() else "failed",
        "proof": str(completion_review_gate_path),
    },
    {
        "id": "completion_review_accepted",
        "status": "passed" if review_accepted else ("failed" if review_failed else "human_gate"),
        "proof": f"overall={review.get('overall')} accepted={summary_in.get('completion_review_accepted')}",
    },
    {
        "id": "done_ledger_requires_human_acceptance",
        "status": "passed" if (review_accepted or not done_ledger_recorded) else "failed",
        "proof": f"review_accepted={str(review_accepted).lower()} done_ledger_recorded={str(done_ledger_recorded).lower()}",
    },
    {
        "id": "remote_close_blocked",
        "status": "passed" if not remote_close_authorized else "failed",
        "proof": f"remote_close_authorized={str(remote_close_authorized).lower()}",
    },
    {
        "id": "runtime_evidence_preserved",
        "status": "passed" if commands_executed >= 0 and validations_executed >= 0 else "failed",
        "proof": f"commands_executed={commands_executed} validations_executed={validations_executed}",
    },
    {
        "id": "no_commands_executed_by_done_ledger",
        "status": "passed",
        "proof": "done ledger is read-only and executes no commands",
    },
    {
        "id": "done_record_consistent",
        "status": "passed" if (done_ledger_recorded or not done_authorized) else "human_gate",
        "proof": f"done_authorized={str(done_authorized).lower()} ledger_recorded={str(done_ledger_recorded).lower()}",
    },
]
failed_checks = [item for item in ledger_checks if item["status"] == "failed"]
human_gate_checks = [item for item in ledger_checks if item["status"] == "human_gate"]
if failed_checks and overall != "failed":
    overall = "failed"
    ledger_state = "done_ledger_contract_failed"
    next_action = "fix_done_ledger_contract"
    done_ledger_recorded = False

summary = {
    "completion_review_accepted": review_accepted,
    "ready_for_done_ledger": review_accepted,
    "done_ledger_recorded": done_ledger_recorded,
    "technical_done": done_ledger_recorded,
    "remote_done_closed": False,
    "decision": decision_value,
    "commands_executed": commands_executed,
    "failed_commands": failed_commands,
    "validations_executed": validations_executed,
    "rollback_required": rollback_required,
    "residual_risks": len(residual_risks),
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(summary_in.get("paid_tokens_authorized", 0) or 0) if review_accepted else 0,
    "ledger_checks": len(ledger_checks),
    "ledger_passed": sum(1 for item in ledger_checks if item["status"] == "passed"),
    "ledger_failed": len(failed_checks),
    "ledger_human_gate": len(human_gate_checks),
}

done_record = {
    "status": "recorded" if done_ledger_recorded else "blocked",
    "recorded_at": generated_at if done_ledger_recorded else "",
    "recorded_by": "artemis-agent-runtime-done-ledger" if done_ledger_recorded else "",
    "technical_done": done_ledger_recorded,
    "remote_done_closed": False,
    "completion_review_gate": str(completion_review_gate_path),
    "completion_review": {
        "overall": review.get("overall"),
        "review_state": review.get("review_state"),
        "decision": decision_value,
    },
    "completion_handoff": completion_handoff,
    "residual_risks": residual_risks,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-done-ledger.sh",
    "mode": "agent_runtime_done_ledger",
    "overall": overall,
    "reason": "Done Ledger was derived from completion review evidence without closing external systems.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "completion_review_gate": str(completion_review_gate_path),
    },
    "ledger_state": ledger_state,
    "next_action": next_action,
    "summary": summary,
    "completion_review_gate": {
        "overall": review.get("overall"),
        "review_state": review.get("review_state"),
        "next_action": review.get("next_action"),
    },
    "ledger_checks": ledger_checks,
    "done_record": done_record,
    "human_summary": {
        "status": overall,
        "plain_language": (
            "O Done tecnico local foi registrado; fechamento remoto continua separado."
            if done_ledger_recorded
            else "O Done tecnico local ainda esta bloqueado ate a revisao humana final ser aceita."
        ),
        "operator_next_step": next_action,
    },
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Done Ledger consumes only Completion Review Gate evidence.",
        "Technical Done is blocked until completion_review_accepted=true.",
        "Remote close, GitHub close, PR merge, deploy and production remain out of scope.",
        "The Done Ledger never runs commands, starts agents, pushes, deploys, or touches secrets.",
        "If recorded, this ledger records local technical Done only.",
    ],
    "next_cut": "NONE - ARTEMIS Symphony runtime spine complete",
}

(artifact_root / "done-ledger.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME DONE LEDGER STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Ledger state: `{ledger_state}`",
    f"- Next action: `{next_action}`",
    f"- Completion review accepted: `{str(review_accepted).lower()}`",
    f"- Done ledger recorded: `{str(done_ledger_recorded).lower()}`",
    f"- Technical done: `{str(summary['technical_done']).lower()}`",
    f"- Remote done closed: `{str(summary['remote_done_closed']).lower()}`",
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
    "# ARTEMIS AGENT RUNTIME DONE LEDGER VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Ledger state: `{ledger_state}`",
    f"- Human Gate: `{summary['ledger_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in ledger_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

ledger_lines = [
    "# ARTEMIS AGENT RUNTIME DONE LEDGER",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Ledger state: `{ledger_state}`",
    f"- Done ledger recorded: `{str(done_ledger_recorded).lower()}`",
    f"- Technical done: `{str(summary['technical_done']).lower()}`",
    f"- Remote done closed: `{str(summary['remote_done_closed']).lower()}`",
    "",
    "## Registro",
    "",
    f"- Status: `{done_record['status']}`",
    f"- Recorded at: `{done_record['recorded_at']}`",
    f"- Recorded by: `{done_record['recorded_by']}`",
    "",
    "## Riscos residuais",
    "",
]
if residual_risks:
    ledger_lines.extend(f"- `{risk}`" for risk in residual_risks)
else:
    ledger_lines.append("- Nenhum risco residual reportado pelo Completion Review Gate.")
(artifact_root / "DONE_LEDGER.md").write_text("\n".join(ledger_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME DONE LEDGER HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-070 avaliou o Done Ledger como `{overall}` com estado `{ledger_state}`.",
    "",
    "## Proximo corte",
    "",
    "- Nenhum TKT planejado no escopo atual da espinha de runtime.",
    "- Abrir novo Exec Pack apenas para uma nova fase ou melhoria deliberada.",
    "",
    "## Nao fazer",
    "",
    "- Nao marcar Done tecnico sem `completion_review_accepted`.",
    "- Nao fechar GitHub, PR, issue, deploy ou remoto a partir deste ledger.",
    "- Nao tratar este ledger como aceite de produto ou producao.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

state_to = "done" if overall == "done_ledger_recorded" else ("blocked" if overall == "failed" else "human_gate")
gate = {
    "kind": "human",
    "status": "resolved" if overall == "done_ledger_recorded" else ("failed" if overall == "failed" else "human_gate"),
    "reason": "Done Ledger result.",
}
done_event = event(
    event_id="evt_tkt-070_agent_runtime_done_ledger",
    event_type="task.state_changed" if overall == "done_ledger_recorded" else "human_gate.opened",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_done_ledger", "name": "scripts/artemis-agent-runtime-done-ledger.sh", "mode": "read_only"},
    ticket="TKT-070",
    title="Agent Runtime Done Ledger do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-070-artemis-agent-runtime-done-ledger.md",
    artifact_root=str(artifact_root),
    state_from="review",
    state_to=state_to,
    severity="info" if overall == "done_ledger_recorded" else ("error" if overall == "failed" else "warning"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "ledger_state": ledger_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={"kind": "none"},
    gate=gate,
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-done-ledger.sh", generated_at=generated_at, events=[done_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Done Ledger: {overall}")
    print(
        "summary: "
        f"ledger_state={ledger_state} "
        f"done_ledger_recorded={str(done_ledger_recorded).lower()} "
        f"technical_done={str(summary['technical_done']).lower()}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
