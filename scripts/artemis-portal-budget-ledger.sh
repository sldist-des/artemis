#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-budget-ledger/run-01"
run_assignment="artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-budget-ledger.sh [--artifact-root path] [--run-assignment path] [--json]

Builds the ARTEMIS Portal Budget and Cost Ledger contract. It does not
authenticate providers, issue vault leases, start agents, execute commands,
spend tokens, read billing APIs, mutate GitHub or write remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --run-assignment)
      run_assignment="${2:-}"
      if [ -z "$run_assignment" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$run_assignment" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
run_assignment_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md"),
    Path("docs/exec-packs/done/TKT-075-artemis-portal-run-assignment.md"),
    Path("artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

assignment_payload = {}
if run_assignment_path.is_file():
    assignment_payload = json.loads(run_assignment_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(run_assignment_path))

sample_assignment = assignment_payload.get("sample_assignment", {})
assignment_budget_policy = sample_assignment.get("budget_policy_id", "budget:unknown")

budget_policies = [
    {
        "budget_policy_id": "budget:frontier-engineering",
        "label": "Frontier engineering",
        "applies_to": ["codex_frontier_engineer"],
        "max_agents": 2,
        "max_wall_time_minutes": 180,
        "max_prompt_tokens": 300000,
        "max_completion_tokens": 120000,
        "max_total_tokens": 420000,
        "max_estimated_cost_units": 100,
        "hard_stop_on_limit": True,
        "human_gate_required_above_cost_units": 40,
    },
    {
        "budget_policy_id": "budget:medium-slice",
        "label": "Medium implementation slice",
        "applies_to": ["claude_code_mapper"],
        "max_agents": 3,
        "max_wall_time_minutes": 90,
        "max_prompt_tokens": 180000,
        "max_completion_tokens": 70000,
        "max_total_tokens": 250000,
        "max_estimated_cost_units": 45,
        "hard_stop_on_limit": True,
        "human_gate_required_above_cost_units": 20,
    },
    {
        "budget_policy_id": "budget:verification",
        "label": "Verification",
        "applies_to": ["artemis_verifier"],
        "max_agents": 2,
        "max_wall_time_minutes": 60,
        "max_prompt_tokens": 120000,
        "max_completion_tokens": 30000,
        "max_total_tokens": 150000,
        "max_estimated_cost_units": 20,
        "hard_stop_on_limit": True,
        "human_gate_required_above_cost_units": 10,
    },
]
budget_policy_by_id = {policy["budget_policy_id"]: policy for policy in budget_policies}
selected_budget_policy = budget_policy_by_id.get(assignment_budget_policy, budget_policies[0])

ledger_entry_schema = {
    "required_fields": [
        "ledger_entry_id",
        "assignment_id",
        "ticket",
        "agent_profile_id",
        "budget_policy_id",
        "provider_id",
        "model_policy",
        "phase",
        "recorded_at",
        "prompt_tokens",
        "completion_tokens",
        "total_tokens",
        "estimated_cost_units",
        "actual_cost_units",
        "limit_state",
        "human_gate_required",
        "evidence",
    ],
    "forbidden_fields": [
        "raw_provider_invoice",
        "billing_api_secret",
        "card_number",
        "provider_account_secret",
        "plaintext_token",
        "runtime_command_output",
    ],
}

budget_contract = {
    "purpose": "Bind every portal run assignment to explicit token, cost, duration and agent-count limits before runtime spend.",
    "state": "contract_only",
    "budget_ledger_ready": True,
    "spend_authorized": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "actual_cost_units": 0,
    "remote_state_mutated": False,
    "unit_policy": {
        "currency": "policy_units",
        "reason": "Avoid coupling this contract to live provider billing before billing adapters exist.",
        "conversion_source": "future_provider_billing_adapter",
        "raw_billing_values_allowed": False,
    },
    "budget_policies": budget_policies,
    "ledger_entry_schema": ledger_entry_schema,
    "state_model": [
        "draft",
        "estimated",
        "waiting_for_human_budget_gate",
        "approved_for_preflight",
        "spending",
        "limit_warning",
        "hard_stopped",
        "closed",
        "reconciled",
    ],
    "enforcement_rules": [
        "A Run Assignment must bind a known budget policy before launcher preflight.",
        "Budget approval is not runtime execution permission.",
        "Human Gate is required when estimated cost exceeds policy threshold.",
        "Runtime must stop when max_total_tokens, max_wall_time_minutes or max_agents is exceeded.",
        "Ledger entries are append-only and must reference assignment id, ticket and evidence.",
        "Actual provider billing reconciliation is future work and must not store secrets or raw billing credentials.",
        "Remote writes remain blocked even when budget is approved.",
    ],
}

sample_ledger_entry = {
    "ledger_entry_id": "cost-tkt-076-contract-fixture",
    "assignment_id": sample_assignment.get("assignment_id", "assign-tkt-076-contract-fixture"),
    "ticket": "TKT-076",
    "agent_profile_id": sample_assignment.get("agent_profile_id", "codex_frontier_engineer"),
    "budget_policy_id": selected_budget_policy["budget_policy_id"],
    "provider_id": sample_assignment.get("provider_id", "openai_codex"),
    "model_policy": "organization_policy_reference_only",
    "phase": "contract_fixture",
    "recorded_at": generated_at,
    "prompt_tokens": 0,
    "completion_tokens": 0,
    "total_tokens": 0,
    "estimated_cost_units": 0,
    "actual_cost_units": 0,
    "limit_state": "within_budget",
    "human_gate_required": False,
    "evidence": [
        "artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json",
        "artifacts/artemis-portal-budget-ledger/run-01/BUDGET_LEDGER.md",
    ],
}

checks = [
    {
        "id": "run_assignment_ready",
        "status": "passed" if assignment_payload.get("overall") == "assignment_ready" else "failed",
        "detail": "Budget Ledger consumes an accepted Run Assignment before defining spend limits.",
    },
    {
        "id": "budget_policy_bound",
        "status": "passed" if assignment_budget_policy in budget_policy_by_id else "failed",
        "detail": "The assignment budget policy resolves to a concrete limit policy.",
    },
    {
        "id": "ledger_schema_declared",
        "status": "passed" if ledger_entry_schema["required_fields"] and ledger_entry_schema["forbidden_fields"] else "failed",
        "detail": "Append-only cost ledger fields and forbidden billing/secret fields are declared.",
    },
    {
        "id": "no_runtime_spend",
        "status": "passed" if sample_ledger_entry["total_tokens"] == 0 and sample_ledger_entry["actual_cost_units"] == 0 else "failed",
        "detail": "This cut records policy and zero-spend fixture data only.",
    },
    {
        "id": "hard_limits_present",
        "status": "passed" if all(policy.get("hard_stop_on_limit") for policy in budget_policies) else "failed",
        "detail": "Every budget policy has hard stop behavior for runtime enforcement.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No provider secrets, payment data or raw billing credentials are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "budget_ledger_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "budget_ledger_ready": overall == "budget_ledger_ready",
    "spend_authorized": False,
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "estimated_cost_units": 0,
    "actual_cost_units": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-077 - ARTEMIS Portal Workspace Session Contract",
    "missing_files": missing_files,
    "budget_contract": budget_contract,
    "sample_ledger_entry": sample_ledger_entry,
    "checks": checks,
}

(artifact_root / "budget-ledger-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Budget and Cost Ledger Contract",
    "",
    f"- Overall: `{overall}`",
    "- Spend authorized: `false`",
    "- Runtime auth executed: `false`",
    "- Vault lease issued: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Actual cost units: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-077 - ARTEMIS Portal Workspace Session Contract`",
    "",
    "## Regra central",
    "",
    "Nenhum assignment pode chegar ao launcher sem budget policy resolvida, limites de token/custo/duracao/agentes e ledger append-only. Budget aprovado nao e permissao de execucao.",
    "",
    "## Selected policy",
    "",
    f"- Budget policy: `{selected_budget_policy['budget_policy_id']}`",
    f"- Max agents: `{selected_budget_policy['max_agents']}`",
    f"- Max wall time minutes: `{selected_budget_policy['max_wall_time_minutes']}`",
    f"- Max total tokens: `{selected_budget_policy['max_total_tokens']}`",
    f"- Max estimated cost units: `{selected_budget_policy['max_estimated_cost_units']}`",
    "",
    "## Ledger required fields",
    "",
]
for field in ledger_entry_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in ledger_entry_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Policies", ""])
for policy in budget_policies:
    lines.extend([
        f"### {policy['label']}",
        "",
        f"- Policy id: `{policy['budget_policy_id']}`",
        f"- Applies to: `{', '.join(policy['applies_to'])}`",
        f"- Max agents: `{policy['max_agents']}`",
        f"- Max wall time minutes: `{policy['max_wall_time_minutes']}`",
        f"- Max total tokens: `{policy['max_total_tokens']}`",
        f"- Max estimated cost units: `{policy['max_estimated_cost_units']}`",
        f"- Human Gate above cost units: `{policy['human_gate_required_above_cost_units']}`",
        "",
    ])

lines.extend(["## Enforcement rules", ""])
for rule in budget_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "BUDGET_LEDGER.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Budget and Cost Ledger contract recorded.",
        "- No provider auth, vault lease, token spend, billing API call, command execution or agent runtime executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Run Assignment artifact checked.",
        "- Budget policies, cost ledger schema, hard limits, Human Gate thresholds and forbidden billing/secret fields defined.",
        "- No secrets, runtime auth, vault lease, token spend, billing API call, agent launch, command execution or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-076 defines the ARTEMIS Portal Budget and Cost Ledger contract.",
        "",
        "The next cut should define the Portal Workspace Session contract that binds assignment and budget to a concrete project/worktree lock before runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-budget-ledger.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_budget_ledger_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_budget_ledger",
                "name": "scripts/artemis-portal-budget-ledger.sh",
                "mode": "read_only",
            },
            ticket="TKT-076",
            title="ARTEMIS Portal Budget and Cost Ledger Contract",
            exec_pack="docs/exec-packs/done/TKT-076-artemis-portal-budget-ledger.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "budget_ledger_ready" else "blocked",
            payload={
                "budget_ledger_ready": overall == "budget_ledger_ready",
                "budget_policy_id": selected_budget_policy["budget_policy_id"],
                "spend_authorized": False,
                "tokens_spent": 0,
                "estimated_cost_units": 0,
                "actual_cost_units": 0,
                "runtime_auth_executed": False,
                "vault_lease_issued": False,
                "agents_started": False,
                "commands_executed": 0,
                "secret_values_recorded": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "budget-ledger-contract.json"),
                str(artifact_root / "BUDGET_LEDGER.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal budget ledger: {overall}")
    print(f"artifact_root={artifact_root}")
    print("spend_authorized=false")
    print("tokens_spent=0")
    print("actual_cost_units=0")
PY
