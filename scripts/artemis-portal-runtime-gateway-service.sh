#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-runtime-gateway-service/run-01"
gateway_contract="artifacts/artemis-portal-runtime-gateway/run-01/runtime-gateway-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-runtime-gateway-service.sh [--artifact-root path] [--gateway-contract path] [--json]

Builds the ARTEMIS Portal Runtime Gateway read-only service contract. It does
not start a server, open sockets, accept POST requests, authenticate providers,
start agents, execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --gateway-contract)
      gateway_contract="${2:-}"
      if [ -z "$gateway_contract" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$gateway_contract" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
gateway_contract_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY.md"),
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY_SERVICE.md"),
    Path("docs/exec-packs/done/TKT-083-artemis-portal-runtime-gateway.md"),
    Path("artifacts/artemis-portal-runtime-gateway/run-01/runtime-gateway-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

gateway_payload = {}
if gateway_contract_path.is_file():
    gateway_payload = json.loads(gateway_contract_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(gateway_contract_path))

gateway = gateway_payload.get("gateway_contract", {})
operators = gateway.get("operator_adapters", [])

routes = [
    {
        "method": "GET",
        "path": "/runtime-gateway/health",
        "purpose": "Read service health and read-only mode.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
    {
        "method": "GET",
        "path": "/runtime-gateway/status",
        "purpose": "Read gateway state, side effects, gates and next cut.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
    {
        "method": "GET",
        "path": "/runtime-gateway/operators",
        "purpose": "List registered runtime operators and connection states.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
    {
        "method": "GET",
        "path": "/runtime-gateway/projects",
        "purpose": "List the current local project source and future project selector shape.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
    {
        "method": "GET",
        "path": "/runtime-gateway/readiness",
        "purpose": "Explain what remains blocked before real runtime launch.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
    {
        "method": "GET",
        "path": "/runtime-gateway/evidence",
        "purpose": "Return artifact paths for status, validation and handoff.",
        "mutates_state": False,
        "requires_human_gate": False,
    },
]

operator_summary = [
    {
        "operator_id": item.get("operator_id"),
        "display_name": item.get("display_name"),
        "provider_id": item.get("provider_id"),
        "adapter": item.get("adapter"),
        "runtime_surface": item.get("runtime_surface"),
        "connection_state": item.get("connection_state"),
        "auth_state": item.get("auth_state"),
        "available_for_runtime": item.get("connection_state") == "connected",
        "human_text": (
            "Planejado, mas ainda nao conectado."
            if item.get("connection_state") == "planned_not_connected"
            else "Bloqueado ate descoberta de capacidades."
            if item.get("connection_state") == "unverified_adapter"
            else "Estado precisa ser revisado."
        ),
    }
    for item in operators
]

readiness = {
    "panel_can_start_runtime": bool(gateway.get("panel_can_start_runtime", False)),
    "runtime_gateway_required": bool(gateway.get("runtime_gateway_required", True)),
    "server_started": False,
    "websocket_opened": False,
    "post_routes_enabled": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "blocked_until": [
        "provider_auth_connected",
        "credential_vault_lease_real",
        "budget_policy_accepted",
        "workspace_session_bound_to_project",
        "command_plan_created",
        "human_execution_gate_accepted",
        "runtime_adapter_capability_discovery",
        "validation_policy_bound",
    ],
}

service_contract = {
    "purpose": "Expose Runtime Gateway state to the Control Plane as read-only data before any real runtime operation.",
    "state": "read_only_contract",
    "transport": "static_json_artifact_first",
    "control_plane_source_url": "../artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json",
    "http_server_started": False,
    "allowed_methods": ["GET"],
    "forbidden_methods": ["POST", "PATCH", "PUT", "DELETE"],
    "routes": routes,
    "operator_summary": operator_summary,
    "readiness": readiness,
    "human_explanation": [
        "Este service mostra quais operadores existem e por que ainda nao podem rodar.",
        "Codex app-server e Claude Code estao planejados, mas nao conectados ao painel.",
        "Antigravity CLI e um slot futuro e fica bloqueado ate capability discovery.",
        "O painel continua proibido de iniciar runtime diretamente.",
    ],
    "evidence": {
        "gateway_contract": str(gateway_contract_path),
        "service_contract": str(artifact_root / "runtime-gateway-service.json"),
        "status": str(artifact_root / "STATUS.md"),
        "validation": str(artifact_root / "VALIDATION.md"),
        "handoff": str(artifact_root / "HANDOFF.md"),
    },
}

checks = [
    {
        "id": "gateway_contract_ready",
        "status": "passed" if gateway_payload.get("overall") == "runtime_gateway_ready" else "failed",
        "detail": "Service consumes the Runtime Gateway contract before exposing panel data.",
    },
    {
        "id": "read_only_routes_only",
        "status": "passed" if all(route["method"] == "GET" and not route["mutates_state"] for route in routes) else "failed",
        "detail": "Every declared endpoint is GET-only and non-mutating.",
    },
    {
        "id": "no_server_started",
        "status": "passed" if not service_contract["http_server_started"] else "failed",
        "detail": "This cut writes a static read-only artifact and starts no persistent service.",
    },
    {
        "id": "panel_still_cannot_start_runtime",
        "status": "passed" if readiness["runtime_gateway_required"] and not readiness["panel_can_start_runtime"] else "failed",
        "detail": "The Control Plane remains a reader and cannot launch provider runtime.",
    },
    {
        "id": "operators_visible",
        "status": "passed" if {item.get("operator_id") for item in operator_summary} >= {"codex_app_server", "claude_code", "antigravity_cli"} else "failed",
        "detail": "Codex app-server, Claude Code and Antigravity CLI appear in the read-only operator list.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No auth, socket, agent launch, token spend, command execution or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "runtime_gateway_service_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "runtime_gateway_service_ready": overall == "runtime_gateway_service_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "http_server_started": False,
    "websocket_opened": False,
    "post_routes_enabled": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-085 - Control Plane Runtime Gateway Status View",
    "missing_files": missing_files,
    "service_contract": service_contract,
    "checks": checks,
}

(artifact_root / "runtime-gateway-service.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Runtime Gateway Read-only Service",
    "",
    f"- Overall: `{overall}`",
    "- HTTP server started: `false`",
    "- WebSocket opened: `false`",
    "- POST routes enabled: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Rotas planejadas",
    "",
]
for route in routes:
    lines.append(f"- `{route['method']} {route['path']}` - {route['purpose']}")

lines.extend(["", "## Operadores visiveis", ""])
for item in operator_summary:
    lines.extend([
        f"### {item['display_name']}",
        "",
        f"- Operator id: `{item['operator_id']}`",
        f"- Adapter: `{item['adapter']}`",
        f"- Connection state: `{item['connection_state']}`",
        f"- Auth state: `{item['auth_state']}`",
        f"- Runtime disponivel: `{str(item['available_for_runtime']).lower()}`",
        f"- Leitura humana: {item['human_text']}",
        "",
    ])

lines.extend(["## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "RUNTIME_GATEWAY_SERVICE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Runtime Gateway read-only service contract recorded.",
        "- No HTTP server, socket, provider auth, agent runtime, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Runtime Gateway contract checked.",
        "- Routes are GET-only and non-mutating.",
        "- Operator list exposes Codex app-server, Claude Code and Antigravity CLI status without enabling runtime.",
        "- Control Plane remains prohibited from direct runtime launch.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-084 defines the read-only Runtime Gateway Service artifact.",
        "",
        "The next cut should render this service state in the Control Plane so a human can see which operators exist, which are connected, and why runtime is still blocked.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-runtime-gateway-service.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_runtime_gateway_service_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_runtime_gateway_service",
                "name": "scripts/artemis-portal-runtime-gateway-service.sh",
                "mode": "read_only",
            },
            ticket="TKT-084",
            title="ARTEMIS Portal Runtime Gateway Read-only Service",
            exec_pack="docs/exec-packs/done/TKT-084-artemis-portal-runtime-gateway-service.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "runtime_gateway_service_ready" else "blocked",
            payload={
                "runtime_gateway_service_ready": overall == "runtime_gateway_service_ready",
                "http_server_started": False,
                "websocket_opened": False,
                "post_routes_enabled": False,
                "operator_count": len(operator_summary),
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
                str(artifact_root / "runtime-gateway-service.json"),
                str(artifact_root / "RUNTIME_GATEWAY_SERVICE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal runtime gateway service: {overall}")
    print(f"artifact_root={artifact_root}")
    print("http_server_started=false")
    print("post_routes_enabled=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
