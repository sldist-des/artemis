# ARTEMIS Model/API Governance Registry

## Resultado

- Overall: `model_api_governance_registry_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-111 - Provider Capability Probes`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Capability Roles

- `frontier_reasoning`: Architecture, critical planning, high-risk code review and final synthesis.
- `fast_code_explorer`: Repository mapping, file discovery, symbol search and short synthesis.
- `standard_code_worker`: Bounded implementation slices with tests and handoff evidence.
- `verifier`: Independent validation, regression checks, evidence review and done criteria.
- `async_orchestrator`: Supervised long-running orchestration only after explicit human and budget gates.
