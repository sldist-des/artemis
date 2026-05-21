# ARTEMIS Token Budget Policy

## Resultado

- Overall: `model_token_budget_policy_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-115 - Model/API Documentation Radar`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Budget Classes

- `fast_probe`: max `50000` tokens
- `verification_slice`: max `150000` tokens
- `standard_slice`: max `250000` tokens
- `frontier_guarded`: max `420000` tokens
- `supervised_async`: max `600000` tokens
