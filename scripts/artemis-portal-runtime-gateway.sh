#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-runtime-gateway/run-01"
runtime_session="artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json"
agent_registry="artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json"
credential_vault="artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-runtime-gateway.sh [--artifact-root path] [--runtime-session path] [--agent-registry path] [--credential-vault path] [--json]

Builds the ARTEMIS Portal Runtime Gateway contract for multi-operator runtime
control. It does not authenticate providers, start app-server, start Claude
Code, start Antigravity CLI, open sockets, execute commands, spend tokens or
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
    --runtime-session)
      runtime_session="${2:-}"
      if [ -z "$runtime_session" ]; then usage; exit 2; fi
      shift 2
      ;;
    --agent-registry)
      agent_registry="${2:-}"
      if [ -z "$agent_registry" ]; then usage; exit 2; fi
      shift 2
      ;;
    --credential-vault)
      credential_vault="${2:-}"
      if [ -z "$credential_vault" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$runtime_session" "$agent_registry" "$credential_vault" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
runtime_session_path = Path(sys.argv[2])
agent_registry_path = Path(sys.argv[3])
credential_vault_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY.md"),
    Path("docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md"),
    Path("docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md"),
    Path("docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md"),
    Path("docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md"),
    Path("docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md"),
    Path("docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md"),
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md"),
    Path("artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json"),
    Path("artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json"),
    Path("artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

def read_json(path: Path) -> dict:
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    missing_files.append(str(path))
    return {}

runtime_payload = read_json(runtime_session_path)
registry_payload = read_json(agent_registry_path)
vault_payload = read_json(credential_vault_path)

registry_profiles = registry_payload.get("registry_contract", {}).get("profile_bindings", [])
provider_bindings = vault_payload.get("vault_contract", {}).get("provider_bindings", [])
known_providers = {item.get("provider_id") for item in provider_bindings if item.get("provider_id")}

operator_adapters = [
    {
        "operator_id": "codex_app_server",
        "display_name": "Codex app-server",
        "provider_id": "openai_codex",
        "adapter": "codex_app_server",
        "runtime_surface": "app_server",
        "connection_state": "planned_not_connected",
        "auth_state": "requires_provider_connection_and_vault_lease",
        "best_for": [
            "long implementation",
            "complex refactor",
            "frontier reasoning",
            "supervised approvals and artifacts",
        ],
        "credential_lease_required": True,
        "budget_policy_required": True,
        "workspace_session_required": True,
        "command_plan_required": True,
        "human_execution_gate_required": True,
        "validation_required": True,
        "cost_tracking_required": True,
        "allowed_operations": [
            "read_status",
            "draft_assignment",
            "draft_command_plan",
            "stream_redacted_events_after_gate",
            "produce_handoff",
        ],
        "forbidden_operations": [
            "start_without_gate",
            "receive_raw_secret",
            "run_unplanned_command",
            "remote_write_without_gate",
            "store_raw_stdout",
            "store_full_prompt_transcript",
        ],
        "evidence_outputs": [
            "redacted_event_stream",
            "command_plan",
            "validation_results",
            "completion_handoff",
        ],
    },
    {
        "operator_id": "claude_code",
        "display_name": "Claude Code",
        "provider_id": "anthropic_claude",
        "adapter": "claude_agent_sdk",
        "runtime_surface": "cli_or_sdk",
        "connection_state": "planned_not_connected",
        "auth_state": "requires_provider_connection_and_vault_lease",
        "best_for": [
            "repository mapping",
            "language and framework orientation",
            "short to medium implementation slices",
            "handoff drafting",
        ],
        "credential_lease_required": True,
        "budget_policy_required": True,
        "workspace_session_required": True,
        "command_plan_required": True,
        "human_execution_gate_required": True,
        "validation_required": True,
        "cost_tracking_required": True,
        "allowed_operations": [
            "read_status",
            "draft_assignment",
            "draft_command_plan",
            "capture_redacted_tool_events_after_gate",
            "produce_handoff",
        ],
        "forbidden_operations": [
            "start_without_gate",
            "receive_raw_secret",
            "run_unplanned_command",
            "remote_write_without_gate",
            "store_raw_stdout",
            "store_full_prompt_transcript",
        ],
        "evidence_outputs": [
            "redacted_tool_events",
            "command_plan",
            "validation_results",
            "completion_handoff",
        ],
    },
    {
        "operator_id": "antigravity_cli",
        "display_name": "Antigravity CLI",
        "provider_id": "antigravity",
        "adapter": "antigravity_cli",
        "runtime_surface": "cli_unverified",
        "connection_state": "unverified_adapter",
        "auth_state": "blocked_until_capability_discovery",
        "best_for": [
            "future operator adapter",
            "experimental runtime after local discovery",
            "only bounded tasks after contract review",
        ],
        "credential_lease_required": True,
        "budget_policy_required": True,
        "workspace_session_required": True,
        "command_plan_required": True,
        "human_execution_gate_required": True,
        "validation_required": True,
        "cost_tracking_required": True,
        "allowed_operations": [
            "read_status_after_adapter_exists",
            "draft_assignment_only",
            "record_capability_discovery",
        ],
        "forbidden_operations": [
            "available_before_discovery",
            "start_without_gate",
            "receive_raw_secret",
            "run_unplanned_command",
            "remote_write_without_gate",
            "store_raw_stdout",
            "store_full_prompt_transcript",
        ],
        "evidence_outputs": [
            "capability_discovery_report",
            "adapter_contract",
            "validation_results",
        ],
    },
]

gateway_contract = {
    "purpose": "Define the safe multi-operator boundary between the ARTEMIS Portal UI and provider-backed agent runtimes.",
    "state": "contract_only",
    "panel_can_start_runtime": False,
    "runtime_gateway_required": True,
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "operator_adapters": operator_adapters,
    "operator_rules": [
        "Portal UI talks to Runtime Gateway, never directly to provider CLIs.",
        "Every operator must be registered as an adapter before assignment.",
        "One writer per worktree.",
        "Every provider-backed operator requires Credential Vault lease, Budget Ledger binding, Workspace Session, Command Plan and Human Execution Gate.",
        "Experimental operators stay blocked until local capability discovery and adapter contract review pass.",
        "Verifier runs must be separated from the implementation run they review.",
        "Human owner can pause, stop, reject or require more evidence at any time.",
    ],
    "portal_operations": {
        "allowed_before_gate": [
            "list_projects",
            "list_registered_operators",
            "show_connection_state",
            "create_draft_task",
            "draft_assignment",
            "draft_command_plan",
            "request_human_gate",
            "show_planned_budget",
            "show_validation_evidence",
        ],
        "forbidden_before_gate": [
            "send_prompt_to_provider",
            "start_runtime",
            "execute_command",
            "spend_tokens",
            "open_runtime_websocket",
            "remote_write",
            "push_branch",
            "open_pr",
            "deploy",
            "store_secret",
            "store_raw_runtime_logs",
        ],
    },
    "record_contract": {
        "required_fields": [
            "operator_id",
            "display_name",
            "provider_id",
            "adapter",
            "runtime_surface",
            "connection_state",
            "auth_state",
            "credential_lease_required",
            "budget_policy_required",
            "workspace_session_required",
            "command_plan_required",
            "human_execution_gate_required",
            "validation_required",
            "cost_tracking_required",
            "allowed_operations",
            "forbidden_operations",
            "evidence_outputs",
        ],
        "forbidden_fields": [
            "plaintext_secret",
            "raw_access_token",
            "raw_refresh_token",
            "private_key_material",
            "session_cookie",
            "full_prompt_transcript",
            "raw_runtime_stdout",
            "raw_runtime_stderr",
            "provider_billing_secret",
            "git_remote_token",
        ],
    },
    "upstream_state": {
        "runtime_session_overall": runtime_payload.get("overall", "unknown"),
        "agent_registry_overall": registry_payload.get("overall", "unknown"),
        "credential_vault_overall": vault_payload.get("overall", "unknown"),
        "registered_profile_count": len(registry_profiles),
        "known_vault_providers": sorted(known_providers),
    },
}

checks = [
    {
        "id": "runtime_session_contract_ready",
        "status": "passed" if runtime_payload.get("overall") == "runtime_session_ready" else "failed",
        "detail": "Gateway consumes Runtime Session before any provider launch.",
    },
    {
        "id": "agent_registry_contract_ready",
        "status": "passed" if registry_payload.get("overall") == "registry_ready" else "failed",
        "detail": "Gateway operators are derived from registered/provider-aware profiles.",
    },
    {
        "id": "credential_vault_contract_ready",
        "status": "passed" if vault_payload.get("overall") == "contract_ready" else "failed",
        "detail": "Gateway requires vault lease policy and never stores raw secrets.",
    },
    {
        "id": "multi_operator_adapters_declared",
        "status": "passed" if len(operator_adapters) >= 3 else "failed",
        "detail": "Codex app-server, Claude Code and Antigravity CLI adapter slots are declared.",
    },
    {
        "id": "experimental_adapter_blocked",
        "status": "passed" if any(item["operator_id"] == "antigravity_cli" and item["connection_state"] == "unverified_adapter" for item in operator_adapters) else "failed",
        "detail": "Antigravity remains blocked until capability discovery confirms the local CLI contract.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No auth, runtime session, agent launch, token spend, command execution or remote mutation happened.",
    },
    {
        "id": "gateway_required_before_panel_execution",
        "status": "passed" if gateway_contract["runtime_gateway_required"] and not gateway_contract["panel_can_start_runtime"] else "failed",
        "detail": "Control Plane cannot directly start providers; it must pass through the Gateway.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "runtime_gateway_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "runtime_gateway_ready": overall == "runtime_gateway_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-084 - ARTEMIS Portal Runtime Gateway Read-only Service",
    "missing_files": missing_files,
    "gateway_contract": gateway_contract,
    "checks": checks,
}

(artifact_root / "runtime-gateway-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Runtime Gateway Contract",
    "",
    f"- Overall: `{overall}`",
    "- Panel can start runtime: `false`",
    "- Runtime gateway required: `true`",
    "- Secret values recorded: `false`",
    "- Runtime auth executed: `false`",
    "- Runtime session started: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Regra simples",
    "",
    "O painel nao fala direto com Codex, Claude Code ou Antigravity. O painel fala com o Runtime Gateway, e o Gateway so libera runtime depois de projeto, operador, auth, budget, workspace, command plan, Human Gate e validacao.",
    "",
    "## Operadores",
    "",
]

for adapter in operator_adapters:
    lines.extend([
        f"### {adapter['display_name']}",
        "",
        f"- Operator id: `{adapter['operator_id']}`",
        f"- Provider: `{adapter['provider_id']}`",
        f"- Adapter: `{adapter['adapter']}`",
        f"- Runtime surface: `{adapter['runtime_surface']}`",
        f"- Connection state: `{adapter['connection_state']}`",
        f"- Auth state: `{adapter['auth_state']}`",
        f"- Human execution gate required: `{str(adapter['human_execution_gate_required']).lower()}`",
        "",
        "Best for:",
        "",
    ])
    lines.extend(f"- {item}." for item in adapter["best_for"])
    lines.extend(["", "Forbidden before gate:", ""])
    lines.extend(f"- `{item}`" for item in adapter["forbidden_operations"])
    lines.append("")

lines.extend([
    "## Portal operations allowed before gate",
    "",
])
lines.extend(f"- `{item}`" for item in gateway_contract["portal_operations"]["allowed_before_gate"])
lines.extend(["", "## Portal operations forbidden before gate", ""])
lines.extend(f"- `{item}`" for item in gateway_contract["portal_operations"]["forbidden_before_gate"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "RUNTIME_GATEWAY.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Runtime Gateway contract recorded.",
        "- Multi-operator slots declared for Codex app-server, Claude Code and Antigravity CLI.",
        "- No provider auth, runtime session, agent launch, token spend, command execution or remote mutation happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Runtime Session, Agent Registry and Credential Vault contracts checked.",
        "- Gateway requires adapter registration, vault lease, budget, workspace, command plan, Human Gate and validation before provider-backed runtime.",
        "- Antigravity CLI is intentionally marked unverified until capability discovery confirms its local contract.",
        "- No secrets, runtime auth, token spend, agent launch, command execution or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-083 defines the ARTEMIS Portal Runtime Gateway contract.",
        "",
        "The next cut should expose this contract through a read-only local service that the Control Plane can consume before any real provider runtime is enabled.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-runtime-gateway.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_runtime_gateway_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_runtime_gateway",
                "name": "scripts/artemis-portal-runtime-gateway.sh",
                "mode": "read_only",
            },
            ticket="TKT-083",
            title="ARTEMIS Portal Runtime Gateway Contract",
            exec_pack="docs/exec-packs/done/TKT-083-artemis-portal-runtime-gateway.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "runtime_gateway_ready" else "blocked",
            payload={
                "runtime_gateway_ready": overall == "runtime_gateway_ready",
                "operator_adapters": len(operator_adapters),
                "panel_can_start_runtime": False,
                "secret_values_recorded": False,
                "runtime_auth_executed": False,
                "runtime_session_started": False,
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
                str(artifact_root / "runtime-gateway-contract.json"),
                str(artifact_root / "RUNTIME_GATEWAY.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal runtime gateway: {overall}")
    print(f"artifact_root={artifact_root}")
    print("panel_can_start_runtime=false")
    print("runtime_auth_executed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
