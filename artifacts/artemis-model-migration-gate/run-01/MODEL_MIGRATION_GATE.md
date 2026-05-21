# ARTEMIS Model Migration Gate

## Resultado

- Overall: `model_migration_gate_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-113 - Provider Operational Evals`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Gate

- Default state: `waiting_for_external_model_review`
- Migration allowed: `false`
- Human decision required: `true`
