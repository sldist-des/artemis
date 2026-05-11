#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-launcher-command-plan/run-01"
launcher_preflight_path="artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-launcher-command-plan.sh [--artifact-root path] [--launcher-preflight path] [--json]

Builds the ARTEMIS Agent Runtime Launcher Command Plan from a Launcher
Preflight artifact. This is read-only: it materializes an auditable command
plan only when preflight is ready, but it never executes commands, starts
agent runtimes, spends paid tokens, touches secrets, writes remotely, deploys
or changes production.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --launcher-preflight)
      launcher_preflight_path="${2:-}"
      if [ -z "$launcher_preflight_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$launcher_preflight_path" "$format" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
launcher_preflight_path = Path(sys.argv[2])
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


def run(command):
    return subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, check=False)


def nonempty_string(value):
    return isinstance(value, str) and bool(value.strip())


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


launcher_preflight = read_json(launcher_preflight_path)
preflight_summary = launcher_preflight.get("summary") or {}
launcher_package = launcher_preflight.get("launcher_package") or {}
approved_commands = list(launcher_package.get("approved_commands") or [])
budget = launcher_package.get("budget") or {}
workspace = launcher_package.get("workspace") or {}
validation = launcher_package.get("validation") or {}
rollback = launcher_package.get("rollback") or {}
git_context = current_git_context()

preflight_ready = (
    launcher_preflight.get("overall") == "launcher_preflight_ready"
    and launcher_preflight.get("preflight_state") == "preflight_ready"
    and preflight_summary.get("launcher_preflight_allowed") is True
    and launcher_package.get("eligible") is True
)

plan_checks = [
    {
        "id": "launcher_preflight_exists",
        "status": "passed" if launcher_preflight_path.is_file() else "failed",
        "proof": str(launcher_preflight_path),
    },
    {
        "id": "launcher_preflight_ready",
        "status": "passed" if preflight_ready else "human_gate",
        "proof": f"overall={launcher_preflight.get('overall')} preflight_state={launcher_preflight.get('preflight_state')}",
    },
    {
        "id": "launcher_execution_still_blocked",
        "status": "passed" if preflight_summary.get("launcher_execution_allowed") is False else "failed",
        "proof": f"launcher_execution_allowed={preflight_summary.get('launcher_execution_allowed')}",
    },
    {
        "id": "runtime_execution_still_blocked",
        "status": "passed" if preflight_summary.get("runtime_execution_allowed") is False else "failed",
        "proof": f"runtime_execution_allowed={preflight_summary.get('runtime_execution_allowed')}",
    },
    {
        "id": "commands_not_executed",
        "status": "passed" if int(preflight_summary.get("commands_executed", -1) or 0) == 0 else "failed",
        "proof": f"commands_executed={preflight_summary.get('commands_executed')}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if preflight_summary.get("remote_writes_allowed") is False else "failed",
        "proof": f"remote_writes_allowed={preflight_summary.get('remote_writes_allowed')}",
    },
]

if preflight_ready:
    if not nonempty_string(launcher_package.get("runtime")):
        blockers.append("launcher_package.runtime is required")
    if not nonempty_string(launcher_package.get("profile_id")):
        blockers.append("launcher_package.profile_id is required")
    if not nonempty_string(launcher_package.get("command_surface")):
        blockers.append("launcher_package.command_surface is required")
    if not approved_commands:
        blockers.append("launcher_package.approved_commands must include exact commands")
    if int(budget.get("max_commands", 0) or 0) < len(approved_commands):
        blockers.append("budget.max_commands must cover planned command count")
    if int(budget.get("max_agents", 0) or 0) <= 0:
        blockers.append("budget.max_agents must be positive")
    if int(budget.get("max_paid_tokens", 0) or 0) <= 0:
        blockers.append("budget.max_paid_tokens must be positive")
    if int(budget.get("max_runtime_seconds", 0) or 0) <= 0:
        blockers.append("budget.max_runtime_seconds must be positive")
    if not nonempty_string(budget.get("stop_rule")):
        blockers.append("budget.stop_rule is required")
    if workspace.get("repo") != str(Path.cwd()):
        blockers.append("workspace.repo must match current repository")
    if rollback.get("required_before_runtime") is not True:
        blockers.append("rollback.required_before_runtime must be true")
    if rollback.get("preserve_logs") is not True:
        blockers.append("rollback.preserve_logs must be true")
    if validation.get("required_before_done") is not True:
        blockers.append("validation.required_before_done must be true")
    if not (list(validation.get("checks") or []) or list(validation.get("evidence_artifacts") or [])):
        blockers.append("validation checks or evidence artifacts are required")

    blocked_patterns = [
        r"\bgit\s+push\b",
        r"\bgh\s+(pr|issue|repo|api)\b",
        r"\bdeploy\b",
        r"\bkubectl\b",
        r"\bscp\b",
        r"\brsync\b",
        r"\bssh\s+",
    ]
    for command in approved_commands:
        if not nonempty_string(command):
            blockers.append("planned commands cannot be empty")
            continue
        for pattern in blocked_patterns:
            if re.search(pattern, command):
                blockers.append(f"planned command is blocked before separate remote/production gate: {command}")
                break

    plan_checks.extend([
        {
            "id": "runtime_profile_bound",
            "status": "passed" if nonempty_string(launcher_package.get("runtime")) and nonempty_string(launcher_package.get("profile_id")) else "failed",
            "proof": f"runtime={launcher_package.get('runtime', '')} profile={launcher_package.get('profile_id', '')}",
        },
        {
            "id": "command_budget_bound",
            "status": "passed" if int(budget.get("max_commands", 0) or 0) >= len(approved_commands) > 0 else "failed",
            "proof": f"commands={len(approved_commands)} max_commands={budget.get('max_commands')}",
        },
        {
            "id": "workspace_bound",
            "status": "passed" if workspace.get("repo") == str(Path.cwd()) else "failed",
            "proof": workspace.get("repo", ""),
        },
        {
            "id": "rollback_bound",
            "status": "passed" if rollback.get("required_before_runtime") is True and rollback.get("preserve_logs") is True else "failed",
            "proof": json.dumps(rollback, ensure_ascii=False),
        },
        {
            "id": "validation_bound",
            "status": "passed" if validation.get("required_before_done") is True else "failed",
            "proof": json.dumps(validation, ensure_ascii=False),
        },
        {
            "id": "git_context_recorded",
            "status": "passed" if git_context["head"] else "failed",
            "proof": f"branch={git_context['branch']} head={git_context['head']} dirty={git_context['dirty']}",
        },
    ])

failed_checks = [item for item in plan_checks if item["status"] == "failed"]
human_gate_checks = [item for item in plan_checks if item["status"] == "human_gate"]
plan_ready = preflight_ready and not blockers and not failed_checks

if plan_ready:
    overall = "launcher_command_plan_ready"
    plan_state = "command_plan_ready"
    next_action = "eligible_for_supervised_launcher_execution_gate"
elif human_gate_checks and not failed_checks and not blockers:
    overall = "human_gate"
    plan_state = "waiting_for_launcher_preflight_ready"
    next_action = "wait_for_launcher_preflight_ready"
else:
    overall = "failed"
    plan_state = "blocked"
    next_action = "fix_launcher_preflight_or_command_plan_blockers"

planned_steps = []
if plan_ready:
    for index, command in enumerate(approved_commands, 1):
        planned_steps.append({
            "step": index,
            "command": command,
            "surface": launcher_package.get("command_surface", ""),
            "runtime": launcher_package.get("runtime", ""),
            "execute": False,
            "requires_supervised_execution_gate": True,
        })

summary = {
    "launcher_preflight_ready": preflight_ready,
    "command_plan_ready": plan_ready,
    "plan_checks": len(plan_checks),
    "plan_passed": sum(1 for item in plan_checks if item["status"] == "passed"),
    "plan_failed": len(failed_checks),
    "plan_human_gate": len(human_gate_checks),
    "planned_commands_count": len(planned_steps),
    "launcher_execution_allowed": False,
    "runtime_execution_allowed": False,
    "runtime_started": False,
    "agents_started": 0,
    "commands_executed": 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "paid_tokens_authorized": int(budget.get("max_paid_tokens", 0) or 0) if plan_ready else 0,
}

command_plan = {
    "kind": "future_supervised_launcher_execution_input",
    "eligible": plan_ready,
    "runtime": launcher_package.get("runtime") if plan_ready else "",
    "profile_id": launcher_package.get("profile_id") if plan_ready else "",
    "command_surface": launcher_package.get("command_surface") if plan_ready else "",
    "budget": budget if plan_ready else {},
    "workspace": workspace if plan_ready else {},
    "validation": validation if plan_ready else {},
    "rollback": rollback if plan_ready else {},
    "steps": planned_steps,
    "logs": {
        "command_plan": f"{artifact_root}/COMMAND_PLAN.md",
        "status": f"{artifact_root}/STATUS.md",
        "validation": f"{artifact_root}/VALIDATION.md",
        "handoff": f"{artifact_root}/HANDOFF.md",
    },
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-launcher-command-plan.sh",
    "mode": "read_only_agent_runtime_launcher_command_plan",
    "overall": overall,
    "reason": "Launcher command plan was evaluated without executing commands or starting runtime.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "launcher_preflight": str(launcher_preflight_path),
    },
    "plan_state": plan_state,
    "next_action": next_action,
    "summary": summary,
    "launcher_preflight": {
        "overall": launcher_preflight.get("overall"),
        "preflight_state": launcher_preflight.get("preflight_state"),
        "next_action": launcher_preflight.get("next_action"),
    },
    "git_context": git_context,
    "plan_checks": plan_checks,
    "command_plan": command_plan,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Command Plan is read-only and never executes planned commands.",
        "launcher_command_plan_ready means eligible for a supervised execution gate, not execution.",
        "Runtime execution remains false in this cut.",
        "Remote writes, secrets, deploys, production and paid runtime remain separate Human Gates.",
        "Future launcher execution gates must consume this artifact and preserve logs.",
    ],
    "next_cut": "TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony",
}

(artifact_root / "launcher-command-plan.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER COMMAND PLAN STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Plan state: `{plan_state}`",
    f"- Next action: `{next_action}`",
    f"- Launcher preflight ready: `{str(preflight_ready).lower()}`",
    f"- Command plan ready: `{str(plan_ready).lower()}`",
    f"- Planned commands: `{len(planned_steps)}`",
    f"- Launcher execution allowed: `false`",
    f"- Runtime execution allowed: `false`",
    f"- Runtime started: `false`",
    f"- Agents started: `0`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
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
    "# ARTEMIS AGENT RUNTIME LAUNCHER COMMAND PLAN VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Launcher preflight ready: `{str(preflight_ready).lower()}`",
    f"- Plan checks: `{len(plan_checks)}`",
    f"- Passed: `{summary['plan_passed']}`",
    f"- Failed: `{summary['plan_failed']}`",
    f"- Human Gate: `{summary['plan_human_gate']}`",
    f"- Launcher execution allowed: `false`",
    f"- Runtime execution allowed: `false`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
    "",
    "## Checks",
    "",
]
for item in plan_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

plan_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER COMMAND PLAN",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Plan state: `{plan_state}`",
    f"- Eligible for supervised execution gate: `{str(plan_ready).lower()}`",
    "",
    "## Comandos planejados",
    "",
]
if planned_steps:
    for step in planned_steps:
        plan_lines.append(f"{step['step']}. `{step['command']}`")
else:
    plan_lines.append("- Nenhum comando materializado enquanto o preflight nao estiver `launcher_preflight_ready`.")
plan_lines.extend([
    "",
    "## Limites",
    "",
    "- Este plano nao executa comando.",
    "- Este plano nao inicia runtime.",
    "- Este plano nao autoriza escrita remota, secrets, deploy, producao ou custo real.",
])
(artifact_root / "COMMAND_PLAN.md").write_text("\n".join(plan_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER COMMAND PLAN HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-063 avaliou o plano de comandos como `{overall}` com estado `{plan_state}`.",
    "",
    "## Proximo corte",
    "",
]
if plan_ready:
    handoff_lines.append("- Implementar `TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony` usando este plano de comandos.")
else:
    handoff_lines.append("- Implementar `TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony`, mantendo execucao bloqueada ate existir `launcher_command_plan_ready`.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao iniciar Codex app-server, Claude Code, SDK, CLI, subagente, fila ou daemon neste plano.",
    "- Nao executar comandos planejados neste plano.",
    "- Nao tocar secrets, producao, deploy, push ou PR.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

plan_event = event(
    event_id="evt_tkt-063_agent_runtime_launcher_command_plan",
    event_type="runner.attempt_planned",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_launcher_command_plan", "name": "scripts/artemis-agent-runtime-launcher-command-plan.sh", "mode": "read_only"},
    ticket="TKT-063",
    title="Agent Runtime Launcher Command Plan do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-063-artemis-agent-runtime-launcher-command-plan.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to="ready" if plan_ready else ("human_gate" if overall == "human_gate" else "blocked"),
    severity="info" if plan_ready else ("warning" if overall == "human_gate" else "error"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "plan_state": plan_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": "agent_runtime_launcher_command_plan",
        "execute": False,
        "commands_planned": len(planned_steps),
        "commands_executed": 0,
    },
    gate={
        "kind": "human" if overall == "human_gate" else "none",
        "status": "human_gate" if overall == "human_gate" else "not_applicable",
        "reason": "Launcher execution remains blocked in TKT-063.",
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-launcher-command-plan.sh", generated_at=generated_at, events=[plan_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Launcher Command Plan: {overall}")
    print(
        "summary: "
        f"plan_state={plan_state} "
        f"command_plan_ready={str(summary['command_plan_ready']).lower()} "
        "launcher_execution_allowed=false runtime_execution_allowed=false commands_executed=0"
    )

if overall == "failed":
    raise SystemExit(1)
PY
