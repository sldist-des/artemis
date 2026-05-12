# ARTEMIS Portal Budget and Cost Ledger Contract

- Overall: `budget_ledger_ready`
- Spend authorized: `false`
- Runtime auth executed: `false`
- Vault lease issued: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Actual cost units: `0`
- Remote state mutated: `false`
- Next cut: `TKT-077 - ARTEMIS Portal Workspace Session Contract`

## Regra central

Nenhum assignment pode chegar ao launcher sem budget policy resolvida, limites de token/custo/duracao/agentes e ledger append-only. Budget aprovado nao e permissao de execucao.

## Selected policy

- Budget policy: `budget:frontier-engineering`
- Max agents: `2`
- Max wall time minutes: `180`
- Max total tokens: `420000`
- Max estimated cost units: `100`

## Ledger required fields

- `ledger_entry_id`
- `assignment_id`
- `ticket`
- `agent_profile_id`
- `budget_policy_id`
- `provider_id`
- `model_policy`
- `phase`
- `recorded_at`
- `prompt_tokens`
- `completion_tokens`
- `total_tokens`
- `estimated_cost_units`
- `actual_cost_units`
- `limit_state`
- `human_gate_required`
- `evidence`

## Forbidden fields

- `raw_provider_invoice`
- `billing_api_secret`
- `card_number`
- `provider_account_secret`
- `plaintext_token`
- `runtime_command_output`

## Policies

### Frontier engineering

- Policy id: `budget:frontier-engineering`
- Applies to: `codex_frontier_engineer`
- Max agents: `2`
- Max wall time minutes: `180`
- Max total tokens: `420000`
- Max estimated cost units: `100`
- Human Gate above cost units: `40`

### Medium implementation slice

- Policy id: `budget:medium-slice`
- Applies to: `claude_code_mapper`
- Max agents: `3`
- Max wall time minutes: `90`
- Max total tokens: `250000`
- Max estimated cost units: `45`
- Human Gate above cost units: `20`

### Verification

- Policy id: `budget:verification`
- Applies to: `artemis_verifier`
- Max agents: `2`
- Max wall time minutes: `60`
- Max total tokens: `150000`
- Max estimated cost units: `20`
- Human Gate above cost units: `10`

## Enforcement rules

- A Run Assignment must bind a known budget policy before launcher preflight.
- Budget approval is not runtime execution permission.
- Human Gate is required when estimated cost exceeds policy threshold.
- Runtime must stop when max_total_tokens, max_wall_time_minutes or max_agents is exceeded.
- Ledger entries are append-only and must reference assignment id, ticket and evidence.
- Actual provider billing reconciliation is future work and must not store secrets or raw billing credentials.
- Remote writes remain blocked even when budget is approved.

## Validation

- `run_assignment_ready`: passed - Budget Ledger consumes an accepted Run Assignment before defining spend limits.
- `budget_policy_bound`: passed - The assignment budget policy resolves to a concrete limit policy.
- `ledger_schema_declared`: passed - Append-only cost ledger fields and forbidden billing/secret fields are declared.
- `no_runtime_spend`: passed - This cut records policy and zero-spend fixture data only.
- `hard_limits_present`: passed - Every budget policy has hard stop behavior for runtime enforcement.
- `no_secret_values_recorded`: passed - No provider secrets, payment data or raw billing credentials are stored.
