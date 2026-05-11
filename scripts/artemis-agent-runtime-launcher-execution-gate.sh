#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-launcher-execution-gate/run-01"
command_plan_path="artifacts/artemis-agent-runtime-launcher-command-plan/run-01/launcher-command-plan.json"
decision_path=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-launcher-execution-gate.sh [--artifact-root path] [--command-plan path] [--decision path] [--json]

Builds the ARTEMIS Agent Runtime Launcher Execution Gate from a Launcher
Command Plan. This gate can authorize a future supervised launcher only after
an exact human decision and a ready command plan. It never executes commands,
starts Codex, starts Claude Code, spends paid tokens, touches secrets, writes
remotely, deploys, or changes production.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --command-plan)
      command_plan_path="${2:-}"
      if [ -z "$command_plan_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$command_plan_path" "$decision_path" "$format" <<'PY'
import hashlib
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
command_plan_path = Path(sys.argv[2])
provided_decision_path = sys.argv[3]
output_format = sys.argv[4]
generated_at = now_utc()
decision_path = Path(provided_decision_path) if provided_decision_path else artifact_root / "launcher-execution-decision.json"
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


def nonempty_string(value):
    return isinstance(value, str) and bool(value.strip())


def valid_timestamp(value):
    if not value:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


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


def sha256_file(path):
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except FileNotFoundError:
        return ""


command_plan_payload = read_json(command_plan_path)
summary_in = command_plan_payload.get("summary") or {}
command_plan = command_plan_payload.get("command_plan") or {}
steps = list(command_plan.get("steps") or [])
step_commands = [step.get("command", "") for step in steps]
budget = command_plan.get("budget") or {}
workspace = command_plan.get("workspace") or {}
validation = command_plan.get("validation") or {}
rollback = command_plan.get("rollback") or {}
git_context = current_git_context()
command_plan_hash = sha256_file(command_plan_path)

command_plan_ready = (
    command_plan_payload.get("overall") == "launcher_command_plan_ready"
    and command_plan_payload.get("plan_state") == "command_plan_ready"
    and summary_in.get("command_plan_ready") is True
    and command_plan.get("eligible") is True
)

default_decision = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-launcher-execution-gate.sh",
    "mode": "human_fillable_pending",
    "based_on": str(command_plan_path),
    "command_plan_sha256": command_plan_hash,
    "decision_record": {
        "decision": "pending",
        "decided_by": "",
        "decided_at": "",
        "reason": "",
        "execute": False,
        "command_plan_sha256": command_plan_hash,
        "approved_runtime": "",
        "approved_profile_id": "",
        "approved_command_surface": "",
        "approved_commands": [],
        "budget_approved": False,
        "logs_approved": False,
        "rollback_approved": False,
        "validation_approved": False,
        "remote_writes_allowed": False,
        "production_allowed": False,
        "secrets_allowed": False,
    },
    "approval_options": {
        "pending": "Decision is still open; launcher execution stays blocked.",
        "approved": "Requires exact command plan hash, commands, budget, logs, rollback and validation approval.",
        "deferred": "Keeps launcher execution blocked for later review.",
        "rejected": "Refuses this launcher execution request while preserving evidence.",
    },
    "invariants": [
        "This file is a human-fillable launcher execution decision, not execution.",
        "Generated decisions start as pending and execute=false.",
        "Agents must not approve launcher execution on behalf of humans.",
        "Remote writes, production and secrets remain blocked unless separately approved.",
    ],
}

if provided_decision_path and decision_path.is_file():
    decision_payload = read_json(decision_path)
else:
    decision_payload = default_decision
    decision_path.write_text(json.dumps(decision_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

record = decision_payload.get("decision_record") or {}
decision = str(record.get("decision") or "pending").strip()
approved_commands = list(record.get("approved_commands") or [])
decision_blockers = []

gate_checks = [
    {
        "id": "launcher_command_plan_exists",
        "status": "passed" if command_plan_path.is_file() else "failed",
        "proof": str(command_plan_path),
    },
    {
        "id": "launcher_command_plan_ready",
        "status": "passed" if command_plan_ready else "human_gate",
        "proof": f"overall={command_plan_payload.get('overall')} plan_state={command_plan_payload.get('plan_state')}",
    },
    {
        "id": "command_plan_did_not_execute",
        "status": "passed" if int(summary_in.get("commands_executed", -1) or 0) == 0 else "failed",
        "proof": f"commands_executed={summary_in.get('commands_executed')}",
    },
    {
        "id": "command_plan_kept_launcher_blocked",
        "status": "passed" if summary_in.get("launcher_execution_allowed") is False else "failed",
        "proof": f"launcher_execution_allowed={summary_in.get('launcher_execution_allowed')}",
    },
    {
        "id": "runtime_still_not_started",
        "status": "passed" if summary_in.get("runtime_started") is False else "failed",
        "proof": f"runtime_started={summary_in.get('runtime_started')}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if summary_in.get("remote_writes_allowed") is False else "failed",
        "proof": f"remote_writes_allowed={summary_in.get('remote_writes_allowed')}",
    },
    {
        "id": "execution_decision_exists",
        "status": "passed" if decision_path.is_file() else "failed",
        "proof": str(decision_path),
    },
]

if decision not in {"pending", "approved", "deferred", "rejected"}:
    decision_blockers.append("decision must be one of: pending, approved, deferred, rejected")

if decision in {"approved", "deferred", "rejected"}:
    for field in ["decided_by", "decided_at", "reason"]:
        if not nonempty_string(record.get(field)):
            decision_blockers.append(f"{field} is required for {decision}")
    if not valid_timestamp(str(record.get("decided_at") or "")):
        decision_blockers.append("decided_at must be ISO-8601")

if command_plan_ready:
    if not steps:
        blockers.append("command_plan.steps must include exact commands before execution gate can be approved")
    if any(step.get("execute") is not False for step in steps):
        blockers.append("command_plan.steps must keep execute=false")
    if not nonempty_string(command_plan.get("runtime")):
        blockers.append("command_plan.runtime is required")
    if not nonempty_string(command_plan.get("profile_id")):
        blockers.append("command_plan.profile_id is required")
    if not nonempty_string(command_plan.get("command_surface")):
        blockers.append("command_plan.command_surface is required")
    if workspace.get("repo") != str(Path.cwd()):
        blockers.append("command_plan.workspace.repo must match current repository")
    if validation.get("required_before_done") is not True:
        blockers.append("command_plan.validation.required_before_done must be true")
    if rollback.get("required_before_runtime") is not True:
        blockers.append("command_plan.rollback.required_before_runtime must be true")
    if int(budget.get("max_paid_tokens", 0) or 0) <= 0:
        blockers.append("command_plan.budget.max_paid_tokens must be positive before approval")
    if int(budget.get("max_runtime_seconds", 0) or 0) <= 0:
        blockers.append("command_plan.budget.max_runtime_seconds must be positive before approval")

    if decision == "approved":
        if record.get("execute") is not True:
            decision_blockers.append("approved launcher execution requires execute=true in the human decision")
        if str(record.get("command_plan_sha256") or "") != command_plan_hash:
            decision_blockers.append("approved launcher execution requires matching command_plan_sha256")
        if approved_commands != step_commands:
            decision_blockers.append("approved_commands must exactly match command_plan steps")
        if record.get("approved_runtime") != command_plan.get("runtime"):
            decision_blockers.append("approved_runtime must match command_plan.runtime")
        if record.get("approved_profile_id") != command_plan.get("profile_id"):
            decision_blockers.append("approved_profile_id must match command_plan.profile_id")
        if record.get("approved_command_surface") != command_plan.get("command_surface"):
            decision_blockers.append("approved_command_surface must match command_plan.command_surface")
        for flag in ["budget_approved", "logs_approved", "rollback_approved", "validation_approved"]:
            if record.get(flag) is not True:
                decision_blockers.append(f"{flag} must be true for approved launcher execution")
        for flag in ["remote_writes_allowed", "production_allowed", "secrets_allowed"]:
            if record.get(flag) is not False:
                decision_blockers.append(f"{flag} must remain false in this gate")
    elif approved_commands:
        decision_blockers.append("pending, deferred and rejected decisions must not include approved_commands")

failed_checks = [item for item in gate_checks if item["status"] == "failed"]
human_gate_checks = [item for item in gate_checks if item["status"] == "human_gate"]
gate_ready = command_plan_ready and decision == "approved" and not blockers and not decision_blockers and not failed_checks

if gate_ready:
    overall = "launcher_execution_gate_ready"
    gate_state = "execution_gate_ready"
    next_action = "eligible_for_supervised_launcher_execution_runner"
elif failed_checks or blockers or decision_blockers:
    overall = "failed"
    gate_state = "blocked"
    next_action = "fix_launcher_execution_gate_blockers"
elif command_plan_ready:
    overall = "human_gate"
    gate_state = "waiting_for_execution_approval"
    next_action = "wait_for_exact_launcher_execution_decision"
else:
    overall = "human_gate"
    gate_state = "waiting_for_launcher_command_plan_ready"
    next_action = "wait_for_launcher_command_plan_ready"

summary = {
    "launcher_command_plan_ready": command_plan_ready,
    "execution_gate_ready": gate_ready,
    "decision": decision,
    "gate_checks": len(gate_checks),
    "gate_passed": sum(1 for item in gate_checks if item["status"] == "passed"),
    "gate_failed": len(failed_checks),
    "gate_human_gate": len(human_gate_checks) + (1 if command_plan_ready and decision == "pending" else 0),
    "planned_commands_count": len(steps) if command_plan_ready else 0,
    "approved_commands_count": len(approved_commands) if gate_ready else 0,
    "launcher_execution_allowed": gate_ready,
    "runtime_execution_allowed": gate_ready,
    "runtime_started": False,
    "agents_started": 0,
    "commands_executed": 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "production_allowed": False,
    "secrets_allowed": False,
    "paid_tokens_authorized": int(budget.get("max_paid_tokens", 0) or 0) if gate_ready else 0,
}

execution_package = {
    "kind": "future_supervised_launcher_execution_runner_input",
    "eligible": gate_ready,
    "execute_in_this_script": False,
    "runtime": command_plan.get("runtime") if gate_ready else "",
    "profile_id": command_plan.get("profile_id") if gate_ready else "",
    "command_surface": command_plan.get("command_surface") if gate_ready else "",
    "command_plan_sha256": command_plan_hash if gate_ready else "",
    "approved_commands": approved_commands if gate_ready else [],
    "budget": budget if gate_ready else {},
    "workspace": workspace if gate_ready else {},
    "validation": validation if gate_ready else {},
    "rollback": rollback if gate_ready else {},
    "logs": {
        "execution_gate": f"{artifact_root}/EXECUTION_GATE.md",
        "status": f"{artifact_root}/STATUS.md",
        "validation": f"{artifact_root}/VALIDATION.md",
        "handoff": f"{artifact_root}/HANDOFF.md",
    },
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-launcher-execution-gate.sh",
    "mode": "agent_runtime_launcher_execution_gate",
    "overall": overall,
    "reason": "Launcher execution gate was evaluated without executing commands or starting runtime.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "launcher_command_plan": str(command_plan_path),
        "decision": str(decision_path),
    },
    "gate_state": gate_state,
    "next_action": next_action,
    "summary": summary,
    "launcher_command_plan": {
        "overall": command_plan_payload.get("overall"),
        "plan_state": command_plan_payload.get("plan_state"),
        "next_action": command_plan_payload.get("next_action"),
        "sha256": command_plan_hash,
    },
    "decision_file": str(decision_path),
    "git_context": git_context,
    "gate_checks": gate_checks,
    "execution_package": execution_package,
    "blockers": blockers + decision_blockers,
    "warnings": warnings,
    "invariants": [
        "Execution Gate never executes commands by itself.",
        "launcher_execution_gate_ready means eligible for a future supervised runner, not execution in this script.",
        "Remote writes, production and secrets remain blocked in this gate.",
        "Paid tokens are authorized only when command plan and exact human decision are both ready.",
        "Future execution runners must preserve logs and re-run Validation Gate before Done.",
    ],
    "next_cut": "TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony",
}

(artifact_root / "launcher-execution-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER EXECUTION GATE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Gate state: `{gate_state}`",
    f"- Next action: `{next_action}`",
    f"- Launcher command plan ready: `{str(command_plan_ready).lower()}`",
    f"- Decision: `{decision}`",
    f"- Execution gate ready: `{str(gate_ready).lower()}`",
    f"- Launcher execution allowed: `{str(summary['launcher_execution_allowed']).lower()}`",
    f"- Runtime execution allowed: `{str(summary['runtime_execution_allowed']).lower()}`",
    f"- Runtime started: `false`",
    f"- Agents started: `0`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
    f"- Production allowed: `false`",
    f"- Secrets allowed: `false`",
    f"- Paid tokens authorized: `{summary['paid_tokens_authorized']}`",
    "",
    "## Blockers",
    "",
]
if payload["blockers"]:
    status_lines.extend(f"- {blocker}" for blocker in payload["blockers"])
else:
    status_lines.append("- Nenhum blocker tecnico local.")
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER EXECUTION GATE VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Launcher command plan ready: `{str(command_plan_ready).lower()}`",
    f"- Decision: `{decision}`",
    f"- Execution gate ready: `{str(gate_ready).lower()}`",
    f"- Gate checks: `{len(gate_checks)}`",
    f"- Passed: `{summary['gate_passed']}`",
    f"- Failed: `{summary['gate_failed']}`",
    f"- Human Gate: `{summary['gate_human_gate']}`",
    f"- Launcher execution allowed: `{str(summary['launcher_execution_allowed']).lower()}`",
    f"- Runtime execution allowed: `{str(summary['runtime_execution_allowed']).lower()}`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
    "",
    "## Checks",
    "",
]
for item in gate_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

gate_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER EXECUTION GATE",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Gate state: `{gate_state}`",
    f"- Eligible for supervised launcher runner: `{str(gate_ready).lower()}`",
    f"- Command plan hash: `{command_plan_hash}`",
    "",
    "## Decisao humana requerida",
    "",
    "- `decision=approved`",
    "- `execute=true`",
    "- `command_plan_sha256` precisa bater com o plano atual",
    "- `approved_commands` precisa bater exatamente com os steps do plano",
    "- `budget_approved=true`",
    "- `logs_approved=true`",
    "- `rollback_approved=true`",
    "- `validation_approved=true`",
    "- `remote_writes_allowed=false`",
    "- `production_allowed=false`",
    "- `secrets_allowed=false`",
    "",
    "## Comandos aprovaveis",
    "",
]
if step_commands and command_plan_ready:
    for index, command in enumerate(step_commands, 1):
        gate_lines.append(f"{index}. `{command}`")
else:
    gate_lines.append("- Nenhum comando aprovavel enquanto o Command Plan nao estiver `launcher_command_plan_ready`.")
gate_lines.extend([
    "",
    "## Limites",
    "",
    "- Este gate nao executa comando.",
    "- Este gate nao inicia runtime.",
    "- Este gate nao autoriza escrita remota, secrets, deploy ou producao.",
])
(artifact_root / "EXECUTION_GATE.md").write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER EXECUTION GATE HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-064 avaliou o gate de execucao como `{overall}` com estado `{gate_state}`.",
    "",
    "## Proximo corte",
    "",
]
if gate_ready:
    handoff_lines.append("- Implementar `TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony` consumindo este gate.")
else:
    handoff_lines.append("- Implementar `TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony`, mantendo execucao bloqueada ate existir `launcher_execution_gate_ready`.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao iniciar Codex app-server, Claude Code, SDK, CLI, subagente, fila ou daemon neste gate.",
    "- Nao executar comandos planejados neste gate.",
    "- Nao tocar secrets, producao, deploy, push ou PR.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

gate_event = event(
    event_id="evt_tkt-064_agent_runtime_launcher_execution_gate",
    event_type="approval.requested",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_launcher_execution_gate", "name": "scripts/artemis-agent-runtime-launcher-execution-gate.sh", "mode": "read_only"},
    ticket="TKT-064",
    title="Agent Runtime Launcher Execution Gate do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-064-artemis-agent-runtime-launcher-execution-gate.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to="ready" if gate_ready else ("human_gate" if overall == "human_gate" else "blocked"),
    severity="info" if gate_ready else ("warning" if overall == "human_gate" else "error"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "gate_state": gate_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": "agent_runtime_launcher_execution_gate",
        "execute": False,
        "commands_planned": len(step_commands) if command_plan_ready else 0,
        "commands_executed": 0,
    },
    gate={
        "kind": "human",
        "status": "resolved" if gate_ready else "human_gate",
        "reason": "Exact human launcher execution decision is required before supervised runtime.",
        "options": ["approved", "deferred", "rejected"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-launcher-execution-gate.sh", generated_at=generated_at, events=[gate_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Launcher Execution Gate: {overall}")
    print(
        "summary: "
        f"gate_state={gate_state} "
        f"execution_gate_ready={str(summary['execution_gate_ready']).lower()} "
        f"launcher_execution_allowed={str(summary['launcher_execution_allowed']).lower()} "
        "commands_executed=0"
    )

if overall == "failed":
    raise SystemExit(1)
PY
