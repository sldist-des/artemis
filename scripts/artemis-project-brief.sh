#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-project-brief/run-01"
project_graph="artifacts/artemis-project-graph/run-01/project-graph.json"
project_graph_view="artifacts/artemis-project-graph-view/run-01/project-graph-view.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-project-brief.sh [--artifact-root path] [--project-graph path] [--project-graph-view path] [--control-plane path] [--json]

Builds the human-readable ARTEMIS Project Brief from the local Project
Operations Graph. This is a read-only explanation layer: it does not start
runtimes, install dependencies, execute agents, or make the Control Plane
canonical.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-graph)
      project_graph="${2:-}"
      if [ -z "$project_graph" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-graph-view)
      project_graph_view="${2:-}"
      if [ -z "$project_graph_view" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$project_graph" "$project_graph_view" "$control_plane" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
project_graph_path = Path(sys.argv[2])
project_graph_view_path = Path(sys.argv[3])
control_plane_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

graph = json.loads(project_graph_path.read_text(encoding="utf-8"))
view = json.loads(project_graph_view_path.read_text(encoding="utf-8"))
html = control_plane_path.read_text(encoding="utf-8")
summary = graph.get("summary", {})

tasks_total = int(summary.get("tasks_total", 0))
tasks_done = int(summary.get("tasks_done", 0))
validation_passed = int(summary.get("validation_passed", 0))
validation_failed = int(summary.get("validation_failed", 0))
human_gates = int(summary.get("validation_human_gate", 0))
events_total = int(summary.get("events_total", 0))
memory_zones = int(summary.get("memory_zones", 0))
nodes_total = int(summary.get("nodes_total", 0))
edges_total = int(summary.get("edges_total", 0))

required_tokens = [
    "project-brief-section",
    "project-brief-status",
    "project-brief-metrics",
    "project-brief-ready",
    "project-brief-human",
    "project-brief-next",
    "projectBriefSourceUrl",
    "renderProjectBrief",
    "loadProjectBriefSource",
]
missing_tokens = [token for token in required_tokens if token not in html]

required_files = [
    project_graph_path,
    project_graph_view_path,
    control_plane_path,
    Path("docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md"),
    Path("docs/exec-packs/done/TKT-056-artemis-project-brief.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

plain_status = (
    "O ARTEMIS Symphony esta pronto como sistema local supervisionado: ele organiza tarefas, evidencia, validacao, memoria e limites antes de qualquer execucao automatica."
)
if human_gates:
    plain_gate = f"Existem {human_gates} Human Gates ativos. Eles nao sao erro: sao pontos onde uma pessoa precisa decidir antes de rede, auth, custo, escrita remota ou cleanup real."
else:
    plain_gate = "Nao ha Human Gate tecnico aberto neste snapshot, mas decisoes sensiveis continuam exigindo aprovacao humana antes de execucao."

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-project-brief.sh",
    "mode": "read_only_human_project_brief",
    "overall": "human_project_brief_ready",
    "reason": "Human-readable Project Brief was derived from the Project Operations Graph.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "project_graph": str(project_graph_path),
        "project_graph_view": str(project_graph_view_path),
        "control_plane": str(control_plane_path),
    },
    "audience": [
        "human_collaborator",
        "project_owner",
        "codex",
        "claude_code",
    ],
    "summary": {
        "tasks_total": tasks_total,
        "tasks_done": tasks_done,
        "events_total": events_total,
        "nodes_total": nodes_total,
        "edges_total": edges_total,
        "validation_passed": validation_passed,
        "validation_failed": validation_failed,
        "human_gates": human_gates,
        "memory_zones": memory_zones,
        "dependencies_installed": 0,
        "commands_executed": 0,
        "runtime_started": False,
        "remote_writes_allowed": False,
        "source_of_truth_changed": False,
    },
    "brief": {
        "headline": "ARTEMIS Symphony em linguagem de projeto",
        "status": plain_status,
        "ready": [
            f"{tasks_done} de {tasks_total} Exec Packs estao concluidos e versionados.",
            f"O Validation Gate registra {validation_passed} checks aprovados e {validation_failed} falhas tecnicas.",
            f"O Project Graph conecta {nodes_total} nos e {edges_total} relacoes entre tarefas, agentes, gates, memoria, custos e evidencias.",
            f"A Memory Zone tem {memory_zones} zonas para contexto humano-AI versionado em Git.",
        ],
        "human_attention": [
            plain_gate,
            "O painel ajuda a entender o estado, mas nao aprova nem executa trabalho sensivel sozinho.",
            "Qualquer mudanca com producao, secrets, auth, push remoto, custo ou cleanup real continua passando por decisao humana explicita.",
        ],
        "next_actions": [
            "Usar este briefing como porta de entrada para pessoas que nao conhecem todos os artifacts.",
            "Abrir novos cortes somente como nova fase, com Exec Pack, risco, evidencia esperada e decisao humana necessaria.",
            "Usar o modo guiado e o Done Ledger como entrada para operacao supervisionada sem perder controle terminal-first.",
        ],
        "how_to_collaborate": [
            "Leia o briefing primeiro para entender o estado geral.",
            "Abra o Project Graph quando precisar ver relacoes tecnicas.",
            "Abra Exec Packs e artifacts quando precisar auditar a evidencia.",
            "Autorize apenas acoes concretas, reversiveis e bem delimitadas.",
        ],
        "limits": [
            "O briefing e explicacao, nao fonte de verdade.",
            "Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos.",
            "Nenhum agente, runner, bridge, fila, indexador ou banco e iniciado por este corte.",
            "Budget, tokens, auth e escrita remota precisam ser explicitos antes de runtime real.",
        ],
    },
    "missing_tokens": missing_tokens,
    "missing_files": missing_files,
    "required_tokens": required_tokens,
    "next_cut": "TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract",
}

brief_ready = (
    graph.get("overall") == "project_graph_ready"
    and view.get("overall") == "project_graph_view_ready"
    and not missing_tokens
    and not missing_files
    and validation_failed == 0
)
if not brief_ready:
    payload["overall"] = "failed"
    payload["reason"] = "Human-readable Project Brief contract is incomplete."

(artifact_root / "project-brief.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS PROJECT BRIEF STATUS",
    "",
    f"- Overall: `{payload['overall']}`",
    f"- Reason: {payload['reason']}",
    f"- Tasks done: `{tasks_done}` / `{tasks_total}`",
    f"- Validation passed: `{validation_passed}`",
    f"- Validation failed: `{validation_failed}`",
    f"- Human Gates: `{human_gates}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
    f"- Dependencies installed: `{payload['summary']['dependencies_installed']}`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS PROJECT BRIEF VALIDATION",
    "",
    f"- Project graph ready: `{str(graph.get('overall') == 'project_graph_ready').lower()}`",
    f"- Project graph view ready: `{str(view.get('overall') == 'project_graph_view_ready').lower()}`",
    f"- Required UI tokens present: `{str(not missing_tokens).lower()}`",
    f"- Required files present: `{str(not missing_files).lower()}`",
    f"- Technical validation failed: `{validation_failed}`",
    f"- Commands executed: `{payload['summary']['commands_executed']}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

brief_lines = [
    "# ARTEMIS PROJECT BRIEF",
    "",
    "## Em uma frase",
    "",
    payload["brief"]["status"],
    "",
    "## O que esta pronto",
    "",
]
brief_lines.extend(f"- {item}" for item in payload["brief"]["ready"])
brief_lines.extend(["", "## Onde precisa de humano", ""])
brief_lines.extend(f"- {item}" for item in payload["brief"]["human_attention"])
brief_lines.extend(["", "## Proximas acoes", ""])
brief_lines.extend(f"- {item}" for item in payload["brief"]["next_actions"])
brief_lines.extend(["", "## Como colaborar", ""])
brief_lines.extend(f"- {item}" for item in payload["brief"]["how_to_collaborate"])
brief_lines.extend(["", "## Limites", ""])
brief_lines.extend(f"- {item}" for item in payload["brief"]["limits"])
(artifact_root / "PROJECT_BRIEF.md").write_text("\n".join(brief_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS PROJECT BRIEF HANDOFF",
    "",
    "O briefing humano esta pronto como camada de explicacao do Project Operations Graph.",
    "",
    "Proximo corte:",
    "",
    "- Nenhum TKT planejado na espinha atual de runtime.",
    "- Abrir nova fase somente com Exec Pack explicito, objetivo, risco, evidencia e decisao humana.",
    "- Manter Done externo, PR, merge, deploy e aceite de produto como gates separados quando forem necessarios.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

brief_event = event(
    event_id="evt_tkt-056_project_brief",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "project_brief", "name": "scripts/artemis-project-brief.sh", "mode": "read_only"},
    ticket="TKT-056",
    title="Human-readable Project Brief do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-056-artemis-project-brief.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="done" if brief_ready else "blocked",
    severity="info" if brief_ready else "error",
    payload={
        "overall": payload["overall"],
        "reason": payload["reason"],
        "summary": payload["summary"],
        "next_cut": payload["next_cut"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-project-brief.sh", generated_at=generated_at, events=[brief_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Project Brief: {payload['overall']}")
    print(f"tasks={tasks_done}/{tasks_total} validation={validation_passed}/{validation_failed} human_gates={human_gates}")

if not brief_ready:
    raise SystemExit(1)
PY
