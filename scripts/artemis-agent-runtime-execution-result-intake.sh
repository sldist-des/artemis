#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-execution-result-intake/run-01"
supervised_execution_path="artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-execution-result-intake.sh [--artifact-root path] [--supervised-execution path] [--json]

Classifies the ARTEMIS Agent Runtime Supervised Execution result. This is a
read-only intake step: it does not run agents, execute commands, install
dependencies, write remotely, deploy, or touch secrets.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --supervised-execution)
      supervised_execution_path="${2:-}"
      if [ -z "$supervised_execution_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$supervised_execution_path" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
supervised_execution_path = Path(sys.argv[2])
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


supervised_execution = read_json(supervised_execution_path)
supervised_summary = supervised_execution.get("summary") or {}
command_results = list(supervised_execution.get("command_results") or [])
execution_plan = supervised_execution.get("execution_plan") or {}
validation_plan = execution_plan.get("validation") or {}
rollback_plan = execution_plan.get("rollback") or {}

supervised_overall = supervised_execution.get("overall", "not_available")
supervised_state = supervised_execution.get("execution_state", "unknown")
execute_requested = supervised_summary.get("execute_requested") is True
runtime_started = supervised_summary.get("runtime_started") is True
commands_executed = int(supervised_summary.get("commands_executed", 0) or 0)
agents_started = int(supervised_summary.get("agents_started", 0) or 0)
remote_writes_allowed = supervised_summary.get("remote_writes_allowed") is True
production_allowed = supervised_summary.get("production_allowed") is True
secrets_allowed = supervised_summary.get("secrets_allowed") is True
paid_tokens_authorized = int(supervised_summary.get("paid_tokens_authorized", 0) or 0)

failed_command_results = [
    item for item in command_results
    if int(item.get("exit_code", 0) or 0) != 0
]
attempt_executed = runtime_started or commands_executed > 0 or bool(command_results)
attempt_planned = supervised_overall in {"human_gate", "supervised_execution_ready"} and not attempt_executed
supervised_completed = supervised_overall == "supervised_execution_completed"
supervised_failed = supervised_overall == "failed" or bool(failed_command_results)
supervised_blocked = supervised_overall == "human_gate" and not attempt_executed

if blockers:
    overall = "failed"
    intake_state = "missing_supervised_execution_result"
    result_kind = "missing_input"
    next_action = "restore_supervised_execution_artifact"
elif supervised_failed:
    overall = "failed"
    intake_state = "execution_failed"
    result_kind = "completed_with_failures" if command_results else "failed_before_execution"
    next_action = "preserve_logs_and_prepare_rollback_review"
elif supervised_completed and attempt_executed:
    overall = "execution_result_intake_ready"
    intake_state = "completed_success"
    result_kind = "completed_success"
    next_action = "run_post_execution_validation_gate"
elif supervised_overall == "supervised_execution_ready" and not attempt_executed:
    overall = "human_gate"
    intake_state = "plan_only_ready_no_execution_result"
    result_kind = "plan_only_ready"
    next_action = "run_supervised_execution_with_execute_after_final_confirmation"
elif supervised_blocked:
    overall = "human_gate"
    intake_state = "waiting_for_supervised_execution_result"
    result_kind = "blocked_pending_gate"
    next_action = "wait_for_supervised_execution_completed_or_ready"
else:
    overall = "human_gate"
    intake_state = "waiting_for_supervised_execution_result"
    result_kind = "not_executed"
    next_action = "wait_for_supervised_execution_completed_or_ready"

supervised_execution_result_ready = overall == "execution_result_intake_ready"
validation_ready = supervised_execution_result_ready and validation_plan.get("required_before_done") is True
rollback_required = overall == "failed" or bool(failed_command_results)

result_checks = [
    {
        "id": "supervised_execution_exists",
        "status": "passed" if supervised_execution_path.is_file() else "failed",
        "proof": str(supervised_execution_path),
    },
    {
        "id": "plan_only_not_success",
        "status": "passed" if not (attempt_planned and supervised_execution_result_ready) else "failed",
        "proof": f"attempt_planned={str(attempt_planned).lower()} result_ready={str(supervised_execution_result_ready).lower()}",
    },
    {
        "id": "supervised_execution_completed",
        "status": "passed" if supervised_completed and attempt_executed else "human_gate",
        "proof": f"overall={supervised_overall} executed={str(attempt_executed).lower()}",
    },
    {
        "id": "command_results_classified",
        "status": "passed" if len(failed_command_results) == 0 else "failed",
        "proof": f"commands_executed={commands_executed} failed_commands={len(failed_command_results)}",
    },
    {
        "id": "validation_evidence_required",
        "status": "passed" if validation_plan.get("required_before_done") is True or not supervised_execution_result_ready else "failed",
        "proof": f"required_before_done={validation_plan.get('required_before_done')}",
    },
    {
        "id": "rollback_state_classified",
        "status": "passed",
        "proof": f"rollback_required={str(rollback_required).lower()} preserve_logs={rollback_plan.get('preserve_logs')}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if not remote_writes_allowed and not production_allowed and not secrets_allowed else "failed",
        "proof": f"remote={str(remote_writes_allowed).lower()} production={str(production_allowed).lower()} secrets={str(secrets_allowed).lower()}",
    },
]

failed_checks = [item for item in result_checks if item["status"] == "failed"]
human_gate_checks = [item for item in result_checks if item["status"] == "human_gate"]
if failed_checks and overall != "failed":
    overall = "failed"
    intake_state = "result_intake_failed"
    result_kind = "invalid_result_contract"
    next_action = "fix_result_intake_contract"

summary = {
    "supervised_execution_result_ready": supervised_execution_result_ready,
    "supervised_execution_completed": supervised_completed,
    "supervised_execution_failed": supervised_failed,
    "supervised_execution_blocked": supervised_blocked,
    "attempt_planned": attempt_planned,
    "attempt_executed": attempt_executed,
    "commands_executed": commands_executed,
    "failed_commands": len(failed_command_results),
    "runtime_started": runtime_started,
    "agents_started": agents_started,
    "validation_ready": validation_ready,
    "rollback_required": rollback_required,
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": paid_tokens_authorized if attempt_executed else 0,
    "result_checks": len(result_checks),
    "result_passed": sum(1 for item in result_checks if item["status"] == "passed"),
    "result_failed": len([item for item in result_checks if item["status"] == "failed"]),
    "result_human_gate": len([item for item in result_checks if item["status"] == "human_gate"]),
}

result_package = {
    "result_kind": result_kind,
    "ready_for_validation": validation_ready,
    "ready_for_handoff": overall in {"human_gate", "execution_result_intake_ready", "failed"},
    "rollback_required": rollback_required,
    "preserve_logs": rollback_plan.get("preserve_logs") is True or bool(command_results),
    "commands": {
        "planned": int(supervised_summary.get("approved_commands_count", 0) or 0),
        "executed": commands_executed,
        "failed": len(failed_command_results),
    },
    "logs": [
        {
            "step": item.get("step"),
            "stdout_path": item.get("stdout_path", ""),
            "stderr_path": item.get("stderr_path", ""),
            "exit_code": item.get("exit_code"),
        }
        for item in command_results
    ],
    "validation": {
        "required_before_done": validation_plan.get("required_before_done") is True,
        "commands": validation_plan.get("commands", []),
    },
    "rollback": {
        "required": rollback_required,
        "plan": rollback_plan,
    },
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-execution-result-intake.sh",
    "mode": "agent_runtime_execution_result_intake",
    "overall": overall,
    "reason": "Supervised execution result was classified before post-execution validation.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "supervised_execution": str(supervised_execution_path),
    },
    "intake_state": intake_state,
    "next_action": next_action,
    "summary": summary,
    "supervised_execution": {
        "overall": supervised_overall,
        "execution_state": supervised_state,
        "next_action": supervised_execution.get("next_action"),
    },
    "result_checks": result_checks,
    "result_package": result_package,
    "command_results": command_results,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Execution Result Intake is read-only and never starts agents or commands.",
        "Plan-only and Human Gate states must never be classified as successful execution.",
        "A completed result needs executed command evidence before post-execution validation.",
        "Failed commands require log preservation and rollback review before any Done state.",
        "Remote writes, production and secrets remain blocked in this intake cut.",
    ],
    "next_cut": "TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony",
}

(artifact_root / "execution-result-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME EXECUTION RESULT INTAKE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Intake state: `{intake_state}`",
    f"- Result kind: `{result_kind}`",
    f"- Next action: `{next_action}`",
    f"- Supervised execution overall: `{supervised_overall}`",
    f"- Attempt planned: `{str(attempt_planned).lower()}`",
    f"- Attempt executed: `{str(attempt_executed).lower()}`",
    f"- Result ready: `{str(supervised_execution_result_ready).lower()}`",
    f"- Commands executed: `{commands_executed}`",
    f"- Failed commands: `{len(failed_command_results)}`",
    f"- Rollback required: `{str(rollback_required).lower()}`",
    f"- Remote writes allowed: `false`",
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
    "# ARTEMIS AGENT RUNTIME EXECUTION RESULT INTAKE VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Intake state: `{intake_state}`",
    f"- Result ready: `{str(supervised_execution_result_ready).lower()}`",
    f"- Commands executed: `{commands_executed}`",
    f"- Failed commands: `{len(failed_command_results)}`",
    f"- Human Gate: `{summary['result_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in result_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

result_lines = [
    "# ARTEMIS AGENT RUNTIME EXECUTION RESULT INTAKE",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Intake state: `{intake_state}`",
    f"- Result kind: `{result_kind}`",
    "",
    "## Evidencia de comandos",
    "",
]
if command_results:
    for item in command_results:
        result_lines.append(f"- Step `{item.get('step')}` exit_code `{item.get('exit_code')}` stdout `{item.get('stdout_path', '')}` stderr `{item.get('stderr_path', '')}`.")
else:
    result_lines.append("- Nenhum comando foi executado; este estado nao pode ser considerado sucesso.")
result_lines.extend([
    "",
    "## Proxima validacao",
    "",
    "- Post-execution Validation Gate so pode rodar quando `supervised_execution_result_ready=true`.",
])
(artifact_root / "RESULT_INTAKE.md").write_text("\n".join(result_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME EXECUTION RESULT INTAKE HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-066 classificou o resultado supervisionado como `{overall}` com estado `{intake_state}`.",
    "",
    "## Proximo corte",
    "",
]
if supervised_execution_result_ready:
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony` rodando validacoes pos-execucao sobre logs e comandos executados.")
else:
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony`, mantendo validacao pos-execucao bloqueada ate existir execucao supervisionada real.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao tratar plano, Human Gate ou dry-run como resultado concluido.",
    "- Nao marcar Done sem logs, exit codes e Validation Gate pos-execucao.",
    "- Nao executar agentes ou comandos dentro do intake.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if overall == "execution_result_intake_ready":
    event_type = "runner.result_recorded"
    state_to = "ready"
    severity = "info"
    gate = {"kind": "none", "status": "not_applicable"}
elif overall == "failed":
    event_type = "runner.result_failed"
    state_to = "blocked"
    severity = "error"
    gate = {"kind": "validation", "status": "failed", "reason": "Execution result intake failed."}
else:
    event_type = "runner.result_blocked"
    state_to = "human_gate"
    severity = "warning"
    gate = {
        "kind": "human",
        "status": "human_gate",
        "reason": "No completed supervised execution result is available yet.",
    }

result_event = event(
    event_id="evt_tkt-066_agent_runtime_execution_result_intake",
    event_type=event_type,
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_execution_result_intake", "name": "scripts/artemis-agent-runtime-execution-result-intake.sh", "mode": "read_only"},
    ticket="TKT-066",
    title="Agent Runtime Execution Result Intake do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-066-artemis-agent-runtime-execution-result-intake.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to=state_to,
    severity=severity,
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "intake_state": intake_state,
        "result_kind": result_kind,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": "none",
        "result_intake": "agent_runtime_execution_result_intake",
        "attempt_executed": attempt_executed,
        "commands_executed": commands_executed,
        "failed_commands": len(failed_command_results),
    },
    gate=gate,
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-execution-result-intake.sh", generated_at=generated_at, events=[result_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Execution Result Intake: {overall}")
    print(
        "summary: "
        f"intake_state={intake_state} "
        f"result_ready={str(supervised_execution_result_ready).lower()} "
        f"commands_executed={commands_executed}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
