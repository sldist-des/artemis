#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-project-graph/run-01"
tasks_path="control-plane/tasks.json"
event_log_path="artifacts/artemis-event-log/run-01/event-log.example.json"
memory_zone_path="artifacts/artemis-memory-zone/run-01/memory-zone.json"
validation_gate_path="artifacts/artemis-validation-gate/run-01/validation-gate.json"
runtime_dry_run_path="artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-project-graph.sh [--artifact-root path] [--tasks path] [--event-log path] [--memory-zone path] [--validation-gate path] [--json]

Records the ARTEMIS Project Operations Graph contract. This is a read-only
architecture cut: it does not install graph databases, vector stores,
embeddings, indexers, agents, or background runtimes.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --tasks)
      tasks_path="${2:-}"
      if [ -z "$tasks_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --event-log)
      event_log_path="${2:-}"
      if [ -z "$event_log_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --memory-zone)
      memory_zone_path="${2:-}"
      if [ -z "$memory_zone_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --validation-gate)
      validation_gate_path="${2:-}"
      if [ -z "$validation_gate_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$tasks_path" "$event_log_path" "$memory_zone_path" "$validation_gate_path" "$format" <<'PY'
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

artifact_root = Path(sys.argv[1])
tasks_path = Path(sys.argv[2])
event_log_path = Path(sys.argv[3])
memory_zone_path = Path(sys.argv[4])
validation_gate_path = Path(sys.argv[5])
output_format = sys.argv[6]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return default


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


generated_at = now_utc()
artifact_root.mkdir(parents=True, exist_ok=True)

required_files = [
    Path("docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md"),
    Path("docs/symphony/ARTEMIS_SYMPHONY_SPEC.md"),
    Path("docs/memory/ARTEMIS_MEMORY_ZONE.md"),
    Path("AGENTS.md"),
    Path("ARTEMIS_WORKFLOW.md"),
    tasks_path,
    event_log_path,
    memory_zone_path,
    validation_gate_path,
]
missing_files = [str(path) for path in required_files if not path.is_file()]

tasks_payload = read_json(tasks_path, {"tasks": []})
event_log_payload = read_json(event_log_path, {"events": []})
memory_payload = read_json(memory_zone_path, {"summary": {}, "zones": []})
validation_payload = read_json(validation_gate_path, {"summary": {}})
runtime_dry_run_payload = read_json(Path("artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json"), {"summary": {}, "overall": "not_available"})

tasks = tasks_payload.get("tasks", [])
events = event_log_payload.get("events", [])
states = Counter(task.get("state", "unknown") for task in tasks)
owners = Counter(task.get("owner", "unknown") for task in tasks)
risks = Counter(task.get("risk", "unknown") for task in tasks)
tags = Counter(tag for task in tasks for tag in task.get("tags", []))

evidence_count = sum(1 for task in tasks if task.get("evidence"))
exec_pack_count = sum(1 for task in tasks if task.get("exec_pack"))
validation_summary = validation_payload.get("summary", {})
memory_summary = memory_payload.get("summary", {})

nodes = [
    {
        "id": "project:artemis",
        "type": "project",
        "label": "ARTEMIS",
        "authority": "git_repository",
        "status": "operational",
    },
    {
        "id": "task_set:exec_packs",
        "type": "task_set",
        "label": "Exec Packs",
        "count": len(tasks),
        "done": states.get("done", 0),
        "human": states.get("human", 0),
    },
    {
        "id": "agent_roles:owners",
        "type": "agent_roles",
        "label": "Owners and agent roles",
        "count": len(owners),
        "top": owners.most_common(5),
    },
    {
        "id": "gate:human",
        "type": "gate",
        "label": "Human Gates",
        "count": validation_summary.get("human_gate", 0),
        "authority": "human_decision",
    },
    {
        "id": "validation:gate",
        "type": "validation",
        "label": "Validation Gate",
        "passed": validation_summary.get("passed", 0),
        "failed": validation_summary.get("failed", 0),
    },
    {
        "id": "memory:zone",
        "type": "memory",
        "label": "Human-AI Memory Zone",
        "zones": memory_summary.get("zones_total", len(memory_payload.get("zones", []))),
        "source_of_truth": "markdown_git_artifacts",
    },
    {
        "id": "artifact:evidence",
        "type": "artifact_set",
        "label": "Artifacts and evidence",
        "task_evidence": evidence_count,
        "exec_packs": exec_pack_count,
    },
    {
        "id": "event_log:timeline",
        "type": "event_log",
        "label": "Canonical event timeline",
        "events": len(events),
    },
    {
        "id": "cost:budget",
        "type": "cost_guard",
        "label": "Token and runtime budget",
        "runtime_started": False,
        "dependencies_installed": 0,
    },
    {
        "id": "runtime:dry_run",
        "type": "runtime_plan",
        "label": "Agent Runtime Dry-Run",
        "status": runtime_dry_run_payload.get("overall", "not_available"),
        "agents_started": runtime_dry_run_payload.get("summary", {}).get("agents_started", 0),
        "commands_executed": runtime_dry_run_payload.get("summary", {}).get("commands_executed", 0),
    },
    {
        "id": "control_plane:view",
        "type": "view",
        "label": "Control Plane",
        "authority": "observational",
    },
]

edges = [
    {"from": "project:artemis", "to": "task_set:exec_packs", "type": "contains"},
    {"from": "task_set:exec_packs", "to": "artifact:evidence", "type": "requires_evidence"},
    {"from": "task_set:exec_packs", "to": "agent_roles:owners", "type": "assigned_to"},
    {"from": "task_set:exec_packs", "to": "gate:human", "type": "blocked_by_when_sensitive"},
    {"from": "validation:gate", "to": "task_set:exec_packs", "type": "verifies"},
    {"from": "memory:zone", "to": "task_set:exec_packs", "type": "provides_context"},
    {"from": "memory:zone", "to": "event_log:timeline", "type": "summarizes_history"},
    {"from": "event_log:timeline", "to": "artifact:evidence", "type": "records"},
    {"from": "cost:budget", "to": "agent_roles:owners", "type": "constrains_runtime"},
    {"from": "runtime:dry_run", "to": "cost:budget", "type": "declares_budget"},
    {"from": "runtime:dry_run", "to": "validation:gate", "type": "requires_preflight"},
    {"from": "control_plane:view", "to": "project:artemis", "type": "observes"},
    {"from": "control_plane:view", "to": "validation:gate", "type": "shows"},
    {"from": "control_plane:view", "to": "memory:zone", "type": "shows"},
]

questions = [
    {
        "question": "Como esta o projeto?",
        "answer_source": ["task_set:exec_packs", "validation:gate", "event_log:timeline"],
    },
    {
        "question": "Quem esta responsavel pelo que?",
        "answer_source": ["agent_roles:owners", "task_set:exec_packs"],
    },
    {
        "question": "O que depende de decisao humana?",
        "answer_source": ["gate:human", "validation:gate"],
    },
    {
        "question": "Qual contexto e seguro para agentes?",
        "answer_source": ["memory:zone", "artifact:evidence"],
    },
    {
        "question": "Qual custo ou runtime foi ativado?",
        "answer_source": ["cost:budget"],
    },
]

summary = {
    "tasks_total": len(tasks),
    "tasks_done": states.get("done", 0),
    "tasks_human": states.get("human", 0),
    "tasks_ready": states.get("ready", 0),
    "owners_total": len(owners),
    "events_total": len(events),
    "nodes_total": len(nodes),
    "edges_total": len(edges),
    "evidence_count": evidence_count,
    "exec_pack_count": exec_pack_count,
    "validation_passed": validation_summary.get("passed", 0),
    "validation_failed": validation_summary.get("failed", 0),
    "validation_human_gate": validation_summary.get("human_gate", 0),
    "memory_zones": memory_summary.get("zones_total", len(memory_payload.get("zones", []))),
    "dependencies_installed": 0,
    "graph_database_started": False,
    "embeddings_created": 0,
    "commands_executed": 0,
    "remote_writes_allowed": False,
    "runner_auto_execution_allowed": False,
}

overall = "project_graph_ready" if not missing_files else "failed"
reason = "Project Operations Graph contract is ready." if not missing_files else "Missing required files: " + ", ".join(missing_files)

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-project-graph.sh",
    "mode": "read_only_project_graph_contract",
    "overall": overall,
    "reason": reason,
    "artifact_root": str(artifact_root),
    "inputs": {
        "tasks": str(tasks_path),
        "event_log": str(event_log_path),
        "memory_zone": str(memory_zone_path),
        "validation_gate": str(validation_gate_path),
    },
    "summary": summary,
    "states": dict(states),
    "risks": dict(risks),
    "top_owners": owners.most_common(10),
    "top_tags": tags.most_common(10),
    "nodes": nodes,
    "edges": edges,
    "questions": questions,
    "invariants": [
        "Project Operations Graph is a read model, not execution authority.",
        "Exec Packs, artifacts, event logs and git remain canonical.",
        "Graph edges must be explainable by local evidence.",
        "Human Gates and Validation Gate remain non-bypassable.",
        "Budget and token costs must be explicit before runtime automation.",
        "No graph database, embeddings, indexer or agent runtime is started in this cut.",
    ],
    "contracts": {
        "source_of_truth": "git_versioned_artemis_files",
        "graph_role": "operational_read_model",
        "memory_input": "artemis_memory_zone",
        "validation_input": "artemis_validation_gate",
        "runtime_input": "artemis_agent_runtime_dry_run",
        "control_plane_role": "observational_graph_consumer",
        "runtime_policy": "no_runtime_without_explicit_human_gate",
    },
    "next_cut": "TKT-060 - Agent Runtime Approval Gate do ARTEMIS Symphony",
}

write_text(artifact_root / "project-graph.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

graph_lines = [
    "# PROJECT OPERATIONS GRAPH",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Reason: {reason}",
    f"- Nodes: `{summary['nodes_total']}`.",
    f"- Edges: `{summary['edges_total']}`.",
    f"- Tasks: `{summary['tasks_total']}`.",
    f"- Events: `{summary['events_total']}`.",
    "",
    "## Nos",
    "",
]
for node in nodes:
    graph_lines.append(f"- `{node['id']}` ({node['type']}): {node['label']}.")
graph_lines.extend(["", "## Arestas", ""])
for edge in edges:
    graph_lines.append(f"- `{edge['from']}` --{edge['type']}--> `{edge['to']}`.")
graph_lines.extend(["", "## Perguntas operacionais", ""])
for item in questions:
    graph_lines.append(f"- {item['question']}")
write_text(artifact_root / "GRAPH.md", "\n".join(graph_lines).rstrip() + "\n")

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Tasks total: `{summary['tasks_total']}`.",
    f"- Tasks done: `{summary['tasks_done']}`.",
    f"- Nodes: `{summary['nodes_total']}`.",
    f"- Edges: `{summary['edges_total']}`.",
    f"- Validation passed: `{summary['validation_passed']}`.",
    f"- Validation failed: `{summary['validation_failed']}`.",
    f"- Human Gate checks: `{summary['validation_human_gate']}`.",
    f"- Memory zones: `{summary['memory_zones']}`.",
    f"- Graph database started: `{str(summary['graph_database_started']).lower()}`.",
    f"- Dependencies installed: `{summary['dependencies_installed']}`.",
    "",
    "## Invariantes",
    "",
]
status_lines.extend(f"- {item}" for item in payload["invariants"])
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Missing files: `{len(missing_files)}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`.",
    f"- Runner auto execution allowed: `{str(summary['runner_auto_execution_allowed']).lower()}`.",
    "",
    "## Comandos",
    "",
    f"- `scripts/artemis-project-graph.sh --artifact-root {artifact_root} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
]
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Project Operations Graph esta `{overall}` como read model operacional. Ele conecta tarefas, agentes, gates, validacao, memoria, custos e artifacts sem iniciar runtime.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-060 - Agent Runtime Approval Gate do ARTEMIS Symphony`.",
    "- Renderizar relacoes do grafo no Control Plane com linguagem operacional e leiga.",
    "",
    "## Nao fazer",
    "",
    "- Nao tratar grafo como fonte de verdade.",
    "- Nao iniciar banco de grafo, embeddings, indexador ou agentes sem Human Gate.",
    "- Nao bypassar Exec Pack, Validation Gate ou Human Gate por causa de arestas derivadas.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

events_out = [
    event(
        event_id="evt_tkt-054_project_graph",
        event_type="adapter.contract_recorded",
        generated_at=generated_at,
        producer={"adapter": "project_graph", "name": "scripts/artemis-project-graph.sh", "mode": "read_only"},
        ticket="TKT-054",
        title="Project Operations Graph do ARTEMIS Symphony",
        exec_pack="docs/exec-packs/done/TKT-054-artemis-project-graph.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="done" if overall == "project_graph_ready" else "blocked",
        runner={"kind": "none"},
        severity="info" if overall == "project_graph_ready" else "error",
        payload={
            "overall": overall,
            "reason": reason,
            "summary": summary,
            "next_cut": payload["next_cut"],
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-project-graph.sh", generated_at=generated_at, events=events_out))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Project Operations Graph: {overall}")
    print(
        "summary: "
        f"tasks={summary['tasks_total']} "
        f"nodes={summary['nodes_total']} "
        f"edges={summary['edges_total']} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
