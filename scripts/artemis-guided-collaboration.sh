#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-guided-collaboration/run-01"
project_brief="artifacts/artemis-project-brief/run-01/project-brief.json"
project_graph="artifacts/artemis-project-graph/run-01/project-graph.json"
tasks_file="control-plane/tasks.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-guided-collaboration.sh [--artifact-root path] [--project-brief path] [--project-graph path] [--tasks path] [--control-plane path] [--json]

Builds the read-only Guided Human Collaboration contract for ARTEMIS Symphony.
It helps a person choose project, task lane, agent profile, gates and evidence
before work starts. It does not dispatch agents, start runtime, install
dependencies, write remote state, or approve Human Gates.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$project_brief" "$project_graph" "$tasks_file" "$control_plane" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
project_brief_path = Path(sys.argv[2])
project_graph_path = Path(sys.argv[3])
tasks_path = Path(sys.argv[4])
control_plane_path = Path(sys.argv[5])
output_format = sys.argv[6]
generated_at = now_utc()

brief = json.loads(project_brief_path.read_text(encoding="utf-8"))
graph = json.loads(project_graph_path.read_text(encoding="utf-8"))
tasks_payload = json.loads(tasks_path.read_text(encoding="utf-8"))
html = control_plane_path.read_text(encoding="utf-8")

summary = brief.get("summary", {})
tasks = tasks_payload.get("tasks", [])
done_tasks = [task for task in tasks if task.get("state") == "done"]
human_tasks = [task for task in tasks if task.get("state") == "human"]
ready_tasks = [task for task in tasks if task.get("state") in {"ready", "intake"}]

required_tokens = [
    "guided-collaboration-section",
    "guided-collaboration-status",
    "guided-collaboration-projects",
    "guided-collaboration-tasks",
    "guided-collaboration-agents",
    "guided-collaboration-gates",
    "guidedCollaborationSourceUrl",
    "renderGuidedCollaboration",
    "loadGuidedCollaborationSource",
]
missing_tokens = [token for token in required_tokens if token not in html]

required_files = [
    project_brief_path,
    project_graph_path,
    tasks_path,
    control_plane_path,
    Path("docs/symphony/ARTEMIS_SYMPHONY_GUIDED_COLLABORATION.md"),
    Path("docs/exec-packs/done/TKT-057-artemis-guided-collaboration.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

projects = [
    {
        "id": "artemis",
        "name": "ARTEMIS",
        "status": "operational_local_supervised",
        "summary": "Metodo e Symphony locais prontos para explicar trabalho, gates, evidencia e limites antes de acionar agentes.",
        "source_of_truth": "git_exec_packs_artifacts",
        "entry_artifacts": [
            str(project_brief_path),
            str(project_graph_path),
            "docs/symphony/ARTEMIS_SYMPHONY_SPEC.md",
        ],
    }
]

task_lanes = [
    {
        "id": "choose_project",
        "label": "Escolher projeto",
        "state": "ready",
        "question": "Qual repositorio ou produto sera trabalhado?",
        "evidence": "Git remoto/local, AGENTS.md e Exec Packs existentes.",
        "human_gate": "Obrigatorio quando envolver novo repositorio, secrets, producao ou push.",
    },
    {
        "id": "choose_task",
        "label": "Escolher tarefa",
        "state": "ready",
        "question": "Qual objetivo concreto, reversivel e verificavel entra no fluxo?",
        "evidence": "Exec Pack com objetivo, escopo, risco, validacao e handoff.",
        "human_gate": "Obrigatorio para escopo ambiguo, limpeza real, custo alto ou mudanca remota.",
    },
    {
        "id": "choose_agent",
        "label": "Escolher agente",
        "state": "ready",
        "question": "Qual perfil deve atuar: Codex frontier, Claude Code rapido, reviewer ou verifier?",
        "evidence": "Contrato de agente, limite de tokens, comandos permitidos e validacao esperada.",
        "human_gate": "Obrigatorio antes de runtime remoto, auth, rede, ferramenta paga ou execucao longa.",
    },
    {
        "id": "confirm_evidence",
        "label": "Confirmar evidencia",
        "state": "ready",
        "question": "O que prova que a tarefa terminou sem perder controle?",
        "evidence": "Validation Gate, logs, artefatos, git diff, screenshot ou teste end-to-end.",
        "human_gate": "Obrigatorio quando a evidencia exigir decisao de aceite humana.",
    },
]

agent_profiles = [
    {
        "id": "codex_frontier",
        "name": "Codex frontier",
        "best_for": "Tarefas longas, arquitetura, integracao, validacao ampla e commits Lore.",
        "avoid_for": "Exploracao simples que pode ser resolvida por leitura rapida.",
        "budget": "alto",
        "terminal_first": True,
        "requires_auth": False,
    },
    {
        "id": "claude_code_fast",
        "name": "Claude Code rapido",
        "best_for": "Mapear diretorios, entender linguagem, sugerir recortes medios e revisar contexto.",
        "avoid_for": "Tarefas longas sem checkpoints, alto custo ou alteracoes amplas sem supervisao.",
        "budget": "medio",
        "terminal_first": True,
        "requires_auth": True,
    },
    {
        "id": "verifier",
        "name": "Verifier",
        "best_for": "Conferir evidencia, testes, gates, screenshots e claims de conclusao.",
        "avoid_for": "Implementar escopo novo sem contrato claro.",
        "budget": "baixo_medio",
        "terminal_first": True,
        "requires_auth": False,
    },
    {
        "id": "human_owner",
        "name": "Humano owner",
        "best_for": "Decidir auth, custo, producao, remoto, prioridade, risco e aceite.",
        "avoid_for": "Microgerenciar comandos reversiveis que ja estao cobertos por contrato.",
        "budget": "decisao",
        "terminal_first": True,
        "requires_auth": False,
    },
]

gate_contract = [
    {
        "id": "auth_gate",
        "label": "Auth",
        "status": "human_required_before_real_use",
        "rule": "Codex app-server, Claude Code, GitHub ou qualquer conta pessoal precisam de autenticacao explicita do humano.",
    },
    {
        "id": "budget_gate",
        "label": "Budget",
        "status": "human_required_before_runtime",
        "rule": "Token, custo, modelo, tempo maximo e numero de agentes devem ser declarados antes de execucao real.",
    },
    {
        "id": "remote_write_gate",
        "label": "Remote write",
        "status": "blocked_by_default",
        "rule": "Push, PR, issue mutation, deploy e configuracao remota continuam bloqueados ate decisao humana.",
    },
    {
        "id": "validation_gate",
        "label": "Validation",
        "status": "required_before_done",
        "rule": "Toda tarefa guiada precisa declarar a evidencia que sera aceita antes de entrar em Done.",
    },
]

commands = [
    "scripts/artemis-guided-collaboration.sh --json",
    "scripts/artemis-project-brief.sh --json",
    "scripts/artemis-validation-gate.sh --json",
    "scripts/validate-artemis.sh",
]

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-guided-collaboration.sh",
    "mode": "read_only_guided_human_collaboration",
    "overall": "guided_collaboration_ready",
    "reason": "Guided collaboration contract was derived from Project Brief, Project Graph and local task source.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "project_brief": str(project_brief_path),
        "project_graph": str(project_graph_path),
        "tasks": str(tasks_path),
        "control_plane": str(control_plane_path),
    },
    "summary": {
        "projects_total": len(projects),
        "task_lanes": len(task_lanes),
        "agent_profiles": len(agent_profiles),
        "gate_contracts": len(gate_contract),
        "tasks_total": len(tasks),
        "tasks_done": len(done_tasks),
        "tasks_human": len(human_tasks),
        "tasks_ready": len(ready_tasks),
        "validation_passed": int(summary.get("validation_passed", 0)),
        "validation_failed": int(summary.get("validation_failed", 0)),
        "human_gates": int(summary.get("human_gates", 0)),
        "commands_executed": 0,
        "dependencies_installed": 0,
        "runtime_started": False,
        "agents_started": 0,
        "remote_writes_allowed": False,
        "source_of_truth_changed": False,
    },
    "projects": projects,
    "task_lanes": task_lanes,
    "agent_profiles": agent_profiles,
    "gate_contract": gate_contract,
    "guided_flow": [
        "Escolha o projeto e confirme a fonte canonica.",
        "Escolha uma tarefa pequena o bastante para validar.",
        "Escolha o perfil de agente pelo risco, contexto e duracao.",
        "Declare budget, auth, comandos permitidos e evidencias esperadas.",
        "Pare em Human Gate antes de custo, rede, remoto, producao ou cleanup real.",
    ],
    "commands": commands,
    "missing_tokens": missing_tokens,
    "missing_files": missing_files,
    "required_tokens": required_tokens,
    "next_cut": "NONE - ARTEMIS Portal supervised control spine complete",
}

ready = (
    brief.get("overall") == "human_project_brief_ready"
    and graph.get("overall") == "project_graph_ready"
    and not missing_tokens
    and not missing_files
    and payload["summary"]["validation_failed"] == 0
)
if not ready:
    payload["overall"] = "failed"
    payload["reason"] = "Guided collaboration contract is incomplete."

(artifact_root / "guided-collaboration.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS GUIDED COLLABORATION STATUS",
    "",
    f"- Overall: `{payload['overall']}`",
    f"- Reason: {payload['reason']}",
    f"- Projects: `{len(projects)}`",
    f"- Task lanes: `{len(task_lanes)}`",
    f"- Agent profiles: `{len(agent_profiles)}`",
    f"- Gate contracts: `{len(gate_contract)}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
    f"- Agents started: `{payload['summary']['agents_started']}`",
    f"- Remote writes allowed: `{str(payload['summary']['remote_writes_allowed']).lower()}`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS GUIDED COLLABORATION VALIDATION",
    "",
    f"- Project Brief ready: `{str(brief.get('overall') == 'human_project_brief_ready').lower()}`",
    f"- Project Graph ready: `{str(graph.get('overall') == 'project_graph_ready').lower()}`",
    f"- Required UI tokens present: `{str(not missing_tokens).lower()}`",
    f"- Required files present: `{str(not missing_files).lower()}`",
    f"- Technical validation failed: `{payload['summary']['validation_failed']}`",
    f"- Commands executed: `{payload['summary']['commands_executed']}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
    f"- Agents started: `{payload['summary']['agents_started']}`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

guide_lines = [
    "# ARTEMIS GUIDED COLLABORATION",
    "",
    "## Entrada guiada",
    "",
]
guide_lines.extend(f"- {item}" for item in payload["guided_flow"])
guide_lines.extend(["", "## Perfis de agente", ""])
for profile in agent_profiles:
    guide_lines.append(f"- **{profile['name']}**: {profile['best_for']} Budget: `{profile['budget']}`.")
guide_lines.extend(["", "## Gates", ""])
for gate in gate_contract:
    guide_lines.append(f"- **{gate['label']}** (`{gate['status']}`): {gate['rule']}")
guide_lines.extend(["", "## Comandos de verificacao", ""])
guide_lines.extend(f"- `{command}`" for command in commands)
(artifact_root / "GUIDE.md").write_text("\n".join(guide_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS GUIDED COLLABORATION HANDOFF",
    "",
    "O modo guiado esta pronto como contrato read-only para pessoas escolherem projeto, tarefa, perfil de agente, gates e evidencia antes de runtime real.",
    "",
    "Proximo corte:",
    "",
    "- Nenhum TKT planejado na espinha atual de runtime.",
    "- Abrir nova fase somente com Exec Pack explicito.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

guided_event = event(
    event_id="evt_tkt-057_guided_collaboration",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "guided_collaboration", "name": "scripts/artemis-guided-collaboration.sh", "mode": "read_only"},
    ticket="TKT-057",
    title="Guided Human Collaboration Mode do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-057-artemis-guided-collaboration.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="done" if ready else "blocked",
    severity="info" if ready else "error",
    payload={
        "overall": payload["overall"],
        "reason": payload["reason"],
        "summary": payload["summary"],
        "next_cut": payload["next_cut"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-guided-collaboration.sh", generated_at=generated_at, events=[guided_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Guided Collaboration: {payload['overall']}")
    print(f"projects={len(projects)} task_lanes={len(task_lanes)} agent_profiles={len(agent_profiles)} gates={len(gate_contract)}")

if not ready:
    raise SystemExit(1)
PY
