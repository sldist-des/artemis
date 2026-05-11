#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01"
execution_gate_path="artifacts/artemis-agent-runtime-launcher-execution-gate/run-01/launcher-execution-gate.json"
format="text"
execute="false"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-launcher-supervised-execution.sh [--artifact-root path] [--execution-gate path] [--execute] [--json]

Builds the ARTEMIS Agent Runtime Launcher Supervised Execution record from a
Launcher Execution Gate. By default this is plan-only. With --execute it can
run only after launcher_execution_gate_ready and exact local safety checks.
It never writes remotely, touches secrets, deploys, or changes production.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --execution-gate)
      execution_gate_path="${2:-}"
      if [ -z "$execution_gate_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$execution_gate_path" "$execute" "$format" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
execution_gate_path = Path(sys.argv[2])
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
    return subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, check=False)


def current_git_context():
    branch = run(["git", "branch", "--show-current"])
    status = run(["git", "status", "--porcelain"])
    rev = run(["git", "rev-parse", "--short", "HEAD"])
    return {
        "branch": branch.stdout.strip() if branch.returncode == 0 else "",
        "dirty": bool(status.stdout.strip()) if status.returncode == 0 else True,
        "status_porcelain": status.stdout.splitlines() if status.returncode == 0 else [],
        "head": rev.stdout.strip() if rev.returncode == 0 else "",
    }


execution_gate = read_json(execution_gate_path)
gate_summary = execution_gate.get("summary") or {}
execution_package = execution_gate.get("execution_package") or {}
approved_commands = list(execution_package.get("approved_commands") or [])
budget = execution_package.get("budget") or {}
validation = execution_package.get("validation") or {}
rollback = execution_package.get("rollback") or {}
workspace = execution_package.get("workspace") or {}
git_context = current_git_context()

gate_ready = (
    execution_gate.get("overall") == "launcher_execution_gate_ready"
    and execution_gate.get("gate_state") == "execution_gate_ready"
    and gate_summary.get("execution_gate_ready") is True
    and gate_summary.get("launcher_execution_allowed") is True
    and gate_summary.get("runtime_execution_allowed") is True
    and execution_package.get("eligible") is True
)

supervision_checks = [
    {
        "id": "launcher_execution_gate_exists",
        "status": "passed" if execution_gate_path.is_file() else "failed",
        "proof": str(execution_gate_path),
    },
    {
        "id": "launcher_execution_gate_ready",
        "status": "passed" if gate_ready else "human_gate",
        "proof": f"overall={execution_gate.get('overall')} gate_state={execution_gate.get('gate_state')}",
    },
    {
        "id": "upstream_commands_not_executed",
        "status": "passed" if int(gate_summary.get("commands_executed", -1) or 0) == 0 else "failed",
        "proof": f"commands_executed={gate_summary.get('commands_executed')}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if gate_summary.get("remote_writes_allowed") is False else "failed",
        "proof": f"remote_writes_allowed={gate_summary.get('remote_writes_allowed')}",
    },
    {
        "id": "production_blocked",
        "status": "passed" if gate_summary.get("production_allowed") is False else "failed",
        "proof": f"production_allowed={gate_summary.get('production_allowed')}",
    },
    {
        "id": "secrets_blocked",
        "status": "passed" if gate_summary.get("secrets_allowed") is False else "failed",
        "proof": f"secrets_allowed={gate_summary.get('secrets_allowed')}",
    },
]

if gate_ready:
    if not approved_commands:
        blockers.append("execution_package.approved_commands is required")
    if workspace.get("repo") != str(Path.cwd()):
        blockers.append("execution_package.workspace.repo must match current repository")
    if validation.get("required_before_done") is not True:
        blockers.append("execution_package.validation.required_before_done must be true")
    if rollback.get("required_before_runtime") is not True:
        blockers.append("execution_package.rollback.required_before_runtime must be true")
    if rollback.get("preserve_logs") is not True:
        blockers.append("execution_package.rollback.preserve_logs must be true")
    if int(budget.get("max_commands", 0) or 0) < len(approved_commands):
        blockers.append("budget.max_commands must cover approved command count")
    if int(budget.get("max_runtime_seconds", 0) or 0) <= 0:
        blockers.append("budget.max_runtime_seconds must be positive")

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
if gate_ready:
    for command in approved_commands:
        if not isinstance(command, str) or not command.strip():
            blockers.append("approved commands cannot be empty")
            continue
        for pattern in blocked_patterns:
            if re.search(pattern, command):
                blockers.append(f"approved command is blocked in supervised execution: {command}")
                break

failed_checks = [item for item in supervision_checks if item["status"] == "failed"]
human_gate_checks = [item for item in supervision_checks if item["status"] == "human_gate"]
can_execute = gate_ready and execute_requested and not blockers and not failed_checks
ready_plan_only = gate_ready and not execute_requested and not blockers and not failed_checks

command_results = []
if can_execute:
    for index, command in enumerate(approved_commands, 1):
        result = subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, shell=True, check=False)
        command_results.append({
            "step": index,
            "command": command,
            "exit_code": result.returncode,
            "stdout_path": f"{artifact_root}/command-{index:02d}.stdout.txt",
            "stderr_path": f"{artifact_root}/command-{index:02d}.stderr.txt",
        })
        (artifact_root / f"command-{index:02d}.stdout.txt").write_text(result.stdout, encoding="utf-8")
        (artifact_root / f"command-{index:02d}.stderr.txt").write_text(result.stderr, encoding="utf-8")
        if result.returncode != 0:
            blockers.append(f"approved command failed at step {index}: exit_code={result.returncode}")
            break

if can_execute and not blockers:
    overall = "supervised_execution_completed"
    execution_state = "completed"
    next_action = "collect_runtime_result_intake"
elif ready_plan_only:
    overall = "supervised_execution_ready"
    execution_state = "ready_execute_false"
    next_action = "rerun_with_execute_after_final_human_confirmation"
elif failed_checks or blockers:
    overall = "failed"
    execution_state = "blocked"
    next_action = "fix_supervised_execution_blockers"
else:
    overall = "human_gate"
    execution_state = "waiting_for_launcher_execution_gate_ready"
    next_action = "wait_for_launcher_execution_gate_ready"

commands_executed = len(command_results)
summary = {
    "launcher_execution_gate_ready": gate_ready,
    "execute_requested": execute_requested,
    "supervised_execution_ready": ready_plan_only or can_execute,
    "supervised_execution_completed": overall == "supervised_execution_completed",
    "supervision_checks": len(supervision_checks),
    "supervision_passed": sum(1 for item in supervision_checks if item["status"] == "passed"),
    "supervision_failed": len(failed_checks),
    "supervision_human_gate": len(human_gate_checks),
    "approved_commands_count": len(approved_commands) if gate_ready else 0,
    "commands_executed": commands_executed,
    "runtime_started": can_execute,
    "agents_started": 1 if can_execute and approved_commands else 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(budget.get("max_paid_tokens", 0) or 0) if (ready_plan_only or can_execute) else 0,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-launcher-supervised-execution.sh",
    "mode": "agent_runtime_launcher_supervised_execution",
    "overall": overall,
    "reason": "Supervised launcher execution was evaluated with ARTEMIS gates and evidence.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "launcher_execution_gate": str(execution_gate_path),
    },
    "execution_state": execution_state,
    "next_action": next_action,
    "summary": summary,
    "launcher_execution_gate": {
        "overall": execution_gate.get("overall"),
        "gate_state": execution_gate.get("gate_state"),
        "next_action": execution_gate.get("next_action"),
    },
    "git_context": git_context,
    "supervision_checks": supervision_checks,
    "execution_plan": {
        "eligible": ready_plan_only or can_execute,
        "execute": execute_requested,
        "runtime": execution_package.get("runtime") if gate_ready else "",
        "profile_id": execution_package.get("profile_id") if gate_ready else "",
        "command_surface": execution_package.get("command_surface") if gate_ready else "",
        "approved_commands": approved_commands if gate_ready else [],
        "budget": budget if gate_ready else {},
        "validation": validation if gate_ready else {},
        "rollback": rollback if gate_ready else {},
    },
    "command_results": command_results,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Supervised Execution consumes only launcher_execution_gate_ready artifacts.",
        "Default mode is plan-only; --execute is required even after Human Gate approval.",
        "Remote writes, production and secrets remain blocked in this runner.",
        "Validation evidence and logs must be preserved before Done.",
        "Failed commands stop the execution sequence and require handoff.",
    ],
    "next_cut": "TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony",
}

(artifact_root / "launcher-supervised-execution.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER SUPERVISED EXECUTION STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Execution state: `{execution_state}`",
    f"- Next action: `{next_action}`",
    f"- Launcher execution gate ready: `{str(gate_ready).lower()}`",
    f"- Execute requested: `{str(execute_requested).lower()}`",
    f"- Runtime started: `{str(summary['runtime_started']).lower()}`",
    f"- Agents started: `{summary['agents_started']}`",
    f"- Commands executed: `{summary['commands_executed']}`",
    f"- Remote writes allowed: `false`",
    f"- Production allowed: `false`",
    f"- Secrets allowed: `false`",
    f"- Paid tokens authorized: `{summary['paid_tokens_authorized']}`",
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
    "# ARTEMIS AGENT RUNTIME LAUNCHER SUPERVISED EXECUTION VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Launcher execution gate ready: `{str(gate_ready).lower()}`",
    f"- Execute requested: `{str(execute_requested).lower()}`",
    f"- Commands executed: `{summary['commands_executed']}`",
    f"- Failed: `{summary['supervision_failed']}`",
    f"- Human Gate: `{summary['supervision_human_gate']}`",
    "",
    "## Checks",
    "",
]
for item in supervision_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

execution_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER SUPERVISED EXECUTION",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Execution state: `{execution_state}`",
    f"- Execute requested: `{str(execute_requested).lower()}`",
    "",
    "## Comandos",
    "",
]
if approved_commands and gate_ready:
    for index, command in enumerate(approved_commands, 1):
        execution_lines.append(f"{index}. `{command}`")
else:
    execution_lines.append("- Nenhum comando executavel enquanto o gate nao estiver `launcher_execution_gate_ready`.")
execution_lines.extend([
    "",
    "## Resultados",
    "",
])
if command_results:
    for result in command_results:
        execution_lines.append(f"- Step `{result['step']}` exit_code `{result['exit_code']}`.")
else:
    execution_lines.append("- Nenhum comando foi executado.")
(artifact_root / "SUPERVISED_EXECUTION.md").write_text("\n".join(execution_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER SUPERVISED EXECUTION HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-065 avaliou a execucao supervisionada como `{overall}` com estado `{execution_state}`.",
    "",
    "## Proximo corte",
    "",
]
if overall == "supervised_execution_completed":
    handoff_lines.append("- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony` lendo logs e resultados desta execucao.")
else:
    handoff_lines.append("- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony`, mantendo execucao bloqueada ate existir resultado supervisionado.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao bypassar Launcher Execution Gate.",
    "- Nao executar comandos sem `--execute` e gate pronto.",
    "- Nao tocar remoto, secrets, deploy, PR, push ou producao.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

execution_event = event(
    event_id="evt_tkt-065_agent_runtime_launcher_supervised_execution",
    event_type="runner.attempt_completed" if overall == "supervised_execution_completed" else "runner.attempt_planned",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_launcher_supervised_execution", "name": "scripts/artemis-agent-runtime-launcher-supervised-execution.sh", "mode": "supervised" if execute_requested else "read_only"},
    ticket="TKT-065",
    title="Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-065-artemis-agent-runtime-launcher-supervised-execution.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to="done" if overall == "supervised_execution_completed" else ("ready" if overall == "supervised_execution_ready" else ("human_gate" if overall == "human_gate" else "blocked")),
    severity="info" if overall in {"supervised_execution_ready", "supervised_execution_completed"} else ("warning" if overall == "human_gate" else "error"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "execution_state": execution_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": "agent_runtime_launcher_supervised_execution",
        "execute": execute_requested,
        "commands_planned": len(approved_commands) if gate_ready else 0,
        "commands_executed": commands_executed,
    },
    gate={
        "kind": "human" if overall == "human_gate" else "none",
        "status": "human_gate" if overall == "human_gate" else "not_applicable",
        "reason": "Launcher execution gate remains required before supervised execution.",
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-launcher-supervised-execution.sh", generated_at=generated_at, events=[execution_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Launcher Supervised Execution: {overall}")
    print(
        "summary: "
        f"execution_state={execution_state} "
        f"execute_requested={str(execute_requested).lower()} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
