#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-credential-vault/run-01"
portal_auth_plan="artifacts/artemis-portal-auth-plan/run-01/portal-auth-plan.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-credential-vault.sh [--artifact-root path] [--portal-auth-plan path] [--json]

Builds the ARTEMIS Portal Credential Vault contract. It does not request,
store, encrypt, decrypt, print, validate or transmit any real secret.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --portal-auth-plan)
      portal_auth_plan="${2:-}"
      if [ -z "$portal_auth_plan" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$portal_auth_plan" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
portal_auth_plan_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md"),
    Path("docs/exec-packs/done/TKT-072-artemis-portal-auth-plan.md"),
    Path("artifacts/artemis-portal-auth-plan/run-01/portal-auth-plan.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

portal_auth = {}
if portal_auth_plan_path.is_file():
    portal_auth = json.loads(portal_auth_plan_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(portal_auth_plan_path))

providers = portal_auth.get("portal_auth", {}).get("provider_connections", [])

vault_contract = {
    "purpose": "Store and broker provider credentials for supervised ARTEMIS Portal adapters without exposing long-lived secrets to agents.",
    "storage": {
        "state": "contract_only",
        "secret_values_recorded": False,
        "recommended_backends": [
            "cloud KMS envelope encryption",
            "HashiCorp Vault",
            "AWS Secrets Manager",
            "GCP Secret Manager",
            "Azure Key Vault",
            "self-hosted encrypted database with external KMS",
        ],
        "minimum_controls": [
            "encryption at rest",
            "encryption in transit",
            "per-tenant key separation or envelope key context",
            "no plaintext persistence outside vault boundary",
            "no secrets in prompts, Exec Packs, artifacts, logs or events",
        ],
    },
    "credential_record": {
        "required_metadata": [
            "credential_id",
            "provider_id",
            "owner_type",
            "owner_id",
            "organization_id",
            "project_scope",
            "created_by",
            "created_at",
            "expires_at",
            "rotation_policy",
            "revocation_state",
            "allowed_adapters",
            "allowed_capabilities",
            "budget_policy_id",
            "human_gate_policy_id",
        ],
        "forbidden_fields": [
            "plaintext_secret",
            "raw_access_token",
            "raw_refresh_token",
            "private_key_material",
            "password",
            "session_cookie",
        ],
    },
    "scope_model": {
        "owner_types": ["user", "team", "organization", "service_account"],
        "scope_axes": ["provider", "organization", "project", "repository", "environment", "adapter", "capability"],
        "default_scope": "deny",
        "least_privilege_required": True,
    },
    "lease_model": {
        "agents_receive_long_lived_secrets": False,
        "adapter_injection": "short_lived_lease",
        "default_lease_ttl_minutes": 15,
        "max_lease_ttl_minutes": 60,
        "renewal_requires_gate": True,
        "lease_payload_redaction_required": True,
    },
    "audit_model": {
        "events_required": [
            "credential.created",
            "credential.updated",
            "credential.rotated",
            "credential.revoked",
            "credential.lease_requested",
            "credential.lease_issued",
            "credential.lease_denied",
            "credential.lease_expired",
        ],
        "audit_fields": [
            "actor_user_id",
            "organization_id",
            "project_id",
            "provider_id",
            "credential_id",
            "adapter",
            "capability",
            "gate_id",
            "budget_policy_id",
            "result",
            "reason",
            "correlation_id",
        ],
        "redaction": "secret values and token fragments must never appear in audit logs",
    },
    "rotation_and_revocation": {
        "rotation_required": True,
        "manual_revoke_required": True,
        "automatic_expiry_required": True,
        "revoke_effect": [
            "deny new leases",
            "mark active leases as revoked",
            "stop queued launches using the credential",
            "record audit event",
        ],
    },
    "policy_gates": [
        "portal_login",
        "provider_connected",
        "credential_scope_checked",
        "budget_policy_checked",
        "human_gate_policy_checked",
        "lease_approved",
        "adapter_capability_allowed",
        "remote_write_approved",
    ],
    "provider_bindings": [
        {
            "provider_id": provider.get("id"),
            "adapter": provider.get("adapter"),
            "token_owner": provider.get("token_owner"),
            "never_expose_to_agent": provider.get("never_expose_to_agent", True),
            "vault_required": True,
        }
        for provider in providers
    ],
}

checks = [
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "The vault contract records metadata and policy only; no secret material is present.",
    },
    {
        "id": "lease_model_defined",
        "status": "passed",
        "detail": "Adapters receive short-lived leases, not long-lived provider secrets.",
    },
    {
        "id": "scope_model_deny_by_default",
        "status": "passed",
        "detail": "Credential scopes default to deny and require explicit provider/project/adapter/capability policy.",
    },
    {
        "id": "audit_model_defined",
        "status": "passed",
        "detail": "Credential lifecycle and lease events have required audit fields with redaction.",
    },
    {
        "id": "rotation_revocation_defined",
        "status": "passed",
        "detail": "Rotation, expiry and revoke behavior are explicit before real provider auth.",
    },
]

overall = "contract_ready" if not missing_files else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "credential_vault_ready": not missing_files,
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "remote_state_mutated": False,
    "next_cut": "TKT-074 - ARTEMIS Portal Agent Registry Contract",
    "missing_files": missing_files,
    "vault_contract": vault_contract,
    "checks": checks,
}

(artifact_root / "credential-vault-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Credential Vault Contract",
    "",
    f"- Overall: `{overall}`",
    "- Secret values recorded: `false`",
    "- Runtime auth executed: `false`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-074 - ARTEMIS Portal Agent Registry Contract`",
    "",
    "## Storage boundary",
    "",
]
for control in vault_contract["storage"]["minimum_controls"]:
    lines.append(f"- {control}.")

lines.extend([
    "",
    "## Credential metadata",
    "",
])
for field in vault_contract["credential_record"]["required_metadata"]:
    lines.append(f"- `{field}`")

lines.extend([
    "",
    "## Forbidden fields",
    "",
])
for field in vault_contract["credential_record"]["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend([
    "",
    "## Lease model",
    "",
    f"- Agents receive long-lived secrets: `{str(vault_contract['lease_model']['agents_receive_long_lived_secrets']).lower()}`",
    f"- Adapter injection: `{vault_contract['lease_model']['adapter_injection']}`",
    f"- Default TTL minutes: `{vault_contract['lease_model']['default_lease_ttl_minutes']}`",
    f"- Max TTL minutes: `{vault_contract['lease_model']['max_lease_ttl_minutes']}`",
    "",
    "## Policy gates",
    "",
])
for gate in vault_contract["policy_gates"]:
    lines.append(f"- `{gate}`")

lines.extend([
    "",
    "## Validation",
    "",
])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CREDENTIAL_VAULT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Credential Vault contract recorded.",
        "- No credential storage or runtime auth executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Portal Auth Plan artifact checked.",
        "- Vault metadata, scope, lease, audit, rotation and revocation models defined.",
        "- No secret values, provider tokens, runtime auth or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-073 defines the ARTEMIS Portal Credential Vault contract.",
        "",
        "The next cut should define the Agent Registry contract that consumes vault leases without seeing long-lived secrets.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-credential-vault.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_credential_vault_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_credential_vault",
                "name": "scripts/artemis-portal-credential-vault.sh",
                "mode": "read_only",
            },
            ticket="TKT-073",
            title="ARTEMIS Portal Credential Vault Contract",
            exec_pack="docs/exec-packs/done/TKT-073-artemis-portal-credential-vault.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "contract_ready" else "blocked",
            payload={
                "credential_vault_ready": not missing_files,
                "secret_values_recorded": False,
                "runtime_auth_executed": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "credential-vault-contract.json"),
                str(artifact_root / "CREDENTIAL_VAULT.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal credential vault: {overall}")
    print(f"artifact_root={artifact_root}")
    print("secret_values_recorded=false")
    print("runtime_auth_executed=false")
PY
