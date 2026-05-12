#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01"
result_intake_path="artifacts/artemis-agent-runtime-execution-result-intake/run-01/execution-result-intake.json"
format="text"
execute="false"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-post-execution-validation-gate.sh [--artifact-root path] [--result-intake path] [--execute] [--json]

Builds the ARTEMIS Agent Runtime Post-Execution Validation Gate from an
Execution Result Intake. By default this is read-only. With --execute it can
run only validation commands declared by a ready result intake. It never writes
remotely, touches secrets, deploys, or changes production.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --result-intake)
      result_intake_path="${2:-}"
      if [ -z "$result_intake_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --execute)
      execute="true"
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

mkdir -p "$artifact_root"

python3 - "$artifact_root" "$result_intake_path" "$execute" "$format" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
result_intake_path = Path(sys.argv[2])
execute_requested = sys.argv[3] == "true"
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


def run(command):
    return subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, shell=True, check=False)


result_intake = read_json(result_intake_path)
intake_summary = result_intake.get("summary") or {}
result_package = result_intake.get("result_package") or {}
result_validation = result_package.get("validation") or {}
result_commands = result_package.get("commands") or {}
result_logs = result_package.get("logs") or []
rollback = result_package.get("rollback") or {}

intake_ready = (
    result_intake.get("overall") == "execution_result_intake_ready"
    and intake_summary.get("supervised_execution_result_ready") is True
    and intake_summary.get("attempt_executed") is True
    and int(intake_summary.get("commands_executed", 0) or 0) > 0
)
validation_commands = list(result_validation.get("commands") or [])
validation_required = result_validation.get("required_before_done") is True
rollback_required = result_package.get("rollback_required") is True or intake_summary.get("rollback_required") is True
commands_executed = int(intake_summary.get("commands_executed", 0) or 0)
failed_commands = int(intake_summary.get("failed_commands", 0) or 0)
remote_writes_allowed = intake_summary.get("remote_writes_allowed") is True
production_allowed = intake_summary.get("production_allowed") is True
secrets_allowed = intake_summary.get("secrets_allowed") is True

blocked_patterns = [
    r"\bgit\s+push\b",
    r"\bgh\s+(pr|issue|repo|api)\b",
    r"\bdeploy\b",
    r"\bkubectl\b",
    r"\bscp\b",
    r"\brsync\b",
    r"\bssh\s+",
    r"\bsudo\b",
    r"\brm\s+-rf\b",
]
if intake_ready:
    if validation_required and not validation_commands:
        blockers.append("result_package.validation.commands is required when validation is required")
    if failed_commands:
        blockers.append("post-execution validation cannot pass with failed runtime commands")
    if not result_logs and commands_executed > 0:
        blockers.append("executed runtime commands must preserve stdout/stderr log paths")
    for command in validation_commands:
        if not isinstance(command, str) or not command.strip():
            blockers.append("validation commands cannot be empty")
            continue
        for pattern in blocked_patterns:
            if re.search(pattern, command):
                blockers.append(f"validation command is blocked in post-execution gate: {command}")
                break

validation_results = []
can_execute = intake_ready and execute_requested and not blockers
ready_plan_only = intake_ready and not execute_requested and not blockers
if can_execute:
    for index, command in enumerate(validation_commands, 1):
        result = run(command)
        validation_results.append({
            "step": index,
            "command": command,
            "exit_code": result.returncode,
            "stdout_path": f"{artifact_root}/validation-{index:02d}.stdout.txt",
            "stderr_path": f"{artifact_root}/validation-{index:02d}.stderr.txt",
        })
        (artifact_root / f"validation-{index:02d}.stdout.txt").write_text(result.stdout, encoding="utf-8")
        (artifact_root / f"validation-{index:02d}.stderr.txt").write_text(result.stderr, encoding="utf-8")
        if result.returncode != 0:
            blockers.append(f"post-execution validation failed at step {index}: exit_code={result.returncode}")
            break

validation_failed = any(int(item.get("exit_code", 0) or 0) != 0 for item in validation_results)
validations_executed = len(validation_results)

if blockers and not validation_failed and not result_intake_path.is_file():
    overall = "failed"
    post_validation_state = "missing_execution_result_intake"
    next_action = "restore_execution_result_intake_artifact"
elif validation_failed or (blockers and intake_ready):
    overall = "failed"
    post_validation_state = "post_execution_validation_failed"
    next_action = "preserve_validation_logs_and_prepare_repair_or_rollback"
elif can_execute:
    overall = "post_execution_validation_completed"
    post_validation_state = "completed"
    next_action = "prepare_runtime_completion_handoff"
elif ready_plan_only:
    overall = "post_execution_validation_ready"
    post_validation_state = "ready_execute_false"
    next_action = "rerun_with_execute_after_final_validation_confirmation"
elif result_intake.get("overall") == "failed":
    overall = "human_gate"
    post_validation_state = "waiting_for_result_intake_repair"
    next_action = "repair_execution_result_intake_before_validation"
elif result_intake.get("overall") == "human_gate":
    overall = "human_gate"
    post_validation_state = "waiting_for_execution_result_intake_ready"
    next_action = "wait_for_execution_result_intake_ready"
else:
    overall = "human_gate"
    post_validation_state = "waiting_for_execution_result_intake_ready"
    next_action = "wait_for_execution_result_intake_ready"

post_execution_validation_ready = overall in {"post_execution_validation_ready", "post_execution_validation_completed"}

validation_checks = [
    {
        "id": "execution_result_intake_exists",
        "status": "passed" if result_intake_path.is_file() else "failed",
        "proof": str(result_intake_path),
    },
    {
        "id": "execution_result_intake_ready",
        "status": "passed" if intake_ready else "human_gate",
        "proof": f"overall={result_intake.get('overall')} result_ready={intake_summary.get('supervised_execution_result_ready')}",
    },
    {
        "id": "plan_only_not_validated",
        "status": "passed" if not (not intake_ready and validations_executed > 0) else "failed",
        "proof": f"intake_ready={str(intake_ready).lower()} validations_executed={validations_executed}",
    },
    {
        "id": "runtime_logs_available",
        "status": "passed" if (not intake_ready or bool(result_logs)) else "failed",
        "proof": f"logs={len(result_logs)} commands_executed={commands_executed}",
    },
    {
        "id": "validation_commands_declared",
        "status": "passed" if (not intake_ready or not validation_required or bool(validation_commands)) else "failed",
        "proof": f"required={str(validation_required).lower()} commands={len(validation_commands)}",
    },
    {
        "id": "rollback_state_reviewed",
        "status": "human_gate" if rollback_required and not validation_failed else "passed",
        "proof": f"rollback_required={str(rollback_required).lower()} rollback_keys={len(rollback)}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if not remote_writes_allowed and not production_allowed and not secrets_allowed else "failed",
        "proof": f"remote={str(remote_writes_allowed).lower()} production={str(production_allowed).lower()} secrets={str(secrets_allowed).lower()}",
    },
]
failed_checks = [item for item in validation_checks if item["status"] == "failed"]
human_gate_checks = [item for item in validation_checks if item["status"] == "human_gate"]
if failed_checks and overall != "failed":
    overall = "failed"
    post_validation_state = "post_execution_validation_contract_failed"
    next_action = "fix_post_execution_validation_contract"
    post_execution_validation_ready = False

summary = {
    "execution_result_intake_ready": intake_ready,
    "post_execution_validation_ready": post_execution_validation_ready,
    "post_execution_validation_completed": overall == "post_execution_validation_completed",
    "execute_requested": execute_requested,
    "validation_required": validation_required,
    "validation_commands_count": len(validation_commands),
    "validations_executed": validations_executed,
    "validation_failed": len([item for item in validation_results if int(item.get("exit_code", 0) or 0) != 0]),
    "commands_executed": commands_executed,
    "failed_commands": failed_commands,
    "runtime_started": bool(intake_summary.get("runtime_started")),
    "agents_started": int(intake_summary.get("agents_started", 0) or 0),
    "rollback_required": rollback_required,
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(intake_summary.get("paid_tokens_authorized", 0) or 0) if intake_ready else 0,
    "validation_checks": len(validation_checks),
    "validation_passed": sum(1 for item in validation_checks if item["status"] == "passed"),
    "validation_failed_checks": len(failed_checks),
    "validation_human_gate": len(human_gate_checks),
}

validation_package = {
    "ready_for_completion_handoff": overall == "post_execution_validation_completed",
    "ready_for_validation_execution": overall == "post_execution_validation_ready",
    "result_kind": result_package.get("result_kind", "unknown"),
    "runtime_commands": result_commands,
    "runtime_logs": result_logs,
    "validation_commands": validation_commands,
    "validation_results": validation_results,
    "rollback": {
        "required": rollback_required,
        "source": rollback,
    },
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-post-execution-validation-gate.sh",
    "mode": "agent_runtime_post_execution_validation_gate",
    "overall": overall,
    "reason": "Post-execution validation gate was evaluated from execution result intake evidence.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "execution_result_intake": str(result_intake_path),
    },
    "post_validation_state": post_validation_state,
    "next_action": next_action,
    "summary": summary,
    "execution_result_intake": {
        "overall": result_intake.get("overall"),
        "intake_state": result_intake.get("intake_state"),
        "next_action": result_intake.get("next_action"),
    },
    "validation_checks": validation_checks,
    "validation_package": validation_package,
    "validation_results": validation_results,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Post-Execution Validation Gate consumes only Execution Result Intake evidence.",
        "Plan-only, dry-run and Human Gate states cannot run post-execution validation.",
        "Validation commands execute only with --execute and a ready result intake.",
        "Failed runtime commands or validation commands require repair or rollback handoff.",
        "Remote writes, production and secrets remain blocked in this gate.",
    ],
    "next_cut": "TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony",
}

(artifact_root / "post-execution-validation-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME POST-EXECUTION VALIDATION GATE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Post-validation state: `{post_validation_state}`",
    f"- Next action: `{next_action}`",
    f"- Execution result intake ready: `{str(intake_ready).lower()}`",
    f"- Execute requested: `{str(execute_requested).lower()}`",
    f"- Post-execution validation ready: `{str(post_execution_validation_ready).lower()}`",
    f"- Validation commands: `{len(validation_commands)}`",
    f"- Validations executed: `{validations_executed}`",
    f"- Runtime commands executed: `{commands_executed}`",
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
    "# ARTEMIS AGENT RUNTIME POST-EXECUTION VALIDATION GATE VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Post-validation state: `{post_validation_state}`",
    f"- Intake ready: `{str(intake_ready).lower()}`",
    f"- Execute requested: `{str(execute_requested).lower()}`",
    f"- Validations executed: `{validations_executed}`",
    f"- Human Gate: `{summary['validation_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in validation_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

gate_lines = [
    "# ARTEMIS AGENT RUNTIME POST-EXECUTION VALIDATION GATE",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Post-validation state: `{post_validation_state}`",
    "",
    "## Comandos de validacao",
    "",
]
if validation_commands:
    for index, command in enumerate(validation_commands, 1):
        gate_lines.append(f"{index}. `{command}`")
else:
    gate_lines.append("- Nenhum comando de validacao pode rodar enquanto nao houver result intake pronto.")
gate_lines.extend(["", "## Resultados", ""])
if validation_results:
    for item in validation_results:
        gate_lines.append(f"- Step `{item['step']}` exit_code `{item['exit_code']}`.")
else:
    gate_lines.append("- Nenhuma validacao pos-execucao foi executada.")
(artifact_root / "POST_EXECUTION_VALIDATION_GATE.md").write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME POST-EXECUTION VALIDATION GATE HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-067 avaliou a validacao pos-execucao como `{overall}` com estado `{post_validation_state}`.",
    "",
    "## Proximo corte",
    "",
]
if overall == "post_execution_validation_completed":
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony` consolidando resultado, validacao, custo e rollback.")
else:
    handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony`, mantendo conclusao bloqueada ate existir validacao pos-execucao real.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao validar plan-only, dry-run ou Human Gate como execucao real.",
    "- Nao marcar Done sem `post_execution_validation_completed`.",
    "- Nao executar comandos de validacao sem `--execute` e result intake pronto.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

state_to = "done" if overall == "post_execution_validation_completed" else ("ready" if overall == "post_execution_validation_ready" else ("blocked" if overall == "failed" else "human_gate"))
severity = "info" if overall in {"post_execution_validation_ready", "post_execution_validation_completed"} else ("error" if overall == "failed" else "warning")
gate = {
    "kind": "validation" if overall in {"failed", "post_execution_validation_completed"} else "human",
    "status": "passed" if overall == "post_execution_validation_completed" else ("failed" if overall == "failed" else "human_gate"),
    "reason": "Post-execution validation result.",
}
validation_event = event(
    event_id="evt_tkt-067_agent_runtime_post_execution_validation_gate",
    event_type="validation.completed",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_post_execution_validation_gate", "name": "scripts/artemis-agent-runtime-post-execution-validation-gate.sh", "mode": "supervised" if execute_requested else "read_only"},
    ticket="TKT-067",
    title="Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-067-artemis-agent-runtime-post-execution-validation-gate.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to=state_to,
    severity=severity,
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "post_validation_state": post_validation_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": "none",
        "post_execution_validation": "agent_runtime_post_execution_validation_gate",
        "execute": execute_requested,
        "validations_executed": validations_executed,
        "commands_executed": commands_executed,
    },
    gate=gate,
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-post-execution-validation-gate.sh", generated_at=generated_at, events=[validation_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Post-Execution Validation Gate: {overall}")
    print(
        "summary: "
        f"post_validation_state={post_validation_state} "
        f"execute_requested={str(execute_requested).lower()} "
        f"validations_executed={validations_executed}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
