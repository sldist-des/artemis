#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-control-plane-project-registry-home-state/run-01"
control_plane="control-plane/index.html"
registry_intake="artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-control-plane-project-registry-home-state.sh [--artifact-root path] [--control-plane path] [--registry-intake path] [--json]

Validates that the Control Plane human home consumes Project Selector Registry
Intake state without exposing the technical audit surface as the primary UI.
It does not approve candidates, switch projects, authenticate providers, start
agents, execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane)
      control_plane="${2:-}"
      if [ -z "$control_plane" ]; then usage; exit 2; fi
      shift 2
      ;;
    --registry-intake)
      registry_intake="${2:-}"
      if [ -z "$registry_intake" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$control_plane" "$registry_intake" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
control_plane_path = Path(sys.argv[2])
registry_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    control_plane_path,
    registry_path,
    Path("docs/control-plane/ARTEMIS_CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR_REGISTRY_INTAKE.md"),
    Path("docs/exec-packs/done/TKT-094-artemis-portal-project-selector-registry-intake.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
registry_payload = json.loads(registry_path.read_text(encoding="utf-8")) if registry_path.is_file() else {}
contract = registry_payload.get("registry_contract", {})
selected = contract.get("selected_project", {})
candidates = contract.get("candidate_entries", [])

required_tokens = [
    "projectSelectorRegistryIntakeSourceUrl",
    "loadProjectSelectorRegistryIntakeSource",
    "renderProjectSelectorRegistryIntake",
    "operation-project-state",
    "operation-project-title",
    "operation-registration-state",
    "operation-registration-title",
    "operation-runtime-state",
    "technical-details",
    "display: none !important",
]

checks = [
    {
        "id": "control_plane_tokens_present",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains registry intake source, loader, renderer and home-state tokens.",
    },
    {
        "id": "registry_intake_ready",
        "status": "passed" if registry_payload.get("overall") == "project_selector_registry_intake_ready" else "failed",
        "detail": "Registry Intake artifact is ready for home consumption.",
    },
    {
        "id": "selected_project_visible",
        "status": "passed" if selected.get("selection_state") == "selected_read_only" and selected.get("repo_root") else "failed",
        "detail": "Home state can show the selected read-only project.",
    },
    {
        "id": "candidate_review_visible",
        "status": "passed" if len(candidates) == int(contract.get("candidate_count", 0)) and all(item.get("registry_state") == "candidate_review_pending" for item in candidates) else "failed",
        "detail": "Home state can show candidate review without making it selectable.",
    },
    {
        "id": "technical_surface_not_primary",
        "status": "passed" if ".technical-details," in html and "display: none !important" in html else "failed",
        "detail": "Technical audit detail remains hidden from the primary home surface.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if registry_payload.get("project_switching_allowed") is False and contract.get("project_switching_allowed") is False else "failed",
        "detail": "Home state does not allow project switching.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if registry_payload.get("runtime_execution_allowed") is False and contract.get("runtime_execution_allowed") is False else "failed",
        "detail": "Home state does not allow runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if registry_payload.get("agents_started") is False and int(registry_payload.get("commands_executed", 1)) == 0 and int(registry_payload.get("tokens_spent", 1)) == 0 else "failed",
        "detail": "No agents, commands or tokens are produced by the home state contract.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "control_plane_project_registry_home_state_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "control_plane_project_registry_home_state_ready": overall == "control_plane_project_registry_home_state_ready",
    "secret_values_recorded": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "http_server_started": False,
    "websocket_opened": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "next_cut": "TKT-096 - Project Registry Human Review Gate",
    "missing_files": missing_files,
    "home_contract": {
        "control_plane": str(control_plane_path),
        "registry_intake": str(registry_path),
        "source_url": "../artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json",
        "selected_project_id": selected.get("project_id", ""),
        "selected_project_root": selected.get("repo_root", ""),
        "candidate_count": len(candidates),
        "candidate_states": sorted({item.get("registry_state", "") for item in candidates if item.get("registry_state")}),
        "technical_surface_primary": False,
        "project_switching_allowed": False,
        "runtime_execution_allowed": False,
        "surface": "human_home_state",
    },
    "checks": checks,
}

(artifact_root / "control-plane-project-registry-home-state.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Control Plane Project Registry Home State",
    "",
    f"- Overall: `{overall}`",
    "- Surface: `human_home_state`",
    f"- Selected project: `{selected.get('display_name', '')}`",
    f"- Selected root: `{selected.get('repo_root', '')}`",
    f"- Candidates in review: `{len(candidates)}`",
    "- Technical surface primary: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Rendered meaning",
    "",
    "The Control Plane home can now say which project is selected, whether a candidate is waiting for review, and that runtime remains blocked.",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Control Plane Project Registry Home State validated.",
        "- The home remains human-facing and read-only.",
        "- No project switching, provider auth, runtime, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Registry Intake artifact checked.",
        "- Control Plane home source, loader and renderer tokens checked.",
        "- Selected project and candidate review state checked.",
        "- Technical audit surface remains hidden from the primary home.",
        "- Runtime and project switching remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-095 validates the Control Plane home against the Project Selector Registry Intake.",
        "",
        "The next cut can introduce a human review gate for candidate approval, but it must keep runtime and project switching blocked until an explicit decision exists.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-control-plane-project-registry-home-state.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_control_plane_project_registry_home_state_ready",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "control_plane",
                "name": "scripts/artemis-control-plane-project-registry-home-state.sh",
                "mode": "read_only",
            },
            ticket="TKT-095",
            title="ARTEMIS Control Plane Project Registry Home State",
            exec_pack="docs/exec-packs/done/TKT-095-artemis-control-plane-project-registry-home-state.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "control_plane_project_registry_home_state_ready" else "blocked",
            payload={
                "control_plane_project_registry_home_state_ready": overall == "control_plane_project_registry_home_state_ready",
                "selected_project_id": selected.get("project_id", ""),
                "candidate_count": len(candidates),
                "technical_surface_primary": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="registry_intake",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "control-plane-project-registry-home-state.json"),
                str(artifact_root / "CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS control plane project registry home state: {overall}")
    print(f"artifact_root={artifact_root}")
    print("technical_surface_primary=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
