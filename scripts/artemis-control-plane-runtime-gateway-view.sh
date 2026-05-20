#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-control-plane-runtime-gateway-view/run-01"
control_plane="control-plane/index.html"
runtime_gateway_service="artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-control-plane-runtime-gateway-view.sh [--artifact-root path] [--control-plane path] [--runtime-gateway-service path] [--json]

Validates the Control Plane Runtime Gateway status view. It does not start
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
    --runtime-gateway-service)
      runtime_gateway_service="${2:-}"
      if [ -z "$runtime_gateway_service" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$control_plane" "$runtime_gateway_service" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
control_plane_path = Path(sys.argv[2])
service_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    control_plane_path,
    service_path,
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY_SERVICE.md"),
    Path("docs/exec-packs/done/TKT-084-artemis-portal-runtime-gateway-service.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
service_payload = json.loads(service_path.read_text(encoding="utf-8")) if service_path.is_file() else {}

required_tokens = [
    "runtime-gateway-overview",
    "runtime-gateway-title",
    "operator-strip",
    "runtimeGatewayServiceSourceUrl",
    "loadRuntimeGatewayServiceSource",
    "renderRuntimeGatewayService",
    "gateway-panel-can-start",
    "gateway-commands",
    "gateway-tokens",
]

operators = service_payload.get("service_contract", {}).get("operator_summary", [])
operator_ids = {item.get("operator_id") for item in operators}
readiness = service_payload.get("service_contract", {}).get("readiness", {})

checks = [
    {
        "id": "control_plane_tokens_present",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains the Runtime Gateway view, source URL, loader and renderer tokens.",
    },
    {
        "id": "runtime_gateway_service_ready",
        "status": "passed" if service_payload.get("overall") == "runtime_gateway_service_ready" else "failed",
        "detail": "Runtime Gateway Service artifact is ready for read-only consumption.",
    },
    {
        "id": "operator_cards_supported",
        "status": "passed" if operator_ids >= {"codex_app_server", "claude_code", "antigravity_cli"} else "failed",
        "detail": "Service exposes Codex app-server, Claude Code and Antigravity CLI for the panel.",
    },
    {
        "id": "panel_still_read_only",
        "status": "passed" if not readiness.get("panel_can_start_runtime", True) else "failed",
        "detail": "The rendered state must keep direct runtime launch disabled.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if service_payload.get("agents_started") is False and int(service_payload.get("commands_executed", 1)) == 0 and int(service_payload.get("tokens_spent", 1)) == 0 else "failed",
        "detail": "No agents, commands or tokens are produced by the view contract.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "control_plane_runtime_gateway_view_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "control_plane_runtime_gateway_view_ready": overall == "control_plane_runtime_gateway_view_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "http_server_started": False,
    "websocket_opened": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-086 - Runtime Gateway Project Selector Contract",
    "missing_files": missing_files,
    "view_contract": {
        "control_plane": str(control_plane_path),
        "runtime_gateway_service": str(service_path),
        "source_url": "../artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json",
        "operators_rendered": sorted(operator_ids),
        "panel_can_start_runtime": bool(readiness.get("panel_can_start_runtime", False)),
        "surface": "read_only_status_view",
    },
    "checks": checks,
}

(artifact_root / "control-plane-runtime-gateway-view.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Control Plane Runtime Gateway View",
    "",
    f"- Overall: `{overall}`",
    "- Surface: `read_only_status_view`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Rendered meaning",
    "",
    "The Control Plane now shows Runtime Gateway operator status in the simple view. Codex app-server and Claude Code appear as planned but not connected. Antigravity CLI appears as blocked until capability discovery.",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CONTROL_PLANE_RUNTIME_GATEWAY_VIEW.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Control Plane Runtime Gateway status view validated.",
        "- No runtime, provider auth, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Control Plane markup and JavaScript tokens checked.",
        "- Runtime Gateway Service artifact checked.",
        "- Operator list and read-only runtime invariant checked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-085 renders Runtime Gateway status in the Control Plane as read-only information.",
        "",
        "The next cut should define project selection before any authenticated runtime operation is introduced.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-control-plane-runtime-gateway-view.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_control_plane_runtime_gateway_view_ready",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "control_plane",
                "name": "scripts/artemis-control-plane-runtime-gateway-view.sh",
                "mode": "read_only",
            },
            ticket="TKT-085",
            title="ARTEMIS Control Plane Runtime Gateway Status View",
            exec_pack="docs/exec-packs/done/TKT-085-artemis-control-plane-runtime-gateway-view.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "control_plane_runtime_gateway_view_ready" else "blocked",
            payload={
                "control_plane_runtime_gateway_view_ready": overall == "control_plane_runtime_gateway_view_ready",
                "operators_rendered": len(operator_ids),
                "panel_can_start_runtime": bool(readiness.get("panel_can_start_runtime", False)),
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "control-plane-runtime-gateway-view.json"),
                str(artifact_root / "CONTROL_PLANE_RUNTIME_GATEWAY_VIEW.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS control plane runtime gateway view: {overall}")
    print(f"artifact_root={artifact_root}")
    print("agents_started=false")
    print("commands_executed=0")
PY
