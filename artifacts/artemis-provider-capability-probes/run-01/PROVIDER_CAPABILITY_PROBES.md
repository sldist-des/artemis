# ARTEMIS Provider Capability Probes

## Resultado

- Overall: `provider_capability_probes_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-112 - Model Migration Gate`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Probes

- `codex`: detected codex-cli 0.132.0
- `claude_code`: detected 2.1.139 (Claude Code)
- `antigravity_cli`: detected 1.0.0
