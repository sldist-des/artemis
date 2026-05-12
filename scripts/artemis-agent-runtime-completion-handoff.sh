#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-completion-handoff/run-01"
post_validation_gate_path="artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01/post-execution-validation-gate.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-completion-handoff.sh [--artifact-root path] [--post-validation-gate path] [--json]

Builds the ARTEMIS Agent Runtime Completion Handoff from the
Post-Execution Validation Gate. This script is read-only: it never starts
agents, runs commands, approves Human Gates, writes remotely, deploys, or
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
    --post-validation-gate)
      post_validation_gate_path="${2:-}"
      if [ -z "$post_validation_gate_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$post_validation_gate_path" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
post_validation_gate_path = Path(sys.argv[2])
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


post_gate = read_json(post_validation_gate_path)
post_summary = post_gate.get("summary") or {}
validation_package = post_gate.get("validation_package") or {}
runtime_commands = validation_package.get("runtime_commands") or {}
runtime_logs = validation_package.get("runtime_logs") or []
validation_commands = validation_package.get("validation_commands") or []
validation_results = validation_package.get("validation_results") or []
rollback = validation_package.get("rollback") or {}

post_completed = (
    post_gate.get("overall") == "post_execution_validation_completed"
    and post_summary.get("post_execution_validation_completed") is True
    and validation_package.get("ready_for_completion_handoff") is True
)
post_ready_plan_only = post_gate.get("overall") == "post_execution_validation_ready"
post_failed = post_gate.get("overall") == "failed"
rollback_required = rollback.get("required") is True or post_summary.get("rollback_required") is True
commands_executed = int(post_summary.get("commands_executed", 0) or 0)
failed_commands = int(post_summary.get("failed_commands", 0) or 0)
validations_executed = int(post_summary.get("validations_executed", 0) or 0)
remote_writes_allowed = post_summary.get("remote_writes_allowed") is True
production_allowed = post_summary.get("production_allowed") is True
secrets_allowed = post_summary.get("secrets_allowed") is True

ready_for_done = post_completed and not rollback_required and failed_commands == 0

if blockers:
    overall = "failed"
    handoff_state = "missing_post_execution_validation_gate"
    next_action = "restore_post_execution_validation_gate_artifact"
elif remote_writes_allowed or production_allowed or secrets_allowed:
    overall = "failed"
    handoff_state = "completion_handoff_contract_failed"
    next_action = "block_completion_and_review_remote_or_secret_scope"
elif ready_for_done:
    overall = "completion_handoff_ready"
    handoff_state = "ready_for_completion_review"
    next_action = "review_completion_handoff_and_mark_done_if_accepted"
elif post_completed and rollback_required:
    overall = "human_gate"
    handoff_state = "waiting_for_rollback_review"
    next_action = "review_rollback_before_completion"
elif post_failed:
    overall = "human_gate"
    handoff_state = "waiting_for_post_execution_repair_or_rollback"
    next_action = "repair_or_rollback_failed_post_execution_validation"
elif post_ready_plan_only:
    overall = "human_gate"
    handoff_state = "waiting_for_post_execution_validation_execute"
    next_action = "run_post_execution_validation_with_execute_after_approval"
else:
    overall = "human_gate"
    handoff_state = "waiting_for_post_execution_validation_completed"
    next_action = "wait_for_post_execution_validation_completed"

checks = [
    {
        "id": "post_execution_validation_gate_exists",
        "status": "passed" if post_validation_gate_path.is_file() else "failed",
        "proof": str(post_validation_gate_path),
    },
    {
        "id": "post_execution_validation_completed",
        "status": "passed" if post_completed else ("failed" if post_failed else "human_gate"),
        "proof": f"overall={post_gate.get('overall')} completed={post_summary.get('post_execution_validation_completed')}",
    },
    {
        "id": "completion_not_done_without_validation",
        "status": "passed" if (post_completed or not ready_for_done) else "failed",
        "proof": f"post_completed={str(post_completed).lower()} ready_for_done={str(ready_for_done).lower()}",
    },
    {
        "id": "runtime_result_classified",
        "status": "passed" if commands_executed >= 0 and failed_commands >= 0 else "failed",
        "proof": f"commands_executed={commands_executed} failed_commands={failed_commands}",
    },
    {
        "id": "validation_evidence_classified",
        "status": "passed" if validations_executed >= 0 else "failed",
        "proof": f"validations_executed={validations_executed} validation_results={len(validation_results)}",
    },
    {
        "id": "rollback_state_classified",
        "status": "human_gate" if rollback_required else "passed",
        "proof": f"rollback_required={str(rollback_required).lower()} rollback_keys={len(rollback)}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if not remote_writes_allowed and not production_allowed and not secrets_allowed else "failed",
        "proof": f"remote={str(remote_writes_allowed).lower()} production={str(production_allowed).lower()} secrets={str(secrets_allowed).lower()}",
    },
]
failed_checks = [item for item in checks if item["status"] == "failed"]
human_gate_checks = [item for item in checks if item["status"] == "human_gate"]
if failed_checks and overall != "failed":
    overall = "failed"
    handoff_state = "completion_handoff_contract_failed"
    next_action = "fix_completion_handoff_contract"
    ready_for_done = False

residual_risks = []
if not post_completed:
    residual_risks.append("post_execution_validation_not_completed")
if rollback_required:
    residual_risks.append("rollback_requires_human_review")
if failed_commands:
    residual_risks.append("runtime_commands_failed")
if not runtime_logs and commands_executed > 0:
    residual_risks.append("runtime_logs_missing")
if not residual_risks and ready_for_done:
    residual_risks.append("human_acceptance_still_required_before_external_close")

summary = {
    "post_execution_validation_completed": post_completed,
    "completion_handoff_ready": overall == "completion_handoff_ready",
    "ready_for_done": ready_for_done,
    "commands_executed": commands_executed,
    "failed_commands": failed_commands,
    "validations_executed": validations_executed,
    "validation_results": len(validation_results),
    "runtime_logs": len(runtime_logs),
    "rollback_required": rollback_required,
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(post_summary.get("paid_tokens_authorized", 0) or 0) if post_completed else 0,
    "handoff_checks": len(checks),
    "handoff_passed": sum(1 for item in checks if item["status"] == "passed"),
    "handoff_failed": len(failed_checks),
    "handoff_human_gate": len(human_gate_checks),
}

completion_package = {
    "ready_for_done": ready_for_done,
    "ready_for_human_acceptance": overall == "completion_handoff_ready",
    "result_kind": validation_package.get("result_kind", "unknown"),
    "runtime_commands": runtime_commands,
    "runtime_logs": runtime_logs,
    "validation_commands": validation_commands,
    "validation_results": validation_results,
    "rollback": rollback,
    "residual_risks": residual_risks,
    "evidence_artifacts": {
        "post_execution_validation_gate": str(post_validation_gate_path),
        "completion_handoff": f"{artifact_root}/COMPLETION_HANDOFF.md",
        "status": f"{artifact_root}/STATUS.md",
        "validation": f"{artifact_root}/VALIDATION.md",
        "handoff": f"{artifact_root}/HANDOFF.md",
    },
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-completion-handoff.sh",
    "mode": "agent_runtime_completion_handoff",
    "overall": overall,
    "reason": "Completion handoff was derived from post-execution validation evidence.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "post_execution_validation_gate": str(post_validation_gate_path),
    },
    "handoff_state": handoff_state,
    "next_action": next_action,
    "summary": summary,
    "post_execution_validation_gate": {
        "overall": post_gate.get("overall"),
        "post_validation_state": post_gate.get("post_validation_state"),
        "next_action": post_gate.get("next_action"),
    },
    "handoff_checks": checks,
    "completion_package": completion_package,
    "human_summary": {
        "status": overall,
        "plain_language": (
            "A tarefa tem validacao pos-execucao suficiente para revisao final."
            if ready_for_done
            else "A tarefa ainda nao pode ser concluida porque falta validacao pos-execucao real."
        ),
        "operator_next_step": next_action,
    },
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Completion Handoff consumes only Post-Execution Validation Gate evidence.",
        "No Done state is allowed without post_execution_validation_completed=true.",
        "Failed commands or rollback requirements stay visible to the human operator.",
        "Remote writes, production and secrets remain blocked in this handoff.",
        "The handoff explains status for both agents and non-technical humans.",
    ],
    "next_cut": "TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony",
}

(artifact_root / "completion-handoff.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION HANDOFF STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Handoff state: `{handoff_state}`",
    f"- Next action: `{next_action}`",
    f"- Post-execution validation completed: `{str(post_completed).lower()}`",
    f"- Completion handoff ready: `{str(summary['completion_handoff_ready']).lower()}`",
    f"- Ready for Done: `{str(ready_for_done).lower()}`",
    f"- Runtime commands executed: `{commands_executed}`",
    f"- Validations executed: `{validations_executed}`",
    f"- Rollback required: `{str(rollback_required).lower()}`",
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
    "# ARTEMIS AGENT RUNTIME COMPLETION HANDOFF VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Handoff state: `{handoff_state}`",
    f"- Human Gate: `{summary['handoff_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_report_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION HANDOFF",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Handoff state: `{handoff_state}`",
    f"- Ready for Done: `{str(ready_for_done).lower()}`",
    "",
    "## Evidencia consolidada",
    "",
    f"- Runtime commands executed: `{commands_executed}`",
    f"- Failed commands: `{failed_commands}`",
    f"- Runtime logs: `{len(runtime_logs)}`",
    f"- Validations executed: `{validations_executed}`",
    f"- Validation results: `{len(validation_results)}`",
    f"- Rollback required: `{str(rollback_required).lower()}`",
    "",
    "## Riscos residuais",
    "",
]
for risk in residual_risks:
    handoff_report_lines.append(f"- `{risk}`")
(artifact_root / "COMPLETION_HANDOFF.md").write_text("\n".join(handoff_report_lines) + "\n", encoding="utf-8")

next_handoff_lines = [
    "# ARTEMIS AGENT RUNTIME COMPLETION HANDOFF HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-068 avaliou o handoff de conclusao como `{overall}` com estado `{handoff_state}`.",
    "",
    "## Proximo corte",
    "",
]
if ready_for_done:
    next_handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony` para revisao humana final antes de Done externo.")
else:
    next_handoff_lines.append("- Implementar `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony`, mantendo revisao bloqueada ate existir handoff pronto.")
next_handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao marcar Done sem `post_execution_validation_completed`.",
    "- Nao esconder rollback, falhas de comando ou riscos residuais.",
    "- Nao executar comandos ou aprovar Human Gate a partir deste handoff.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(next_handoff_lines) + "\n", encoding="utf-8")

state_to = "handoff" if overall == "completion_handoff_ready" else ("blocked" if overall == "failed" else "human_gate")
gate = {
    "kind": "validation" if overall == "completion_handoff_ready" else ("policy" if overall == "failed" else "human"),
    "status": "passed" if overall == "completion_handoff_ready" else ("failed" if overall == "failed" else "human_gate"),
    "reason": "Completion handoff result.",
}
handoff_event = event(
    event_id="evt_tkt-068_agent_runtime_completion_handoff",
    event_type="handoff.recorded",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_completion_handoff", "name": "scripts/artemis-agent-runtime-completion-handoff.sh", "mode": "read_only"},
    ticket="TKT-068",
    title="Agent Runtime Completion Handoff do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-068-artemis-agent-runtime-completion-handoff.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to=state_to,
    severity="info" if overall == "completion_handoff_ready" else ("error" if overall == "failed" else "warning"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "handoff_state": handoff_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={"kind": "none"},
    gate=gate,
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-completion-handoff.sh", generated_at=generated_at, events=[handoff_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Completion Handoff: {overall}")
    print(
        "summary: "
        f"handoff_state={handoff_state} "
        f"ready_for_done={str(ready_for_done).lower()} "
        f"validations_executed={validations_executed}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
