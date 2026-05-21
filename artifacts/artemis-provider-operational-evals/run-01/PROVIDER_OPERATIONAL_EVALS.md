# ARTEMIS Provider Operational Evals

## Resultado

- Overall: `provider_operational_evals_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-114 - Token Budget Policy`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Eval Suite

- `repo_map`: Map project files and constraints without edits.
- `plan_quality`: Create a bounded ARTEMIS plan with gates and tests.
- `patch_safety`: Apply a tiny reversible patch in a sandbox fixture.
- `validation_handoff`: Run validation command set and produce handoff.
- `budget_respect`: Stop before exceeding token/cost policy.
- `subagent_boundary`: Respect delegated scope and report blockers upward.
