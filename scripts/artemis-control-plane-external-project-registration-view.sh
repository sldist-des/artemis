#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-control-plane-external-project-registration-view/run-01"
control_plane="control-plane/index.html"
external_project_registration="artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-control-plane-external-project-registration-view.sh [--artifact-root path] [--control-plane path] [--external-project-registration path] [--json]

Validates the Control Plane External Project Registration view. It does not
start servers, switch projects, authenticate providers, start agents, execute
commands, spend tokens or mutate remote state.
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
    --external-project-registration)
      external_project_registration="${2:-}"
      if [ -z "$external_project_registration" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$control_plane" "$external_project_registration" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
control_plane_path = Path(sys.argv[2])
registration_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    control_plane_path,
    registration_path,
    Path("docs/portal/ARTEMIS_PORTAL_EXTERNAL_PROJECT_REGISTRATION.md"),
    Path("docs/exec-packs/done/TKT-089-artemis-portal-external-project-registration.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
registration_payload = json.loads(registration_path.read_text(encoding="utf-8")) if registration_path.is_file() else {}
contract = registration_payload.get("external_project_registration_contract", {})
candidates = contract.get("candidate_projects", [])
registered = contract.get("registered_projects", [])
candidate_states = {item.get("registration_state") for item in candidates}
provider_auth_connected = registration_payload.get("provider_auth_connected", contract.get("provider_auth_connected", False))
runtime_execution_allowed = registration_payload.get("runtime_execution_allowed", contract.get("runtime_execution_allowed", False))

required_tokens = [
    "operations-overview",
    "operation-registration-title",
    "operation-registration-summary",
    "operation-candidate-strip",
    "externalProjectRegistrationSourceUrl",
    "loadExternalProjectRegistrationSource",
    "renderExternalProjectRegistration",
    "operation-registration-switching",
    "operation-registration-registered",
]

checks = [
    {
        "id": "control_plane_tokens_present",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains External Project Registration markup, source URL, loader and renderer tokens.",
    },
    {
        "id": "external_project_registration_ready",
        "status": "passed" if registration_payload.get("overall") == "external_project_registration_ready" else "failed",
        "detail": "External Project Registration artifact is ready for read-only consumption.",
    },
    {
        "id": "candidate_visible_without_registration",
        "status": "passed" if candidates and "candidate_from_terminal_connect" in candidate_states and not registered else "failed",
        "detail": "The view supports terminal-connect candidates without auto-registering projects.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if registration_payload.get("project_switching_allowed") is False else "failed",
        "detail": "Project switching remains blocked while candidates wait for review.",
    },
    {
        "id": "browser_and_scan_still_blocked",
        "status": "passed" if registration_payload.get("browser_filesystem_access_allowed") is False and registration_payload.get("server_scan_allowed") is False else "failed",
        "detail": "The view preserves no-browser-filesystem and no-server-scan boundaries.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if provider_auth_connected is False and runtime_execution_allowed is False else "failed",
        "detail": "Rendered registration state must not imply provider auth or runtime permission.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if registration_payload.get("agents_started") is False and int(registration_payload.get("commands_executed", 1)) == 0 and int(registration_payload.get("tokens_spent", 1)) == 0 else "failed",
        "detail": "No agents, commands or tokens are produced by the view contract.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "control_plane_external_project_registration_view_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "control_plane_external_project_registration_view_ready": overall == "control_plane_external_project_registration_view_ready",
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
    "external_projects_registered": int(registration_payload.get("external_projects_registered", 0)),
    "next_cut": "TKT-094 - Project Selector Registry Intake",
    "missing_files": missing_files,
    "view_contract": {
        "control_plane": str(control_plane_path),
        "external_project_registration": str(registration_path),
        "source_url": "../artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json",
        "candidate_count": len(candidates),
        "registered_count": len(registered),
        "candidate_states": sorted(item for item in candidate_states if item),
        "project_switching_allowed": False,
        "runtime_execution_allowed": False,
        "surface": "compact_read_only_status_view",
    },
    "checks": checks,
}

(artifact_root / "control-plane-external-project-registration-view.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Control Plane External Project Registration View",
    "",
    f"- Overall: `{overall}`",
    "- Surface: `read_only_status_view`",
    f"- Candidates rendered: `{len(candidates)}`",
    f"- External projects registered: `{payload['external_projects_registered']}`",
    "- Project switching allowed: `false`",
    "- Provider auth connected: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Rendered meaning",
    "",
    "The Control Plane now shows terminal-connected projects as registration candidates. A candidate is not selected, not registered for runtime and still requires human review.",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CONTROL_PLANE_EXTERNAL_PROJECT_REGISTRATION_VIEW.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Control Plane External Project Registration status view validated.",
        "- No project switching, provider auth, runtime, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Control Plane markup and JavaScript tokens checked.",
        "- External Project Registration artifact checked.",
        "- Candidate, no-switching, no-scan and no-runtime invariants checked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-090 renders External Project Registration candidate state in the Control Plane as read-only information.",
        "",
        "The next cut should let the Project Selector consume reviewed registry records without allowing runtime yet.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-control-plane-external-project-registration-view.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_control_plane_external_project_registration_view_ready",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "control_plane",
                "name": "scripts/artemis-control-plane-external-project-registration-view.sh",
                "mode": "read_only",
            },
            ticket="TKT-090",
            title="ARTEMIS Control Plane External Project Registration View",
            exec_pack="docs/exec-packs/done/TKT-090-artemis-control-plane-external-project-registration-view.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "control_plane_external_project_registration_view_ready" else "blocked",
            payload={
                "control_plane_external_project_registration_view_ready": overall == "control_plane_external_project_registration_view_ready",
                "candidate_count": len(candidates),
                "external_projects_registered": payload["external_projects_registered"],
                "project_switching_allowed": False,
                "provider_auth_connected": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="external_project_registration",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "control-plane-external-project-registration-view.json"),
                str(artifact_root / "CONTROL_PLANE_EXTERNAL_PROJECT_REGISTRATION_VIEW.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS control plane external project registration view: {overall}")
    print(f"artifact_root={artifact_root}")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
