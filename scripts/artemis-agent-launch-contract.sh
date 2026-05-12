#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-launch-contract/run-01"
guided_collaboration="artifacts/artemis-guided-collaboration/run-01/guided-collaboration.json"
project_brief="artifacts/artemis-project-brief/run-01/project-brief.json"
project_graph="artifacts/artemis-project-graph/run-01/project-graph.json"
tasks_file="control-plane/tasks.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-launch-contract.sh [--artifact-root path] [--guided-collaboration path] [--project-brief path] [--project-graph path] [--tasks path] [--control-plane path] [--json]

Builds the supervised agent launch contract for ARTEMIS Symphony.
It defines the minimum contract required before Codex, Claude Code or any
agent runtime can be launched from the guided collaboration surface. It does
not dispatch agents, start runtime, install dependencies, mutate remote state,
or approve Human Gates.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --guided-collaboration)
      guided_collaboration="${2:-}"
      if [ -z "$guided_collaboration" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-brief)
      project_brief="${2:-}"
      if [ -z "$project_brief" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-graph)
      project_graph="${2:-}"
      if [ -z "$project_graph" ]; then usage; exit 2; fi
      shift 2
      ;;
    --tasks)
      tasks_file="${2:-}"
      if [ -z "$tasks_file" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane)
      control_plane="${2:-}"
      if [ -z "$control_plane" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$guided_collaboration" "$project_brief" "$project_graph" "$tasks_file" "$control_plane" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
guided_path = Path(sys.argv[2])
brief_path = Path(sys.argv[3])
graph_path = Path(sys.argv[4])
tasks_path = Path(sys.argv[5])
control_plane_path = Path(sys.argv[6])
output_format = sys.argv[7]
generated_at = now_utc()

guided = json.loads(guided_path.read_text(encoding="utf-8"))
brief = json.loads(brief_path.read_text(encoding="utf-8"))
graph = json.loads(graph_path.read_text(encoding="utf-8"))
tasks_payload = json.loads(tasks_path.read_text(encoding="utf-8"))
html = control_plane_path.read_text(encoding="utf-8")

tasks = tasks_payload.get("tasks", [])
done_tasks = [task for task in tasks if task.get("state") == "done"]
human_tasks = [task for task in tasks if task.get("state") == "human"]
summary = brief.get("summary", {})

required_tokens = [
    "agent-launch-section",
    "agent-launch-status",
    "agent-launch-profiles",
    "agent-launch-gates",
    "agent-launch-evidence",
    "agentLaunchContractSourceUrl",
    "renderAgentLaunchContract",
    "loadAgentLaunchContractSource",
]
missing_tokens = [token for token in required_tokens if token not in html]

required_files = [
    guided_path,
    brief_path,
    graph_path,
    tasks_path,
    control_plane_path,
    Path("docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md"),
    Path("docs/exec-packs/done/TKT-058-artemis-agent-launch-contract.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

launch_profiles = [
    {
        "id": "codex_app_server",
        "name": "Codex app-server",
        "purpose": "Receber tarefas remotas ou web e manter supervisao por artifacts, approvals e Validation Gate.",
        "runtime": "codex_app_server",
        "command_surface": "codex app-server",
        "auth_required": True,
        "budget_required": True,
        "workspace_required": True,
        "max_default_agents": 1,
        "execute_default": False,
        "allowed_before_human_approval": ["read artifacts", "plan launch", "validate contract"],
        "blocked_before_human_approval": ["start runtime", "spawn paid agent", "push", "deploy", "touch secrets"],
    },
    {
        "id": "claude_code",
        "name": "Claude Code",
        "purpose": "Mapear repositorio, entender linguagem e executar tarefas medias com checkpoints curtos.",
        "runtime": "claude_code",
        "command_surface": "claude headless/sdk",
        "auth_required": True,
        "budget_required": True,
        "workspace_required": True,
        "max_default_agents": 1,
        "execute_default": False,
        "allowed_before_human_approval": ["read artifacts", "plan launch", "validate contract"],
        "blocked_before_human_approval": ["start runtime", "spawn paid agent", "push", "deploy", "touch secrets"],
    },
    {
        "id": "codex_terminal",
        "name": "Codex terminal-first",
        "purpose": "Atuar como executor principal local quando a tarefa exige controle fino, git e verificacao ampla.",
        "runtime": "codex_cli",
        "command_surface": "terminal",
        "auth_required": False,
        "budget_required": True,
        "workspace_required": True,
        "max_default_agents": 1,
        "execute_default": False,
        "allowed_before_human_approval": ["read artifacts", "plan launch", "validate contract"],
        "blocked_before_human_approval": ["start delegated runtime", "spawn paid agent", "push", "deploy", "touch secrets"],
    },
    {
        "id": "verifier",
        "name": "Verifier",
        "purpose": "Validar evidencia, testes, logs, screenshots e claims antes de Done ou handoff.",
        "runtime": "codex_subagent_or_manual_review",
        "command_surface": "verification",
        "auth_required": False,
        "budget_required": True,
        "workspace_required": False,
        "max_default_agents": 1,
        "execute_default": False,
        "allowed_before_human_approval": ["read artifacts", "plan verification", "validate evidence list"],
        "blocked_before_human_approval": ["approve Human Gate", "merge", "push", "deploy", "touch secrets"],
    },
]

launch_gates = [
    {
        "id": "project_gate",
        "label": "Project",
        "status": "required",
        "rule": "A launch request must name the repository/project and the canonical AGENTS.md contract.",
    },
    {
        "id": "task_gate",
        "label": "Task",
        "status": "required",
        "rule": "A launch request must point to an Exec Pack or explicit task artifact with objective, scope and risk.",
    },
    {
        "id": "auth_gate",
        "label": "Auth",
        "status": "human_required",
        "rule": "Any Codex app-server, Claude Code, GitHub or account-backed runtime requires explicit human authentication.",
    },
    {
        "id": "budget_gate",
        "label": "Budget",
        "status": "human_required",
        "rule": "Model, max tokens/cost, max agents, max wall time and stop rule must be declared before runtime.",
    },
    {
        "id": "command_gate",
        "label": "Command",
        "status": "required",
        "rule": "The exact command surface must be reviewed; launch remains execute=false until the next contract authorizes it.",
    },
    {
        "id": "workspace_gate",
        "label": "Workspace",
        "status": "required",
        "rule": "Agent write scope, branch/worktree, lock and dirty-state policy must be known before execution.",
    },
    {
        "id": "validation_gate",
        "label": "Validation",
        "status": "required",
        "rule": "The task must name tests, static checks, screenshots or artifacts that prove completion.",
    },
    {
        "id": "rollback_gate",
        "label": "Rollback",
        "status": "required",
        "rule": "A clean abort path and artifacts to preserve on failure must be listed before runtime.",
    },
    {
        "id": "remote_write_gate",
        "label": "Remote write",
        "status": "blocked_by_default",
        "rule": "Push, PR, issue mutation, deploy and production writes remain blocked until explicit human approval.",
    },
]

evidence_contract = [
    {
        "id": "launch_request",
        "label": "Launch request",
        "required": True,
        "artifact": "agent-launch-contract.json",
        "proof": "Project, task, runtime profile, budget, auth state, command surface and stop rule are explicit.",
    },
    {
        "id": "preflight",
        "label": "Preflight",
        "required": True,
        "artifact": "VALIDATION.md",
        "proof": "Contract is internally valid and read-only safety invariants are intact.",
    },
    {
        "id": "runtime_logs",
        "label": "Runtime logs",
        "required": "future_runtime",
        "artifact": "future runner/app-server logs",
        "proof": "When runtime exists, every agent turn must be tied to task, budget, command and evidence.",
    },
    {
        "id": "handoff",
        "label": "Handoff",
        "required": True,
        "artifact": "HANDOFF.md",
        "proof": "Next action is known and unresolved gates are visible.",
    },
]

candidate_launch = {
    "project": "ARTEMIS",
    "task": "TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony",
    "recommended_profile": "codex_terminal",
    "fallback_profile": "claude_code",
    "execute": False,
    "reason": "The next safe step is a command plan that consumes launcher preflight evidence without starting paid/runtime agents.",
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-launch-contract.sh",
    "mode": "read_only_supervised_agent_launch_contract",
    "overall": "agent_launch_contract_ready",
    "reason": "Supervised launch contract was derived from Guided Collaboration, Project Brief, Project Graph and task source.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "guided_collaboration": str(guided_path),
        "project_brief": str(brief_path),
        "project_graph": str(graph_path),
        "tasks": str(tasks_path),
        "control_plane": str(control_plane_path),
    },
    "summary": {
        "launch_profiles": len(launch_profiles),
        "launch_gates": len(launch_gates),
        "evidence_requirements": len(evidence_contract),
        "tasks_total": len(tasks),
        "tasks_done": len(done_tasks),
        "tasks_human": len(human_tasks),
        "validation_passed": int(summary.get("validation_passed", 0)),
        "validation_failed": int(summary.get("validation_failed", 0)),
        "human_gates": int(summary.get("human_gates", 0)),
        "execute_default": False,
        "runtime_started": False,
        "agents_started": 0,
        "commands_executed": 0,
        "dependencies_installed": 0,
        "remote_writes_allowed": False,
        "auth_required_before_real_use": True,
        "budget_required_before_runtime": True,
        "rollback_required_before_runtime": True,
        "validation_required_before_done": True,
    },
    "candidate_launch": candidate_launch,
    "launch_profiles": launch_profiles,
    "launch_gates": launch_gates,
    "evidence_contract": evidence_contract,
    "invariants": [
        "Agent Launch Contract is planning authority only; it never starts runtime.",
        "execute=false is the default for every launch profile.",
        "Human approval is required before auth-backed, paid, remote, production or long-running work.",
        "Validation Gate and rollback evidence must be declared before a task can move to Done.",
        "Git, Exec Packs, Event Log, artifacts and AGENTS.md remain canonical.",
    ],
    "missing_tokens": missing_tokens,
    "missing_files": missing_files,
    "required_tokens": required_tokens,
    "next_cut": "TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract",
}

ready = (
    guided.get("overall") == "guided_collaboration_ready"
    and brief.get("overall") == "human_project_brief_ready"
    and graph.get("overall") == "project_graph_ready"
    and not missing_tokens
    and not missing_files
    and payload["summary"]["validation_failed"] == 0
    and payload["summary"]["execute_default"] is False
    and payload["summary"]["runtime_started"] is False
    and payload["summary"]["agents_started"] == 0
    and payload["summary"]["commands_executed"] == 0
    and payload["summary"]["remote_writes_allowed"] is False
)
if not ready:
    payload["overall"] = "failed"
    payload["reason"] = "Supervised launch contract is incomplete."

(artifact_root / "agent-launch-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT LAUNCH CONTRACT STATUS",
    "",
    f"- Overall: `{payload['overall']}`",
    f"- Reason: {payload['reason']}",
    f"- Launch profiles: `{len(launch_profiles)}`",
    f"- Launch gates: `{len(launch_gates)}`",
    f"- Evidence requirements: `{len(evidence_contract)}`",
    f"- Execute default: `{str(payload['summary']['execute_default']).lower()}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
    f"- Agents started: `{payload['summary']['agents_started']}`",
    f"- Remote writes allowed: `{str(payload['summary']['remote_writes_allowed']).lower()}`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT LAUNCH CONTRACT VALIDATION",
    "",
    f"- Guided Collaboration ready: `{str(guided.get('overall') == 'guided_collaboration_ready').lower()}`",
    f"- Project Brief ready: `{str(brief.get('overall') == 'human_project_brief_ready').lower()}`",
    f"- Project Graph ready: `{str(graph.get('overall') == 'project_graph_ready').lower()}`",
    f"- Required UI tokens present: `{str(not missing_tokens).lower()}`",
    f"- Required files present: `{str(not missing_files).lower()}`",
    f"- Execute default false: `{str(payload['summary']['execute_default'] is False).lower()}`",
    f"- Commands executed: `{payload['summary']['commands_executed']}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
    f"- Agents started: `{payload['summary']['agents_started']}`",
    f"- Remote writes allowed: `{str(payload['summary']['remote_writes_allowed']).lower()}`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

contract_lines = [
    "# ARTEMIS AGENT LAUNCH CONTRACT",
    "",
    "## Regra central",
    "",
    "TKT-058 define o contrato minimo antes de qualquer agente real. Ele nao inicia runtime, nao executa comandos de agente, nao instala dependencias e nao escreve remoto.",
    "",
    "## Perfis",
    "",
]
for profile in launch_profiles:
    contract_lines.append(f"- **{profile['name']}** (`{profile['runtime']}`): {profile['purpose']} Execute default: `{str(profile['execute_default']).lower()}`.")
contract_lines.extend(["", "## Gates", ""])
for gate in launch_gates:
    contract_lines.append(f"- **{gate['label']}** (`{gate['status']}`): {gate['rule']}")
contract_lines.extend(["", "## Evidencia", ""])
for item in evidence_contract:
    contract_lines.append(f"- **{item['label']}**: {item['proof']}")
(artifact_root / "CONTRACT.md").write_text("\n".join(contract_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT LAUNCH CONTRACT HANDOFF",
    "",
    "O contrato supervisionado de lancamento de agentes esta pronto como superficie read-only. A partir dele o painel sabe o que precisa existir antes de acionar Codex app-server, Claude Code ou outro runtime.",
    "",
    "Proximo corte:",
    "",
    "- Nenhum TKT planejado na espinha atual de runtime.",
    "- Usar o Agent Runtime Launcher Preflight como entrada obrigatoria antes de materializar comandos em novas fases.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

launch_event = event(
    event_id="evt_tkt-058_agent_launch_contract",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "agent_launch_contract", "name": "scripts/artemis-agent-launch-contract.sh", "mode": "read_only"},
    ticket="TKT-058",
    title="Supervised Agent Launch Contract do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-058-artemis-agent-launch-contract.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="done" if ready else "blocked",
    severity="info" if ready else "error",
    payload={
        "overall": payload["overall"],
        "reason": payload["reason"],
        "summary": payload["summary"],
        "candidate_launch": candidate_launch,
        "next_cut": payload["next_cut"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-launch-contract.sh", generated_at=generated_at, events=[launch_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Launch Contract: {payload['overall']}")
    print(f"profiles={len(launch_profiles)} gates={len(launch_gates)} execute=false agents=0")

if not ready:
    raise SystemExit(1)
PY
