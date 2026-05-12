# ARTEMIS Portal Agent Registry Contract

- Overall: `registry_ready`
- Secret values recorded: `false`
- Runtime auth executed: `false`
- Agents started: `false`
- Remote state mutated: `false`
- Next cut: `TKT-075 - ARTEMIS Portal Run Assignment Contract`

## Regra central

O Portal nao lanca agentes livres. Ele escolhe perfis registrados, aplica budget, solicita vault lease curto e exige gates/validacao antes de qualquer execucao real.

## Agent profiles

### Codex Frontier Engineer

- Agent id: `codex_frontier_engineer`
- Provider: `openai_codex`
- Adapter: `codex_app_server`
- Runtime: `codex`
- Model policy: `organization_frontier_default`
- Task shape: `medium_to_long`
- Requires vault lease: `true`
- Receives raw secret: `false`

Best for:

- long-horizon implementation.
- complex refactors.
- multi-file reasoning.
- high-risk validation planning.

Default capabilities:

- `read_repo`
- `write_worktree`
- `run_local_tests`
- `produce_handoff`
- `request_human_gate`

Forbidden capabilities:

- `read_plaintext_secrets`
- `bypass_human_gate`
- `push_without_gate`
- `modify_branch_protection`
- `deploy_production`

### Claude Code Mapper

- Agent id: `claude_code_mapper`
- Provider: `anthropic_claude`
- Adapter: `claude_agent_sdk`
- Runtime: `claude_code`
- Model policy: `organization_claude_code_default`
- Task shape: `short_to_medium`
- Requires vault lease: `true`
- Receives raw secret: `false`

Best for:

- repository mapping.
- language and framework orientation.
- medium implementation slices.
- documentation and handoff drafting.

Default capabilities:

- `read_repo`
- `write_worktree`
- `run_local_tests`
- `produce_handoff`
- `request_human_gate`

Forbidden capabilities:

- `read_plaintext_secrets`
- `bypass_human_gate`
- `push_without_gate`
- `modify_branch_protection`
- `deploy_production`

### ARTEMIS Verifier

- Agent id: `artemis_verifier`
- Provider: `openai_codex`
- Adapter: `codex_app_server`
- Runtime: `codex`
- Model policy: `organization_standard_verifier_default`
- Task shape: `short_to_medium`
- Requires vault lease: `true`
- Receives raw secret: `false`

Best for:

- claim validation.
- test adequacy review.
- completion evidence.
- handoff acceptance checks.

Default capabilities:

- `read_repo`
- `run_local_tests`
- `read_artifacts`
- `produce_review`
- `request_human_gate`

Forbidden capabilities:

- `write_without_assignment`
- `read_plaintext_secrets`
- `bypass_human_gate`
- `push_without_gate`
- `deploy_production`

## Required profile fields

- `agent_id`
- `display_name`
- `provider_id`
- `adapter`
- `runtime_kind`
- `model_policy`
- `role_family`
- `best_for`
- `task_shape`
- `requires_vault_lease`
- `receives_raw_secret`
- `default_capabilities`
- `forbidden_capabilities`
- `limits`
- `budget_policy_id`
- `validation_policy_id`
- `human_gate_policy_id`
- `workspace_policy_id`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `password`
- `session_cookie`
- `unbounded_system_prompt`

## Assignment rules

- One writer per worktree.
- A verifier must not verify its own unreviewed implementation run.
- Provider capability must exist before a profile becomes available.
- Vault lease is required before provider-backed runtime launch.
- Budget policy is required before token spend.
- Remote write capability is disabled unless a Human Gate explicitly approves it.
- Long or high-risk work defaults to the frontier Codex profile unless human policy chooses otherwise.
- Repository mapping and medium bounded work may use the Claude Code profile when its provider connection is available.

## Validation

- `credential_vault_ready`: passed - Agent registry consumes the Credential Vault contract before provider-backed runtime.
- `required_profile_fields_present`: passed - Every registered profile includes provider, model, policy, capability and workspace metadata.
- `no_secret_values_recorded`: passed - Agent profiles contain metadata, policy and capability boundaries only.
- `vault_lease_required`: passed - Provider-backed profiles require a vault lease and never receive raw secrets.
- `capabilities_deny_dangerous_defaults`: passed - Dangerous capabilities are forbidden or gated by validation and Human Gate policy.
- `model_policy_not_secret`: passed - Profiles reference model policies; they do not embed credentials or immutable secret-backed runtime state.
