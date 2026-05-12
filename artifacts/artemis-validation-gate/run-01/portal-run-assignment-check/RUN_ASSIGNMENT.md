# ARTEMIS Portal Run Assignment Contract

- Overall: `assignment_ready`
- Secret values recorded: `false`
- Runtime auth executed: `false`
- Vault lease issued: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract`

## Regra central

Uma tarefa so pode chegar ao launcher quando estiver vinculada a um perfil registrado, policies explicitas, workspace, evidence policy e stop rule. Este contrato nao executa o launcher.

## Sample assignment

- Assignment id: `assign-tkt-075-contract-fixture`
- Ticket: `TKT-076`
- Agent profile: `codex_frontier_engineer`
- Provider: `openai_codex`
- Adapter: `codex_app_server`
- State: `ready_for_launcher_preflight`
- Runtime execution allowed: `false`

## Required assignment fields

- `assignment_id`
- `project_id`
- `task_id`
- `ticket`
- `exec_pack`
- `requested_by`
- `requested_at`
- `risk`
- `task_shape`
- `agent_profile_id`
- `provider_id`
- `adapter`
- `allowed_capabilities`
- `forbidden_capabilities`
- `budget_policy_id`
- `validation_policy_id`
- `human_gate_policy_id`
- `workspace_policy_id`
- `credential_lease_policy_id`
- `evidence_policy_id`
- `stop_rule`
- `expires_at`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `runtime_command_output`
- `provider_billing_secret`

## Gates

- `task_contract_present`
- `agent_profile_registered`
- `capability_allowed`
- `forbidden_capability_absent`
- `budget_policy_bound`
- `workspace_policy_bound`
- `validation_policy_bound`
- `vault_lease_policy_bound`
- `human_gate_policy_bound`
- `stop_rule_bound`

## Selection rules

- Only profiles declared by the Agent Registry can be assigned.
- Task risk, task shape and requested capabilities must fit the selected profile.
- A writer profile requires an exclusive workspace or worktree lock.
- A verifier assignment must be separate from the implementation assignment it validates.
- Vault lease approval is planned here but issued only by the Credential Vault boundary.
- Budget policy must exist before token spend or paid runtime.
- Human Gate is required before remote write, provider auth, production, deploy or long-running runtime.
- Launcher preflight consumes an accepted assignment; the assignment contract itself never starts runtime.

## Validation

- `agent_registry_ready`: passed - Run assignment consumes the Agent Registry before selecting a profile.
- `registered_profile_selected`: passed - The sample assignment selects only a registered agent profile.
- `policies_bound`: passed - Budget, validation, Human Gate, workspace, credential lease and evidence policies are bound.
- `no_runtime_execution`: passed - The assignment remains preflight-only and cannot start runtime.
- `no_secret_values_recorded`: passed - Assignment records policy metadata only and never store provider secrets.
