#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-project-graph-view/run-01"
project_graph="artifacts/artemis-project-graph/run-01/project-graph.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-project-graph-view.sh [--artifact-root path] [--project-graph path] [--control-plane path] [--json]

Validates and records the read-only Project Graph View contract. It does not
start a server, install dependencies, execute agents, or promote the Control
Plane to source of truth.
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

python3 - "$artifact_root" "$project_graph" "$control_plane" "$format" <<'PY'
import json
import sys
from pathlib import Path
from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
project_graph_path = Path(sys.argv[2])
control_plane_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

graph = json.loads(project_graph_path.read_text(encoding="utf-8"))
html = control_plane_path.read_text(encoding="utf-8")

required_tokens = [
    "project-graph-section",
    "project-graph-map",
    "project-graph-relations",
    "project-graph-brief",
    "projectGraphSourceUrl",
    "renderProjectGraph",
    "loadProjectGraphSource",
]

missing_tokens = [token for token in required_tokens if token not in html]
summary = graph.get("summary", {})
nodes = graph.get("nodes", [])
edges = graph.get("edges", [])
questions = graph.get("questions", [])
invariants = graph.get("invariants", [])

view_ready = (
    graph.get("overall") == "project_graph_ready"
    and not missing_tokens
    and len(nodes) >= 10
    and len(edges) >= 12
)

overall = "project_graph_view_ready" if view_ready else "failed"
reason = (
    "Project Graph View renders the read-only graph in the Control Plane."
    if view_ready
    else "Project Graph View contract is incomplete."
)

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-project-graph-view.sh",
    "mode": "read_only_control_plane_view_contract",
    "overall": overall,
    "reason": reason,
    "artifact_root": str(artifact_root),
    "inputs": {
        "project_graph": str(project_graph_path),
        "control_plane": str(control_plane_path),
    },
    "summary": {
        "nodes_rendered": len(nodes),
        "edges_rendered": len(edges),
        "questions_rendered": min(len(questions), 3),
        "invariants_rendered": min(len(invariants), 3),
        "validation_passed": summary.get("validation_passed", 0),
        "human_gates": summary.get("validation_human_gate", 0),
        "dependencies_installed": 0,
        "commands_executed": 0,
        "runtime_started": False,
        "remote_writes_allowed": False,
        "source_of_truth_changed": False,
    },
    "missing_tokens": missing_tokens,
    "required_tokens": required_tokens,
    "invariants": [
        "Control Plane is observational, not canonical.",
        "Project Graph View reads local graph artifacts only.",
        "No graph database, canvas engine, frontend framework or runtime is introduced.",
        "Human Gates, Validation Gate, Event Log, Exec Packs and git remain authoritative.",
    ],
    "next_cut": "TKT-057 - Guided Human Collaboration Mode do ARTEMIS Symphony",
}

(artifact_root / "project-graph-view.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS PROJECT GRAPH VIEW STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Reason: {reason}",
    f"- Nodes rendered: `{payload['summary']['nodes_rendered']}`",
    f"- Edges rendered: `{payload['summary']['edges_rendered']}`",
    f"- Questions rendered: `{payload['summary']['questions_rendered']}`",
    f"- Invariants rendered: `{payload['summary']['invariants_rendered']}`",
    f"- Dependencies installed: `{payload['summary']['dependencies_installed']}`",
    f"- Commands executed: `{payload['summary']['commands_executed']}`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS PROJECT GRAPH VIEW VALIDATION",
    "",
    f"- Project graph ready: `{str(graph.get('overall') == 'project_graph_ready').lower()}`",
    f"- Required UI tokens present: `{str(not missing_tokens).lower()}`",
    f"- Nodes >= 10: `{str(len(nodes) >= 10).lower()}`",
    f"- Edges >= 12: `{str(len(edges) >= 12).lower()}`",
    f"- Runtime started: `{str(payload['summary']['runtime_started']).lower()}`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS PROJECT GRAPH VIEW HANDOFF",
    "",
    "Project Graph View esta pronto como leitura visual no Control Plane.",
    "",
    "Próximo corte:",
    "",
    "- Implementar `TKT-057 - Guided Human Collaboration Mode do ARTEMIS Symphony`.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

view_event = event(
    event_id="evt_tkt-055_project_graph_view",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "project_graph_view", "name": "scripts/artemis-project-graph-view.sh", "mode": "read_only"},
    ticket="TKT-055",
    title="Project Graph View do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-055-artemis-project-graph-view.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="done" if view_ready else "blocked",
    severity="info" if view_ready else "error",
    payload={
        "overall": overall,
        "reason": reason,
        "summary": payload["summary"],
        "next_cut": payload["next_cut"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-project-graph-view.sh", generated_at=generated_at, events=[view_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Project Graph View: {overall}")
    print(f"nodes={len(nodes)} edges={len(edges)} questions={len(questions)}")

if not view_ready:
    raise SystemExit(1)
PY
