#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-run-assignment/run-01"
agent_registry="artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json"
tasks_source="control-plane/tasks.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-run-assignment.sh [--artifact-root path] [--agent-registry path] [--tasks path] [--json]

Builds the ARTEMIS Portal Run Assignment contract. It does not authenticate
providers, issue vault leases, start agents, execute commands, spend tokens,
mutate GitHub or write remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --agent-registry)
      agent_registry="${2:-}"
      if [ -z "$agent_registry" ]; then usage; exit 2; fi
      shift 2
      ;;
    --tasks)
      tasks_source="${2:-}"
      if [ -z "$tasks_source" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$agent_registry" "$tasks_source" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
agent_registry_path = Path(sys.argv[2])
tasks_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md"),
    Path("docs/exec-packs/done/TKT-074-artemis-portal-agent-registry.md"),
    Path("artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json"),
    Path("control-plane/tasks.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

registry_payload = {}
if agent_registry_path.is_file():
    registry_payload = json.loads(agent_registry_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(agent_registry_path))

tasks_payload = {}
if tasks_path.is_file():
    tasks_payload = json.loads(tasks_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(tasks_path))

registry = registry_payload.get("registry_contract", {})
profiles = registry.get("profile_bindings", [])
profiles_by_id = {profile.get("agent_id"): profile for profile in profiles}
tasks = tasks_payload.get("tasks", [])
latest_task = tasks[-1] if tasks else {
    "ticket": "TKT-075",
    "title": "ARTEMIS Portal Run Assignment Contract",
    "risk": "medium",
    "exec_pack": "docs/exec-packs/done/TKT-075-artemis-portal-run-assignment.md",
    "evidence": "artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json",
}

def choose_profile(task):
    risk = task.get("risk", "medium")
    title = task.get("title", "").lower()
    summary = task.get("summary", "").lower()
    text = f"{title} {summary}"
    if any(marker in title for marker in ["validation", "validacao", "review", "verifier"]):
        return profiles_by_id.get("artemis_verifier") or (profiles[0] if profiles else {})
    if risk == "high" or "arquitetura" in text or "runtime" in text or "portal" in text:
        return profiles_by_id.get("codex_frontier_engineer") or (profiles[0] if profiles else {})
    if "map" in text or "docs" in text or "document" in text:
        return profiles_by_id.get("claude_code_mapper") or (profiles[0] if profiles else {})
    return profiles_by_id.get("codex_frontier_engineer") or (profiles[0] if profiles else {})

selected_profile = choose_profile(latest_task)

assignment_contract = {
    "purpose": "Bind a project task to one registered agent profile under explicit policy before any runtime launch.",
    "state": "contract_only",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "assignment_record": {
        "required_fields": [
            "assignment_id",
            "project_id",
            "task_id",
            "ticket",
            "exec_pack",
            "requested_by",
            "requested_at",
            "risk",
            "task_shape",
            "agent_profile_id",
            "provider_id",
            "adapter",
            "allowed_capabilities",
            "forbidden_capabilities",
            "budget_policy_id",
            "validation_policy_id",
            "human_gate_policy_id",
            "workspace_policy_id",
            "credential_lease_policy_id",
            "evidence_policy_id",
            "stop_rule",
            "expires_at",
        ],
        "forbidden_fields": [
            "plaintext_secret",
            "raw_access_token",
            "raw_refresh_token",
            "private_key_material",
            "session_cookie",
            "runtime_command_output",
            "provider_billing_secret",
        ],
    },
    "state_model": [
        "requested",
        "policy_checking",
        "waiting_for_provider_connection",
        "waiting_for_vault_lease",
        "waiting_for_budget",
        "waiting_for_workspace",
        "waiting_for_human_gate",
        "ready_for_launcher_preflight",
        "rejected",
        "expired",
    ],
    "selection_rules": [
        "Only profiles declared by the Agent Registry can be assigned.",
        "Task risk, task shape and requested capabilities must fit the selected profile.",
        "A writer profile requires an exclusive workspace or worktree lock.",
        "A verifier assignment must be separate from the implementation assignment it validates.",
        "Vault lease approval is planned here but issued only by the Credential Vault boundary.",
        "Budget policy must exist before token spend or paid runtime.",
        "Human Gate is required before remote write, provider auth, production, deploy or long-running runtime.",
        "Launcher preflight consumes an accepted assignment; the assignment contract itself never starts runtime.",
    ],
    "gates": [
        "task_contract_present",
        "agent_profile_registered",
        "capability_allowed",
        "forbidden_capability_absent",
        "budget_policy_bound",
        "workspace_policy_bound",
        "validation_policy_bound",
        "vault_lease_policy_bound",
        "human_gate_policy_bound",
        "stop_rule_bound",
    ],
    "evidence_policy": {
        "required_before_ready": [
            "Exec Pack path",
            "selected agent profile",
            "allowed capabilities",
            "budget policy",
            "workspace policy",
            "validation policy",
            "Human Gate policy",
            "stop rule",
        ],
        "required_after_runtime": [
            "runner logs",
            "validation output",
            "diff summary",
            "handoff",
            "cost ledger",
        ],
    },
}

sample_assignment = {
    "assignment_id": "assign-tkt-075-contract-fixture",
    "project_id": "artemis",
    "task_id": latest_task.get("id", "tkt-075"),
    "ticket": latest_task.get("ticket", "TKT-075"),
    "exec_pack": latest_task.get("exec_pack", "docs/exec-packs/done/TKT-075-artemis-portal-run-assignment.md"),
    "requested_by": "ARTEMIS contract fixture",
    "requested_at": generated_at,
    "risk": latest_task.get("risk", "medium"),
    "task_shape": selected_profile.get("task_shape", "medium_to_long"),
    "agent_profile_id": selected_profile.get("agent_id", "codex_frontier_engineer"),
    "provider_id": selected_profile.get("provider_id", "openai_codex"),
    "adapter": selected_profile.get("adapter", "codex_app_server"),
    "allowed_capabilities": selected_profile.get("default_capabilities", []),
    "forbidden_capabilities": selected_profile.get("forbidden_capabilities", []),
    "budget_policy_id": selected_profile.get("budget_policy_id", "budget:unknown"),
    "validation_policy_id": selected_profile.get("validation_policy_id", "validation:unknown"),
    "human_gate_policy_id": selected_profile.get("human_gate_policy_id", "human-gate:unknown"),
    "workspace_policy_id": selected_profile.get("workspace_policy_id", "workspace:unknown"),
    "credential_lease_policy_id": "lease:short-lived-provider-adapter",
    "evidence_policy_id": "evidence:validation-handoff-cost-ledger",
    "stop_rule": {
        "max_wall_time_minutes": selected_profile.get("limits", {}).get("max_task_duration_minutes", 60),
        "max_consecutive_failures": 1,
        "stop_on_secret_request": True,
        "stop_on_unapproved_remote_write": True,
    },
    "expires_at": "contract_fixture_no_runtime_expiry",
    "assignment_state": "ready_for_launcher_preflight" if selected_profile else "rejected",
    "runtime_execution_allowed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
}

checks = [
    {
        "id": "agent_registry_ready",
        "status": "passed" if registry_payload.get("overall") == "registry_ready" else "failed",
        "detail": "Run assignment consumes the Agent Registry before selecting a profile.",
    },
    {
        "id": "registered_profile_selected",
        "status": "passed" if sample_assignment["agent_profile_id"] in profiles_by_id else "failed",
        "detail": "The sample assignment selects only a registered agent profile.",
    },
    {
        "id": "policies_bound",
        "status": "passed" if all(sample_assignment.get(key) for key in [
            "budget_policy_id",
            "validation_policy_id",
            "human_gate_policy_id",
            "workspace_policy_id",
            "credential_lease_policy_id",
            "evidence_policy_id",
        ]) else "failed",
        "detail": "Budget, validation, Human Gate, workspace, credential lease and evidence policies are bound.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not sample_assignment["runtime_execution_allowed"] and sample_assignment["agents_started"] is False and sample_assignment["commands_executed"] == 0 else "failed",
        "detail": "The assignment remains preflight-only and cannot start runtime.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "Assignment records policy metadata only and never store provider secrets.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "assignment_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "run_assignment_ready": overall == "assignment_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract",
    "missing_files": missing_files,
    "assignment_contract": assignment_contract,
    "sample_assignment": sample_assignment,
    "checks": checks,
}

(artifact_root / "run-assignment-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Run Assignment Contract",
    "",
    f"- Overall: `{overall}`",
    "- Secret values recorded: `false`",
    "- Runtime auth executed: `false`",
    "- Vault lease issued: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract`",
    "",
    "## Regra central",
    "",
    "Uma tarefa so pode chegar ao launcher quando estiver vinculada a um perfil registrado, policies explicitas, workspace, evidence policy e stop rule. Este contrato nao executa o launcher.",
    "",
    "## Sample assignment",
    "",
    f"- Assignment id: `{sample_assignment['assignment_id']}`",
    f"- Ticket: `{sample_assignment['ticket']}`",
    f"- Agent profile: `{sample_assignment['agent_profile_id']}`",
    f"- Provider: `{sample_assignment['provider_id']}`",
    f"- Adapter: `{sample_assignment['adapter']}`",
    f"- State: `{sample_assignment['assignment_state']}`",
    f"- Runtime execution allowed: `{str(sample_assignment['runtime_execution_allowed']).lower()}`",
    "",
    "## Required assignment fields",
    "",
]
for field in assignment_contract["assignment_record"]["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in assignment_contract["assignment_record"]["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Gates", ""])
for gate in assignment_contract["gates"]:
    lines.append(f"- `{gate}`")

lines.extend(["", "## Selection rules", ""])
for rule in assignment_contract["selection_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "RUN_ASSIGNMENT.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Run Assignment contract recorded.",
        "- No provider auth, vault lease, token spend, command execution or agent runtime executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Agent Registry artifact checked.",
        "- Assignment record, profile selection, policy bindings, gates, evidence policy and stop rule defined.",
        "- No secrets, runtime auth, vault lease, token spend, agent launch, command execution or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-075 defines the ARTEMIS Portal Run Assignment contract.",
        "",
        "The next cut should define the Budget and Cost Ledger contract that constrains assignments before runtime spend.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-run-assignment.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_run_assignment_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_run_assignment",
                "name": "scripts/artemis-portal-run-assignment.sh",
                "mode": "read_only",
            },
            ticket="TKT-075",
            title="ARTEMIS Portal Run Assignment Contract",
            exec_pack="docs/exec-packs/done/TKT-075-artemis-portal-run-assignment.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "assignment_ready" else "blocked",
            payload={
                "run_assignment_ready": overall == "assignment_ready",
                "agent_profile_id": sample_assignment["agent_profile_id"],
                "runtime_execution_allowed": False,
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
                str(artifact_root / "run-assignment-contract.json"),
                str(artifact_root / "RUN_ASSIGNMENT.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal run assignment: {overall}")
    print(f"artifact_root={artifact_root}")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("tokens_spent=0")
PY
