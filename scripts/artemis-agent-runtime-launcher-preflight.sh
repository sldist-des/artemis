#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-launcher-preflight/run-01"
decision_intake_path="artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-launcher-preflight.sh [--artifact-root path] [--decision-intake path] [--json]

Builds the ARTEMIS Agent Runtime Launcher Preflight package from a Decision
Intake artifact. This is read-only: it validates whether a human-approved
decision is coherent enough for a future launcher command plan, but it never
starts Codex, Claude Code, subagents, queues, daemons, commands, paid tokens,
remote writes, secrets, deploys or production changes.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision-intake)
      decision_intake_path="${2:-}"
      if [ -z "$decision_intake_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$decision_intake_path" "$format" <<'PY'
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
decision_intake_path = Path(sys.argv[2])
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


def valid_timestamp(value):
    if not value:
        return False
    try:
        datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


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


decision_intake = read_json(decision_intake_path)
approval_request = decision_intake.get("approval_request") or {}
decision_record = decision_intake.get("decision_record") or {}
approved_budget = decision_record.get("approved_budget") or {}
approved_auth = decision_record.get("approved_auth") or {}
approved_workspace = decision_record.get("approved_workspace") or {}
approved_rollback = decision_record.get("approved_rollback") or {}
approved_validation = decision_record.get("approved_validation") or {}
approved_commands = list(decision_record.get("approved_commands") or [])
intake_summary = decision_intake.get("summary") or {}
git_context = current_git_context()

intake_ready = (
    decision_intake.get("overall") == "ready_for_launcher_preflight"
    and decision_intake.get("intake_state") == "approved_ready"
    and intake_summary.get("launcher_preflight_allowed") is True
)

preflight_checks = [
    {
        "id": "decision_intake_exists",
        "status": "passed" if decision_intake_path.is_file() else "failed",
        "proof": str(decision_intake_path),
    },
    {
        "id": "decision_intake_ready",
        "status": "passed" if intake_ready else "human_gate",
        "proof": f"overall={decision_intake.get('overall')} intake_state={decision_intake.get('intake_state')}",
    },
    {
        "id": "runtime_not_started",
        "status": "passed" if intake_summary.get("runtime_started") is False else "failed",
        "proof": f"runtime_started={intake_summary.get('runtime_started')}",
    },
    {
        "id": "commands_not_executed",
        "status": "passed" if int(intake_summary.get("commands_executed", -1) or 0) == 0 else "failed",
        "proof": f"commands_executed={intake_summary.get('commands_executed')}",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed" if intake_summary.get("remote_writes_allowed") is False else "failed",
        "proof": f"remote_writes_allowed={intake_summary.get('remote_writes_allowed')}",
    },
]

if intake_ready:
    if decision_record.get("decision") != "approved":
        blockers.append("decision_record.decision must be approved")
    for field in ["decided_by", "decided_at", "reason"]:
        if not nonempty_string(decision_record.get(field)):
            blockers.append(f"{field} is required")
    if not valid_timestamp(decision_record.get("decided_at")):
        blockers.append("decided_at must be ISO-8601")
    if decision_record.get("approved_profile_id") != approval_request.get("profile_id"):
        blockers.append("approved_profile_id must match approval_request.profile_id")
    if decision_record.get("approved_runtime") != approval_request.get("runtime"):
        blockers.append("approved_runtime must match approval_request.runtime")
    if decision_record.get("approved_command_surface") != approval_request.get("command_surface"):
        blockers.append("approved_command_surface must match approval_request.command_surface")
    if int(approved_budget.get("max_agents", 0) or 0) <= 0:
        blockers.append("approved_budget.max_agents must be positive")
    if int(approved_budget.get("max_commands", 0) or 0) <= 0:
        blockers.append("approved_budget.max_commands must be positive")
    if int(approved_budget.get("max_paid_tokens", 0) or 0) <= 0:
        blockers.append("approved_budget.max_paid_tokens must be positive")
    if int(approved_budget.get("max_runtime_seconds", 0) or 0) <= 0:
        blockers.append("approved_budget.max_runtime_seconds must be positive")
    if int(approved_budget.get("max_commands", 0) or 0) < len(approved_commands):
        blockers.append("approved_budget.max_commands must cover approved command count")
    if not nonempty_string(approved_budget.get("stop_rule")):
        blockers.append("approved_budget.stop_rule is required")
    if bool((approval_request.get("auth") or {}).get("required")) and approved_auth.get("auth_confirmed") is not True:
        blockers.append("approved_auth.auth_confirmed is required for account-backed runtime")
    if approved_auth.get("secrets_touched") is not False:
        blockers.append("approved_auth.secrets_touched must remain false")
    if approved_workspace.get("repo") != str(Path.cwd()):
        blockers.append("approved_workspace.repo must match current repository")
    if approved_workspace.get("repo") != (approval_request.get("workspace") or {}).get("repo"):
        blockers.append("approved_workspace.repo must match approval_request.workspace.repo")
    for field in ["write_scope", "branch_policy", "worktree_policy", "dirty_state_policy"]:
        if not nonempty_string(approved_workspace.get(field)):
            blockers.append(f"approved_workspace.{field} is required")
    if approved_rollback.get("required_before_runtime") is not True:
        blockers.append("approved_rollback.required_before_runtime must be true")
    if not nonempty_string(approved_rollback.get("abort_path")):
        blockers.append("approved_rollback.abort_path is required")
    if approved_rollback.get("preserve_logs") is not True:
        blockers.append("approved_rollback.preserve_logs must be true")
    checks = list(approved_validation.get("checks") or [])
    evidence_artifacts = list(approved_validation.get("evidence_artifacts") or [])
    if approved_validation.get("required_before_done") is not True:
        blockers.append("approved_validation.required_before_done must be true")
    if not checks and not evidence_artifacts:
        blockers.append("approved_validation must include checks or evidence_artifacts")
    if not approved_commands:
        blockers.append("approved_commands must include exact command(s)")

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
            blockers.append("approved_commands cannot contain empty commands")
            continue
        for pattern in blocked_patterns:
            if re.search(pattern, command):
                blockers.append(f"approved command is blocked before separate remote/production gate: {command}")
                break

    preflight_checks.extend([
        {
            "id": "human_metadata",
            "status": "passed" if nonempty_string(decision_record.get("decided_by")) and valid_timestamp(decision_record.get("decided_at")) else "failed",
            "proof": "decided_by and decided_at",
        },
        {
            "id": "budget_positive",
            "status": "passed" if all(int(approved_budget.get(key, 0) or 0) > 0 for key in ["max_agents", "max_commands", "max_paid_tokens", "max_runtime_seconds"]) else "failed",
            "proof": json.dumps(approved_budget, ensure_ascii=False),
        },
        {
            "id": "workspace_current",
            "status": "passed" if approved_workspace.get("repo") == str(Path.cwd()) else "failed",
            "proof": approved_workspace.get("repo", ""),
        },
        {
            "id": "git_context_recorded",
            "status": "passed" if git_context["head"] else "failed",
            "proof": f"branch={git_context['branch']} head={git_context['head']} dirty={git_context['dirty']}",
        },
        {
            "id": "rollback_ready",
            "status": "passed" if approved_rollback.get("required_before_runtime") is True and approved_rollback.get("preserve_logs") is True else "failed",
            "proof": json.dumps(approved_rollback, ensure_ascii=False),
        },
        {
            "id": "validation_declared",
            "status": "passed" if checks or evidence_artifacts else "failed",
            "proof": f"checks={len(checks)} evidence={len(evidence_artifacts)}",
        },
        {
            "id": "commands_declared_not_executed",
            "status": "passed" if approved_commands else "failed",
            "proof": f"approved_commands={len(approved_commands)} commands_executed=0",
        },
    ])

failed_checks = [item for item in preflight_checks if item["status"] == "failed"]
human_gate_checks = [item for item in preflight_checks if item["status"] == "human_gate"]
preflight_ready = intake_ready and not blockers and not failed_checks

if preflight_ready:
    overall = "launcher_preflight_ready"
    preflight_state = "preflight_ready"
    next_action = "eligible_for_agent_runtime_launcher_command_plan"
elif human_gate_checks and not failed_checks and not blockers:
    overall = "human_gate"
    preflight_state = "waiting_for_approved_ready"
    next_action = "wait_for_decision_intake_approved_ready"
else:
    overall = "failed"
    preflight_state = "blocked"
    next_action = "fix_decision_intake_or_preflight_blockers"

summary = {
    "decision_intake_ready": intake_ready,
    "preflight_checks": len(preflight_checks),
    "preflight_passed": sum(1 for item in preflight_checks if item["status"] == "passed"),
    "preflight_failed": len(failed_checks),
    "preflight_human_gate": len(human_gate_checks),
    "approved_commands_count": len(approved_commands) if intake_ready else 0,
    "launcher_preflight_allowed": preflight_ready,
    "launcher_execution_allowed": False,
    "runtime_execution_allowed": False,
    "runtime_started": False,
    "agents_started": 0,
    "commands_executed": 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "paid_tokens_authorized": int(approved_budget.get("max_paid_tokens", 0) or 0) if preflight_ready else 0,
}

launcher_package = {
    "kind": "future_launcher_command_plan_input",
    "eligible": preflight_ready,
    "runtime": decision_record.get("approved_runtime") if preflight_ready else "",
    "profile_id": decision_record.get("approved_profile_id") if preflight_ready else "",
    "command_surface": decision_record.get("approved_command_surface") if preflight_ready else "",
    "approved_commands": approved_commands if preflight_ready else [],
    "budget": approved_budget if preflight_ready else {},
    "workspace": approved_workspace if preflight_ready else {},
    "validation": approved_validation if preflight_ready else {},
    "rollback": approved_rollback if preflight_ready else {},
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-launcher-preflight.sh",
    "mode": "read_only_agent_runtime_launcher_preflight",
    "overall": overall,
    "reason": "Launcher preflight was evaluated without starting any agent runtime.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "decision_intake": str(decision_intake_path),
    },
    "preflight_state": preflight_state,
    "next_action": next_action,
    "summary": summary,
    "approval_request": approval_request,
    "decision_record": decision_record if intake_ready else {},
    "git_context": git_context,
    "preflight_checks": preflight_checks,
    "launcher_package": launcher_package,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Launcher Preflight is read-only and never starts runtime.",
        "launcher_preflight_ready means eligible for command planning, not execution.",
        "Runtime execution remains false in this cut.",
        "Remote writes, secrets, deploys and production remain separate Human Gates.",
        "Future launcher command plans must consume this artifact and preserve logs.",
    ],
    "next_cut": "TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony",
}

(artifact_root / "launcher-preflight.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER PREFLIGHT STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Preflight state: `{preflight_state}`",
    f"- Next action: `{next_action}`",
    f"- Decision intake ready: `{str(intake_ready).lower()}`",
    f"- Launcher preflight allowed: `{str(summary['launcher_preflight_allowed']).lower()}`",
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
    "# ARTEMIS AGENT RUNTIME LAUNCHER PREFLIGHT VALIDATION",
    "",
    f"- Overall: `{overall}`",
    f"- Decision intake ready: `{str(intake_ready).lower()}`",
    f"- Preflight checks: `{len(preflight_checks)}`",
    f"- Passed: `{summary['preflight_passed']}`",
    f"- Failed: `{summary['preflight_failed']}`",
    f"- Human Gate: `{summary['preflight_human_gate']}`",
    f"- Launcher execution allowed: `false`",
    f"- Runtime execution allowed: `false`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
    "",
    "## Checks",
    "",
]
for item in preflight_checks:
    validation_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

preflight_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER PREFLIGHT",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`",
    f"- Preflight state: `{preflight_state}`",
    f"- Eligible for future command plan: `{str(preflight_ready).lower()}`",
    "",
    "## Pacote futuro",
    "",
    f"- Runtime: `{launcher_package['runtime']}`",
    f"- Profile: `{launcher_package['profile_id']}`",
    f"- Command surface: `{launcher_package['command_surface']}`",
    f"- Approved commands: `{len(launcher_package['approved_commands'])}`",
    "",
    "## Limites",
    "",
    "- Este preflight nao executa comando.",
    "- Este preflight nao inicia runtime.",
    "- Este preflight nao autoriza escrita remota, secrets, deploy ou producao.",
]
(artifact_root / "PREFLIGHT.md").write_text("\n".join(preflight_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME LAUNCHER PREFLIGHT HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-062 avaliou o preflight de launcher como `{overall}` com estado `{preflight_state}`.",
    "",
    "## Proximo corte",
    "",
]
if preflight_ready:
    handoff_lines.append("- Implementar `TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony` usando este pacote de preflight.")
else:
    handoff_lines.append("- Implementar `TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony`, mantendo comando e runtime bloqueados ate existir `launcher_preflight_ready`.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao iniciar Codex app-server, Claude Code, SDK, CLI, subagente, fila ou daemon neste preflight.",
    "- Nao executar comandos aprovados neste preflight.",
    "- Nao tocar secrets, producao, deploy, push ou PR.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

runtime_event = event(
    event_id="evt_tkt-062_agent_runtime_launcher_preflight",
    event_type="runner.preflight_recorded",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_launcher_preflight", "name": "scripts/artemis-agent-runtime-launcher-preflight.sh", "mode": "read_only"},
    ticket="TKT-062",
    title="Agent Runtime Launcher Preflight do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-062-artemis-agent-runtime-launcher-preflight.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to="ready" if preflight_ready else ("human_gate" if overall == "human_gate" else "blocked"),
    severity="info" if preflight_ready else ("warning" if overall == "human_gate" else "error"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "preflight_state": preflight_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    gate={
        "kind": "human",
        "status": "human_gate" if overall == "human_gate" else "not_applicable",
        "reason": "Launcher execution remains blocked in TKT-062.",
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-launcher-preflight.sh", generated_at=generated_at, events=[runtime_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Launcher Preflight: {overall}")
    print(
        "summary: "
        f"preflight_state={preflight_state} "
        f"launcher_preflight_allowed={str(summary['launcher_preflight_allowed']).lower()} "
        "launcher_execution_allowed=false runtime_execution_allowed=false commands=0"
    )

if overall == "failed":
    raise SystemExit(1)
PY
