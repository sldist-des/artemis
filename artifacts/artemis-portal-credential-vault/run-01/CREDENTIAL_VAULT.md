# ARTEMIS Portal Credential Vault Contract

- Overall: `contract_ready`
- Secret values recorded: `false`
- Runtime auth executed: `false`
- Remote state mutated: `false`
- Next cut: `TKT-074 - ARTEMIS Portal Agent Registry Contract`

## Storage boundary

- encryption at rest.
- encryption in transit.
- per-tenant key separation or envelope key context.
- no plaintext persistence outside vault boundary.
- no secrets in prompts, Exec Packs, artifacts, logs or events.

## Credential metadata

- `credential_id`
- `provider_id`
- `owner_type`
- `owner_id`
- `organization_id`
- `project_scope`
- `created_by`
- `created_at`
- `expires_at`
- `rotation_policy`
- `revocation_state`
- `allowed_adapters`
- `allowed_capabilities`
- `budget_policy_id`
- `human_gate_policy_id`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `password`
- `session_cookie`

## Lease model

- Agents receive long-lived secrets: `false`
- Adapter injection: `short_lived_lease`
- Default TTL minutes: `15`
- Max TTL minutes: `60`

## Policy gates

- `portal_login`
- `provider_connected`
- `credential_scope_checked`
- `budget_policy_checked`
- `human_gate_policy_checked`
- `lease_approved`
- `adapter_capability_allowed`
- `remote_write_approved`

## Validation

- `no_secret_values_recorded`: passed - The vault contract records metadata and policy only; no secret material is present.
- `lease_model_defined`: passed - Adapters receive short-lived leases, not long-lived provider secrets.
- `scope_model_deny_by_default`: passed - Credential scopes default to deny and require explicit provider/project/adapter/capability policy.
- `audit_model_defined`: passed - Credential lifecycle and lease events have required audit fields with redaction.
- `rotation_revocation_defined`: passed - Rotation, expiry and revoke behavior are explicit before real provider auth.
