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
runtime_approval_gate_path="artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json"
runtime_decision_intake_path="artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json"
runtime_launcher_preflight_path="artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json"
runtime_launcher_command_plan_path="artifacts/artemis-agent-runtime-launcher-command-plan/run-01/launcher-command-plan.json"
runtime_launcher_execution_gate_path="artifacts/artemis-agent-runtime-launcher-execution-gate/run-01/launcher-execution-gate.json"
runtime_launcher_supervised_execution_path="artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json"
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
runtime_approval_gate_payload = read_json(Path("artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json"), {"summary": {}, "overall": "not_available"})
runtime_decision_intake_payload = read_json(Path("artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json"), {"summary": {}, "overall": "not_available"})
runtime_launcher_preflight_payload = read_json(Path("artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json"), {"summary": {}, "overall": "not_available"})
runtime_launcher_command_plan_payload = read_json(Path("artifacts/artemis-agent-runtime-launcher-command-plan/run-01/launcher-command-plan.json"), {"summary": {}, "overall": "not_available"})
runtime_launcher_execution_gate_payload = read_json(Path("artifacts/artemis-agent-runtime-launcher-execution-gate/run-01/launcher-execution-gate.json"), {"summary": {}, "overall": "not_available"})
runtime_launcher_supervised_execution_payload = read_json(Path("artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json"), {"summary": {}, "overall": "not_available"})

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
        "id": "runtime:approval_gate",
        "type": "human_gate",
        "label": "Agent Runtime Approval Gate",
        "status": runtime_approval_gate_payload.get("overall", "not_available"),
        "decision": runtime_approval_gate_payload.get("summary", {}).get("decision", "unknown"),
        "runtime_execution_allowed": runtime_approval_gate_payload.get("summary", {}).get("runtime_execution_allowed", False),
    },
    {
        "id": "runtime:decision_intake",
        "type": "human_gate",
        "label": "Agent Runtime Decision Intake",
        "status": runtime_decision_intake_payload.get("overall", "not_available"),
        "intake_state": runtime_decision_intake_payload.get("intake_state", "unknown"),
        "launcher_preflight_allowed": runtime_decision_intake_payload.get("summary", {}).get("launcher_preflight_allowed", False),
    },
    {
        "id": "runtime:launcher_preflight",
        "type": "runtime_preflight",
        "label": "Agent Runtime Launcher Preflight",
        "status": runtime_launcher_preflight_payload.get("overall", "not_available"),
        "preflight_state": runtime_launcher_preflight_payload.get("preflight_state", "unknown"),
        "launcher_execution_allowed": runtime_launcher_preflight_payload.get("summary", {}).get("launcher_execution_allowed", False),
    },
    {
        "id": "runtime:launcher_command_plan",
        "type": "runtime_command_plan",
        "label": "Agent Runtime Launcher Command Plan",
        "status": runtime_launcher_command_plan_payload.get("overall", "not_available"),
        "plan_state": runtime_launcher_command_plan_payload.get("plan_state", "unknown"),
        "planned_commands": runtime_launcher_command_plan_payload.get("summary", {}).get("planned_commands_count", 0),
        "launcher_execution_allowed": runtime_launcher_command_plan_payload.get("summary", {}).get("launcher_execution_allowed", False),
    },
    {
        "id": "runtime:launcher_execution_gate",
        "type": "runtime_execution_gate",
        "label": "Agent Runtime Launcher Execution Gate",
        "status": runtime_launcher_execution_gate_payload.get("overall", "not_available"),
        "gate_state": runtime_launcher_execution_gate_payload.get("gate_state", "unknown"),
        "execution_gate_ready": runtime_launcher_execution_gate_payload.get("summary", {}).get("execution_gate_ready", False),
        "launcher_execution_allowed": runtime_launcher_execution_gate_payload.get("summary", {}).get("launcher_execution_allowed", False),
        "runtime_execution_allowed": runtime_launcher_execution_gate_payload.get("summary", {}).get("runtime_execution_allowed", False),
        "commands_executed": runtime_launcher_execution_gate_payload.get("summary", {}).get("commands_executed", 0),
    },
    {
        "id": "runtime:launcher_supervised_execution",
        "type": "runtime_supervised_execution",
        "label": "Agent Runtime Launcher Supervised Execution",
        "status": runtime_launcher_supervised_execution_payload.get("overall", "not_available"),
        "execution_state": runtime_launcher_supervised_execution_payload.get("execution_state", "unknown"),
        "execute_requested": runtime_launcher_supervised_execution_payload.get("summary", {}).get("execute_requested", False),
        "supervised_execution_ready": runtime_launcher_supervised_execution_payload.get("summary", {}).get("supervised_execution_ready", False),
        "runtime_started": runtime_launcher_supervised_execution_payload.get("summary", {}).get("runtime_started", False),
        "agents_started": runtime_launcher_supervised_execution_payload.get("summary", {}).get("agents_started", 0),
        "commands_executed": runtime_launcher_supervised_execution_payload.get("summary", {}).get("commands_executed", 0),
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
    {"from": "runtime:dry_run", "to": "runtime:approval_gate", "type": "requests_human_decision"},
    {"from": "runtime:approval_gate", "to": "gate:human", "type": "opens"},
    {"from": "runtime:approval_gate", "to": "cost:budget", "type": "requires_budget_approval"},
    {"from": "runtime:approval_gate", "to": "runtime:decision_intake", "type": "feeds_decision"},
    {"from": "runtime:decision_intake", "to": "validation:gate", "type": "requires_validation"},
    {"from": "runtime:decision_intake", "to": "cost:budget", "type": "preserves_budget_limits"},
    {"from": "runtime:decision_intake", "to": "runtime:launcher_preflight", "type": "gates_preflight"},
    {"from": "runtime:launcher_preflight", "to": "validation:gate", "type": "rechecks"},
    {"from": "runtime:launcher_preflight", "to": "cost:budget", "type": "keeps_execution_blocked"},
    {"from": "runtime:launcher_preflight", "to": "runtime:launcher_command_plan", "type": "gates_command_plan"},
    {"from": "runtime:launcher_command_plan", "to": "validation:gate", "type": "declares_validation"},
    {"from": "runtime:launcher_command_plan", "to": "cost:budget", "type": "keeps_execution_blocked"},
    {"from": "runtime:launcher_command_plan", "to": "runtime:launcher_execution_gate", "type": "gates_execution"},
    {"from": "runtime:launcher_execution_gate", "to": "gate:human", "type": "requires_final_human_confirmation"},
    {"from": "runtime:launcher_execution_gate", "to": "validation:gate", "type": "requires_validation"},
    {"from": "runtime:launcher_execution_gate", "to": "cost:budget", "type": "binds_runtime_budget"},
    {"from": "runtime:launcher_execution_gate", "to": "runtime:launcher_supervised_execution", "type": "gates_supervised_execution"},
    {"from": "runtime:launcher_supervised_execution", "to": "validation:gate", "type": "produces_validation_evidence"},
    {"from": "runtime:launcher_supervised_execution", "to": "cost:budget", "type": "spends_budget_only_when_ready"},
    {"from": "runtime:launcher_supervised_execution", "to": "event_log:timeline", "type": "records_results"},
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
        "runtime_decision_intake": "artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json",
        "runtime_launcher_preflight": "artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json",
        "runtime_launcher_command_plan": "artifacts/artemis-agent-runtime-launcher-command-plan/run-01/launcher-command-plan.json",
        "runtime_launcher_execution_gate": "artifacts/artemis-agent-runtime-launcher-execution-gate/run-01/launcher-execution-gate.json",
        "runtime_launcher_supervised_execution": "artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json",
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
        "runtime_approval_input": "artemis_agent_runtime_approval_gate",
        "runtime_decision_input": "artemis_agent_runtime_decision_intake",
        "runtime_launcher_preflight_input": "artemis_agent_runtime_launcher_preflight",
        "runtime_launcher_command_plan_input": "artemis_agent_runtime_launcher_command_plan",
        "runtime_launcher_execution_gate_input": "artemis_agent_runtime_launcher_execution_gate",
        "runtime_launcher_supervised_execution_input": "artemis_agent_runtime_launcher_supervised_execution",
        "control_plane_role": "observational_graph_consumer",
        "runtime_policy": "no_runtime_without_explicit_human_gate",
    },
    "next_cut": "TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony",
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
    "- Implementar `TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony`.",
    "- Usar o Launcher Supervised Execution como entrada obrigatoria para interpretar resultados de runtime.",
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
