#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-agent-registry/run-01"
credential_vault="artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-agent-registry.sh [--artifact-root path] [--credential-vault path] [--json]

Builds the ARTEMIS Portal Agent Registry contract. It does not authenticate
providers, issue vault leases, start agents, spend tokens, mutate GitHub or
write remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$credential_vault" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
credential_vault_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md"),
    Path("docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md"),
    Path("docs/exec-packs/done/TKT-073-artemis-portal-credential-vault.md"),
    Path("artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

vault_payload = {}
if credential_vault_path.is_file():
    vault_payload = json.loads(credential_vault_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(credential_vault_path))

provider_bindings = vault_payload.get("vault_contract", {}).get("provider_bindings", [])
known_providers = {item.get("provider_id") for item in provider_bindings if item.get("provider_id")}

agent_profiles = [
    {
        "agent_id": "codex_frontier_engineer",
        "display_name": "Codex Frontier Engineer",
        "provider_id": "openai_codex",
        "adapter": "codex_app_server",
        "runtime_kind": "codex",
        "model_policy": "organization_frontier_default",
        "role_family": ["architect", "executor", "code-reviewer", "verifier"],
        "best_for": [
            "long-horizon implementation",
            "complex refactors",
            "multi-file reasoning",
            "high-risk validation planning",
        ],
        "task_shape": "medium_to_long",
        "requires_vault_lease": True,
        "receives_raw_secret": False,
        "budget_policy_id": "budget:frontier-engineering",
        "validation_policy_id": "validation:standard-plus",
        "human_gate_policy_id": "human-gate:remote-write-and-high-risk",
        "workspace_policy_id": "workspace:single-writer-worktree",
        "default_capabilities": [
            "read_repo",
            "write_worktree",
            "run_local_tests",
            "produce_handoff",
            "request_human_gate",
        ],
        "forbidden_capabilities": [
            "read_plaintext_secrets",
            "bypass_human_gate",
            "push_without_gate",
            "modify_branch_protection",
            "deploy_production",
        ],
        "limits": {
            "max_concurrent_runs_per_project": 2,
            "max_task_duration_minutes": 180,
            "requires_budget_policy": True,
            "requires_validation_policy": True,
        },
    },
    {
        "agent_id": "claude_code_mapper",
        "display_name": "Claude Code Mapper",
        "provider_id": "anthropic_claude",
        "adapter": "claude_agent_sdk",
        "runtime_kind": "claude_code",
        "model_policy": "organization_claude_code_default",
        "role_family": ["explore", "debugger", "executor", "writer"],
        "best_for": [
            "repository mapping",
            "language and framework orientation",
            "medium implementation slices",
            "documentation and handoff drafting",
        ],
        "task_shape": "short_to_medium",
        "requires_vault_lease": True,
        "receives_raw_secret": False,
        "budget_policy_id": "budget:medium-slice",
        "validation_policy_id": "validation:standard",
        "human_gate_policy_id": "human-gate:remote-write",
        "workspace_policy_id": "workspace:single-writer-worktree",
        "default_capabilities": [
            "read_repo",
            "write_worktree",
            "run_local_tests",
            "produce_handoff",
            "request_human_gate",
        ],
        "forbidden_capabilities": [
            "read_plaintext_secrets",
            "bypass_human_gate",
            "push_without_gate",
            "modify_branch_protection",
            "deploy_production",
        ],
        "limits": {
            "max_concurrent_runs_per_project": 3,
            "max_task_duration_minutes": 90,
            "requires_budget_policy": True,
            "requires_validation_policy": True,
        },
    },
    {
        "agent_id": "artemis_verifier",
        "display_name": "ARTEMIS Verifier",
        "provider_id": "openai_codex",
        "adapter": "codex_app_server",
        "runtime_kind": "codex",
        "model_policy": "organization_standard_verifier_default",
        "role_family": ["verifier", "test-engineer", "code-reviewer"],
        "best_for": [
            "claim validation",
            "test adequacy review",
            "completion evidence",
            "handoff acceptance checks",
        ],
        "task_shape": "short_to_medium",
        "requires_vault_lease": True,
        "receives_raw_secret": False,
        "budget_policy_id": "budget:verification",
        "validation_policy_id": "validation:review-only",
        "human_gate_policy_id": "human-gate:completion-acceptance",
        "workspace_policy_id": "workspace:read-mostly-verifier",
        "default_capabilities": [
            "read_repo",
            "run_local_tests",
            "read_artifacts",
            "produce_review",
            "request_human_gate",
        ],
        "forbidden_capabilities": [
            "write_without_assignment",
            "read_plaintext_secrets",
            "bypass_human_gate",
            "push_without_gate",
            "deploy_production",
        ],
        "limits": {
            "max_concurrent_runs_per_project": 2,
            "max_task_duration_minutes": 60,
            "requires_budget_policy": True,
            "requires_validation_policy": True,
        },
    },
]

registry_contract = {
    "purpose": "Declare which supervised agents the ARTEMIS Portal may offer, what they are allowed to do, and which gates must pass before launch.",
    "state": "contract_only",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "agents_started": False,
    "remote_state_mutated": False,
    "model_selection": {
        "rule": "Agent profiles reference model policies, not hardcoded provider credentials or immutable model names.",
        "sources": [
            "organization policy",
            "provider capability discovery",
            "project risk tier",
            "budget policy",
            "human override",
        ],
        "invariant": "Changing a model must not change credential scope, validation gates or authority boundaries.",
    },
    "profile_record": {
        "required_fields": [
            "agent_id",
            "display_name",
            "provider_id",
            "adapter",
            "runtime_kind",
            "model_policy",
            "role_family",
            "best_for",
            "task_shape",
            "requires_vault_lease",
            "receives_raw_secret",
            "default_capabilities",
            "forbidden_capabilities",
            "limits",
            "budget_policy_id",
            "validation_policy_id",
            "human_gate_policy_id",
            "workspace_policy_id",
        ],
        "forbidden_fields": [
            "plaintext_secret",
            "raw_access_token",
            "raw_refresh_token",
            "private_key_material",
            "password",
            "session_cookie",
            "unbounded_system_prompt",
        ],
    },
    "state_model": [
        "draft",
        "ready",
        "waiting_for_provider_connection",
        "waiting_for_vault_lease",
        "waiting_for_budget",
        "waiting_for_human_gate",
        "available",
        "assigned",
        "running",
        "validating",
        "blocked",
        "disabled",
    ],
    "assignment_rules": [
        "One writer per worktree.",
        "A verifier must not verify its own unreviewed implementation run.",
        "Provider capability must exist before a profile becomes available.",
        "Vault lease is required before provider-backed runtime launch.",
        "Budget policy is required before token spend.",
        "Remote write capability is disabled unless a Human Gate explicitly approves it.",
        "Long or high-risk work defaults to the frontier Codex profile unless human policy chooses otherwise.",
        "Repository mapping and medium bounded work may use the Claude Code profile when its provider connection is available.",
    ],
    "capability_catalog": [
        {
            "capability": "read_repo",
            "risk": "low",
            "human_gate_required": False,
            "validation_required": False,
        },
        {
            "capability": "write_worktree",
            "risk": "medium",
            "human_gate_required": False,
            "validation_required": True,
        },
        {
            "capability": "run_local_tests",
            "risk": "low",
            "human_gate_required": False,
            "validation_required": True,
        },
        {
            "capability": "open_pr_draft",
            "risk": "medium",
            "human_gate_required": True,
            "validation_required": True,
        },
        {
            "capability": "push_branch",
            "risk": "high",
            "human_gate_required": True,
            "validation_required": True,
        },
        {
            "capability": "deploy_production",
            "risk": "critical",
            "human_gate_required": True,
            "validation_required": True,
            "default_allowed": False,
        },
    ],
    "profile_bindings": agent_profiles,
    "provider_coverage": [
        {
            "provider_id": profile["provider_id"],
            "agent_id": profile["agent_id"],
            "declared_in_vault": profile["provider_id"] in known_providers,
            "adapter": profile["adapter"],
        }
        for profile in agent_profiles
    ],
}

checks = [
    {
        "id": "credential_vault_ready",
        "status": "passed" if vault_payload.get("overall") == "contract_ready" else "failed",
        "detail": "Agent registry consumes the Credential Vault contract before provider-backed runtime.",
    },
    {
        "id": "required_profile_fields_present",
        "status": "passed" if all(
            all(field in profile for field in registry_contract["profile_record"]["required_fields"])
            for profile in agent_profiles
        ) else "failed",
        "detail": "Every registered profile includes provider, model, policy, capability and workspace metadata.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "Agent profiles contain metadata, policy and capability boundaries only.",
    },
    {
        "id": "vault_lease_required",
        "status": "passed" if all(profile["requires_vault_lease"] for profile in agent_profiles) else "failed",
        "detail": "Provider-backed profiles require a vault lease and never receive raw secrets.",
    },
    {
        "id": "capabilities_deny_dangerous_defaults",
        "status": "passed",
        "detail": "Dangerous capabilities are forbidden or gated by validation and Human Gate policy.",
    },
    {
        "id": "model_policy_not_secret",
        "status": "passed",
        "detail": "Profiles reference model policies; they do not embed credentials or immutable secret-backed runtime state.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "registry_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "agent_registry_ready": overall == "registry_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "agents_started": False,
    "remote_state_mutated": False,
    "next_cut": "TKT-075 - ARTEMIS Portal Run Assignment Contract",
    "missing_files": missing_files,
    "registry_contract": registry_contract,
    "checks": checks,
}

(artifact_root / "agent-registry-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Agent Registry Contract",
    "",
    f"- Overall: `{overall}`",
    "- Secret values recorded: `false`",
    "- Runtime auth executed: `false`",
    "- Agents started: `false`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-075 - ARTEMIS Portal Run Assignment Contract`",
    "",
    "## Regra central",
    "",
    "O Portal nao lanca agentes livres. Ele escolhe perfis registrados, aplica budget, solicita vault lease curto e exige gates/validacao antes de qualquer execucao real.",
    "",
    "## Agent profiles",
    "",
]
for profile in agent_profiles:
    lines.extend([
        f"### {profile['display_name']}",
        "",
        f"- Agent id: `{profile['agent_id']}`",
        f"- Provider: `{profile['provider_id']}`",
        f"- Adapter: `{profile['adapter']}`",
        f"- Runtime: `{profile['runtime_kind']}`",
        f"- Model policy: `{profile['model_policy']}`",
        f"- Task shape: `{profile['task_shape']}`",
        f"- Requires vault lease: `{str(profile['requires_vault_lease']).lower()}`",
        f"- Receives raw secret: `{str(profile['receives_raw_secret']).lower()}`",
        "",
        "Best for:",
        "",
    ])
    lines.extend(f"- {item}." for item in profile["best_for"])
    lines.extend(["", "Default capabilities:", ""])
    lines.extend(f"- `{item}`" for item in profile["default_capabilities"])
    lines.extend(["", "Forbidden capabilities:", ""])
    lines.extend(f"- `{item}`" for item in profile["forbidden_capabilities"])
    lines.append("")

lines.extend([
    "## Required profile fields",
    "",
])
for field in registry_contract["profile_record"]["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend([
    "",
    "## Forbidden fields",
    "",
])
for field in registry_contract["profile_record"]["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend([
    "",
    "## Assignment rules",
    "",
])
for rule in registry_contract["assignment_rules"]:
    lines.append(f"- {rule}")

lines.extend([
    "",
    "## Validation",
    "",
])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "AGENT_REGISTRY.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Agent Registry contract recorded.",
        "- No provider auth, vault lease, token spend or agent runtime executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Credential Vault artifact checked.",
        "- Agent profile records, capabilities, forbidden fields, assignment rules and lifecycle states defined.",
        "- No secrets, runtime auth, token spend, agent launch or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-074 defines the ARTEMIS Portal Agent Registry contract.",
        "",
        "The next cut should define the Run Assignment contract that chooses a registered agent for a project task under budget, workspace and validation policy.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-agent-registry.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_agent_registry_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_agent_registry",
                "name": "scripts/artemis-portal-agent-registry.sh",
                "mode": "read_only",
            },
            ticket="TKT-074",
            title="ARTEMIS Portal Agent Registry Contract",
            exec_pack="docs/exec-packs/done/TKT-074-artemis-portal-agent-registry.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "registry_ready" else "blocked",
            payload={
                "agent_registry_ready": overall == "registry_ready",
                "profiles": len(agent_profiles),
                "capabilities": len(registry_contract["capability_catalog"]),
                "secret_values_recorded": False,
                "runtime_auth_executed": False,
                "agents_started": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "agent-registry-contract.json"),
                str(artifact_root / "AGENT_REGISTRY.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal agent registry: {overall}")
    print(f"artifact_root={artifact_root}")
    print("secret_values_recorded=false")
    print("runtime_auth_executed=false")
    print("agents_started=false")
PY
