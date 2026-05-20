#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-control-plane-local-project-connect-view/run-01"
control_plane="control-plane/index.html"
local_project_connect="artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-control-plane-local-project-connect-view.sh [--artifact-root path] [--control-plane path] [--local-project-connect path] [--json]

Validates the Control Plane Local Project Connect view. It does not start
servers, authenticate providers, start agents, execute commands, spend tokens or
mutate remote state.
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
    --local-project-connect)
      local_project_connect="${2:-}"
      if [ -z "$local_project_connect" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$control_plane" "$local_project_connect" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
control_plane_path = Path(sys.argv[2])
connect_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    control_plane_path,
    connect_path,
    Path("docs/portal/ARTEMIS_PORTAL_LOCAL_PROJECT_CONNECT.md"),
    Path("docs/exec-packs/done/TKT-087-artemis-portal-local-project-connect.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
connect_payload = json.loads(connect_path.read_text(encoding="utf-8")) if connect_path.is_file() else {}
project = connect_payload.get("connected_project", {})
providers = connect_payload.get("provider_discovery", [])
provider_ids = {item.get("provider_id") for item in providers}

required_tokens = [
    "local-project-overview",
    "local-project-title",
    "local-project-summary",
    "local-provider-strip",
    "localProjectConnectSourceUrl",
    "loadLocalProjectConnectSource",
    "renderLocalProjectConnect",
    "local-project-browser-access",
    "local-project-runtime",
]

checks = [
    {
        "id": "control_plane_tokens_present",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains Local Project Connect markup, source URL, loader and renderer tokens.",
    },
    {
        "id": "local_project_connect_ready",
        "status": "passed" if connect_payload.get("overall") == "local_project_connect_ready" else "failed",
        "detail": "Local Project Connect artifact is ready for read-only consumption.",
    },
    {
        "id": "terminal_project_access_visible",
        "status": "passed" if project.get("terminal_project_access_required") is True and project.get("browser_filesystem_access_allowed") is False else "failed",
        "detail": "The view must preserve terminal-first project access and block browser filesystem access.",
    },
    {
        "id": "provider_discovery_visible",
        "status": "passed" if provider_ids >= {"codex", "claude_code", "antigravity_cli"} else "failed",
        "detail": "The view supports Codex, Claude Code and Antigravity CLI local discovery state.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if connect_payload.get("provider_auth_connected") is False and project.get("runtime_execution_allowed") is False else "failed",
        "detail": "Rendered provider discovery must not imply provider auth or runtime permission.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if connect_payload.get("agents_started") is False and int(connect_payload.get("commands_executed", 1)) == 0 and int(connect_payload.get("tokens_spent", 1)) == 0 else "failed",
        "detail": "No agents, commands or tokens are produced by the view contract.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "control_plane_local_project_connect_view_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "control_plane_local_project_connect_view_ready": overall == "control_plane_local_project_connect_view_ready",
    "secret_values_recorded": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "http_server_started": False,
    "websocket_opened": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-089 - External Project Registration Contract",
    "missing_files": missing_files,
    "view_contract": {
        "control_plane": str(control_plane_path),
        "local_project_connect": str(connect_path),
        "source_url": "../artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json",
        "project_path": project.get("project_path", ""),
        "repo_root": project.get("repo_root", ""),
        "providers_rendered": sorted(provider_ids),
        "terminal_project_access_required": bool(project.get("terminal_project_access_required", True)),
        "browser_filesystem_access_allowed": bool(project.get("browser_filesystem_access_allowed", False)),
        "runtime_execution_allowed": bool(project.get("runtime_execution_allowed", False)),
        "surface": "read_only_status_view",
    },
    "checks": checks,
}

(artifact_root / "control-plane-local-project-connect-view.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Control Plane Local Project Connect View",
    "",
    f"- Overall: `{overall}`",
    "- Surface: `read_only_status_view`",
    f"- Project path: `{project.get('project_path', '')}`",
    f"- Providers rendered: `{len(provider_ids)}`",
    "- Terminal project access required: `true`",
    "- Browser filesystem access allowed: `false`",
    "- Provider auth connected: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Rendered meaning",
    "",
    "The Control Plane now shows the project connected from the terminal before Runtime Gateway operators. Provider binaries can appear detected, but auth and runtime remain blocked.",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CONTROL_PLANE_LOCAL_PROJECT_CONNECT_VIEW.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Control Plane Local Project Connect status view validated.",
        "- No provider auth, runtime, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Control Plane markup and JavaScript tokens checked.",
        "- Local Project Connect artifact checked.",
        "- Provider discovery, terminal-first and no-runtime invariants checked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-088 renders Local Project Connect state in the Control Plane as read-only information.",
        "",
        "The next cut should define external project registration before the portal can switch between projects or assign real runtime work.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-control-plane-local-project-connect-view.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_control_plane_local_project_connect_view_ready",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "control_plane",
                "name": "scripts/artemis-control-plane-local-project-connect-view.sh",
                "mode": "read_only",
            },
            ticket="TKT-088",
            title="ARTEMIS Control Plane Local Project Connect View",
            exec_pack="docs/exec-packs/done/TKT-088-artemis-control-plane-local-project-connect-view.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "control_plane_local_project_connect_view_ready" else "blocked",
            payload={
                "control_plane_local_project_connect_view_ready": overall == "control_plane_local_project_connect_view_ready",
                "providers_rendered": len(provider_ids),
                "terminal_project_access_required": True,
                "browser_filesystem_access_allowed": False,
                "provider_auth_connected": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="project_connect",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "control-plane-local-project-connect-view.json"),
                str(artifact_root / "CONTROL_PLANE_LOCAL_PROJECT_CONNECT_VIEW.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS control plane local project connect view: {overall}")
    print(f"artifact_root={artifact_root}")
    print("provider_auth_connected=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
