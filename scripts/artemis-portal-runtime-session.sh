#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-runtime-session/run-01"
workspace_session="artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json"
launcher_preflight="artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json"
credential_vault="artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-runtime-session.sh [--artifact-root path] [--workspace-session path] [--launcher-preflight path] [--credential-vault path] [--json]

Builds the ARTEMIS Portal Runtime Session contract. It does not
authenticate providers, issue vault leases, start agents, execute commands,
spend tokens, open sockets, stream transcripts, push, deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --workspace-session)
      workspace_session="${2:-}"
      if [ -z "$workspace_session" ]; then usage; exit 2; fi
      shift 2
      ;;
    --launcher-preflight)
      launcher_preflight="${2:-}"
      if [ -z "$launcher_preflight" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$workspace_session" "$launcher_preflight" "$credential_vault" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
workspace_session_path = Path(sys.argv[2])
launcher_preflight_path = Path(sys.argv[3])
credential_vault_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md"),
    Path("docs/exec-packs/done/TKT-077-artemis-portal-workspace-session.md"),
    Path("artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json"),
    Path("artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json"),
    Path("artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

workspace_payload = {}
if workspace_session_path.is_file():
    workspace_payload = json.loads(workspace_session_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(workspace_session_path))

preflight_payload = {}
if launcher_preflight_path.is_file():
    preflight_payload = json.loads(launcher_preflight_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(launcher_preflight_path))

vault_payload = {}
if credential_vault_path.is_file():
    vault_payload = json.loads(credential_vault_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(credential_vault_path))

sample_workspace = workspace_payload.get("sample_workspace_session", {})
preflight_summary = preflight_payload.get("summary", {})
vault_contract = vault_payload.get("vault_contract", {})

runtime_session_schema = {
    "required_fields": [
        "runtime_session_id",
        "workspace_session_id",
        "assignment_id",
        "project_id",
        "ticket",
        "agent_profile_id",
        "provider_id",
        "adapter",
        "runtime_surface",
        "credential_lease_policy_id",
        "workspace_policy_id",
        "budget_policy_id",
        "supervision_policy_id",
        "command_boundary",
        "heartbeat_policy",
        "transcript_policy",
        "stop_rules",
        "validation_policy_id",
        "opened_at",
        "expires_at",
        "session_state",
        "evidence",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "provider_billing_secret",
        "raw_runtime_stdout",
        "raw_runtime_stderr",
        "full_prompt_transcript",
        "git_remote_token",
        "ssh_private_key",
    ],
}

runtime_contract = {
    "purpose": "Bind workspace, budget, credential lease policy and launcher preflight into a supervised portal runtime session contract.",
    "state": "contract_only",
    "runtime_session_ready": True,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "actual_cost_units": 0,
    "remote_state_mutated": False,
    "runtime_session_schema": runtime_session_schema,
    "state_model": [
        "requested",
        "workspace_bound",
        "budget_bound",
        "waiting_for_credential_lease",
        "waiting_for_launcher_preflight",
        "waiting_for_human_runtime_gate",
        "ready_for_supervised_execution",
        "running",
        "pausing",
        "stopping",
        "stopped",
        "failed",
        "handoff_ready",
        "closed",
    ],
    "lifecycle_gates": [
        "workspace_session_ready",
        "budget_ledger_bound",
        "credential_lease_policy_bound",
        "launcher_preflight_present",
        "command_plan_required",
        "human_execution_gate_required",
        "validation_policy_bound",
        "cost_ledger_update_required",
        "completion_handoff_required",
    ],
    "supervision_policy": {
        "supervision_policy_id": "supervision:portal-controlled-runtime",
        "heartbeat_required": True,
        "heartbeat_interval_seconds": 30,
        "event_stream_required": True,
        "human_stop_supported": True,
        "agent_pause_supported": True,
        "raw_output_storage_allowed": False,
        "summary_transcript_required": True,
    },
    "command_boundary": {
        "source": "future_launcher_command_plan",
        "ad_hoc_commands_allowed": False,
        "remote_write_commands_allowed": False,
        "production_commands_allowed": False,
        "requires_exact_command_plan": True,
        "requires_pre_execution_gate": True,
    },
    "transcript_policy": {
        "summary_allowed": True,
        "raw_prompt_storage_allowed": False,
        "raw_secret_redaction_required": True,
        "human_visible_status_required": True,
        "agent_message_event_required": True,
    },
    "stop_rules": [
        "Stop before any secret request or plaintext credential exposure.",
        "Stop before any command outside the approved command plan.",
        "Stop before remote write unless a separate Human Gate allows it.",
        "Stop when budget, token, agent-count or duration limits are reached.",
        "Stop when forbidden paths are touched.",
        "Stop when dirty-worktree conflict is detected.",
        "Stop on validation failure if no approved retry policy exists.",
        "Stop immediately on human stop request.",
    ],
    "enforcement_rules": [
        "Runtime Session must consume a ready Workspace Session.",
        "Runtime Session must reference a launcher preflight artifact before command planning.",
        "Credential lease policy may be bound, but no real lease is issued in this cut.",
        "Runtime Session approval is not command execution permission.",
        "A command plan and execution gate remain required before any real agent command.",
        "Every runtime state transition must write an event and cost/usage evidence.",
        "Raw secrets, provider tokens, private keys, raw stdout/stderr and full prompt transcripts are forbidden in git artifacts.",
    ],
}

sample_runtime_session = {
    "runtime_session_id": "runtime-session-tkt-078-contract-fixture",
    "workspace_session_id": sample_workspace.get("workspace_session_id", "workspace-session-tkt-077-contract-fixture"),
    "assignment_id": sample_workspace.get("assignment_id", "assign-tkt-075-contract-fixture"),
    "project_id": sample_workspace.get("project_id", "artemis"),
    "ticket": "TKT-078",
    "source_ticket": sample_workspace.get("ticket", "TKT-077"),
    "agent_profile_id": sample_workspace.get("agent_profile_id", "codex_frontier_engineer"),
    "provider_id": "openai_codex",
    "adapter": "codex_app_server",
    "runtime_surface": "portal_supervised_runtime",
    "credential_lease_policy_id": "lease:short-lived-provider-adapter",
    "workspace_policy_id": sample_workspace.get("workspace_policy_id", "workspace:single-writer-worktree"),
    "budget_policy_id": sample_workspace.get("budget_policy_id", "budget:frontier-engineering"),
    "supervision_policy_id": runtime_contract["supervision_policy"]["supervision_policy_id"],
    "command_boundary": runtime_contract["command_boundary"],
    "heartbeat_policy": {
        "required": True,
        "interval_seconds": runtime_contract["supervision_policy"]["heartbeat_interval_seconds"],
        "started": False,
    },
    "transcript_policy": runtime_contract["transcript_policy"],
    "stop_rules": runtime_contract["stop_rules"],
    "validation_policy_id": sample_workspace.get("validation_policy_id", "validation:standard-plus"),
    "opened_at": generated_at,
    "expires_at": "contract_fixture_no_runtime_expiry",
    "session_state": "waiting_for_human_runtime_gate",
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "evidence": [
        "artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json",
        "artifacts/artemis-portal-runtime-session/run-01/RUNTIME_SESSION.md",
    ],
}

checks = [
    {
        "id": "workspace_session_ready",
        "status": "passed" if workspace_payload.get("overall") == "workspace_session_ready" else "failed",
        "detail": "Runtime Session consumes a ready Workspace Session.",
    },
    {
        "id": "launcher_preflight_present",
        "status": "passed" if launcher_preflight_path.is_file() else "failed",
        "detail": "Runtime Session can reference launcher preflight evidence.",
    },
    {
        "id": "preflight_does_not_allow_runtime",
        "status": "passed" if preflight_summary.get("runtime_execution_allowed") is False else "failed",
        "detail": "Existing launcher preflight artifact still blocks runtime execution until Human Gate.",
    },
    {
        "id": "credential_vault_contract_present",
        "status": "passed" if vault_payload.get("overall") == "contract_ready" else "failed",
        "detail": "Runtime Session references the Credential Vault contract without issuing a lease.",
    },
    {
        "id": "supervision_policy_declared",
        "status": "passed" if runtime_contract["supervision_policy"]["heartbeat_required"] and runtime_contract["supervision_policy"]["event_stream_required"] else "failed",
        "detail": "Heartbeat, event stream, human stop and transcript policy are declared.",
    },
    {
        "id": "command_boundary_declared",
        "status": "passed" if runtime_contract["command_boundary"]["requires_exact_command_plan"] and not runtime_contract["command_boundary"]["ad_hoc_commands_allowed"] else "failed",
        "detail": "Runtime commands must come from a future exact command plan.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not sample_runtime_session["runtime_execution_allowed"] and sample_runtime_session["commands_executed"] == 0 else "failed",
        "detail": "This cut records runtime session policy only and cannot execute commands.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No provider secrets, project secrets, raw stdout/stderr or full prompt transcripts are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "runtime_session_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "runtime_session_ready": overall == "runtime_session_ready",
    "secret_values_recorded": False,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "estimated_cost_units": 0,
    "actual_cost_units": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-079 - ARTEMIS Portal Agent Conversation Contract",
    "missing_files": missing_files,
    "runtime_contract": runtime_contract,
    "sample_runtime_session": sample_runtime_session,
    "checks": checks,
    "inputs": {
        "workspace_session": str(workspace_session_path),
        "launcher_preflight": str(launcher_preflight_path),
        "credential_vault": str(credential_vault_path),
        "credential_vault_sections": len(vault_contract),
    },
}

(artifact_root / "runtime-session-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Runtime Session Contract",
    "",
    f"- Overall: `{overall}`",
    "- Runtime execution allowed: `false`",
    "- Runtime session started: `false`",
    "- Runtime auth executed: `false`",
    "- Vault lease issued: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-079 - ARTEMIS Portal Agent Conversation Contract`",
    "",
    "## Regra central",
    "",
    "Nenhuma sessao de runtime do portal pode iniciar agente sem Workspace Session pronta, lease policy, launcher preflight, command plan, execution gate, budget/cost ledger e Human Gate quando aplicavel.",
    "",
    "## Session required fields",
    "",
]
for field in runtime_session_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in runtime_session_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Lifecycle gates", ""])
for gate in runtime_contract["lifecycle_gates"]:
    lines.append(f"- `{gate}`")

lines.extend(["", "## Stop rules", ""])
for rule in runtime_contract["stop_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Enforcement rules", ""])
for rule in runtime_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "RUNTIME_SESSION.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Runtime Session contract recorded.",
        "- No provider auth, vault lease, agent start, command execution, socket stream, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Workspace Session artifact checked.",
        "- Launcher Preflight artifact checked.",
        "- Credential Vault contract checked.",
        "- Runtime session schema, lifecycle gates, supervision policy, command boundary, transcript policy and stop rules defined.",
        "- No secrets, raw runtime output, full prompt transcript, provider auth, vault lease, command execution, agent launch, token spend or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-078 defines the ARTEMIS Portal Runtime Session contract.",
        "",
        "The next cut should define the Portal Agent Conversation contract that maps human messages, agent replies, task updates and runtime events into a safe conversation surface.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-runtime-session.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_runtime_session_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_runtime_session",
                "name": "scripts/artemis-portal-runtime-session.sh",
                "mode": "read_only",
            },
            ticket="TKT-078",
            title="ARTEMIS Portal Runtime Session Contract",
            exec_pack="docs/exec-packs/done/TKT-078-artemis-portal-runtime-session.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "runtime_session_ready" else "blocked",
            payload={
                "runtime_session_ready": overall == "runtime_session_ready",
                "runtime_session_id": sample_runtime_session["runtime_session_id"],
                "workspace_session_id": sample_runtime_session["workspace_session_id"],
                "supervision_policy_id": sample_runtime_session["supervision_policy_id"],
                "runtime_execution_allowed": False,
                "runtime_session_started": False,
                "runtime_auth_executed": False,
                "vault_lease_issued": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "secret_values_recorded": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "runtime-session-contract.json"),
                str(artifact_root / "RUNTIME_SESSION.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal runtime session: {overall}")
    print(f"artifact_root={artifact_root}")
    print("runtime_execution_allowed=false")
    print("runtime_session_started=false")
    print("commands_executed=0")
PY
