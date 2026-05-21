# ARTEMIS Model/API Documentation Radar

## Resultado

- Overall: `model_api_documentation_radar_ready`
- Providers: `3`
- Capability roles: `5`
- Runtime auth executed: `false`
- Provider API calls executed: `0`
- Agents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-116 - Model/API Change Intake`

## Invariantes

- Model names are runtime bindings, not method authority.
- Capability roles remain the routing contract.
- Official docs refresh is required before default model/API changes.
- Human Gate is required before changing default provider routing.
- No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.

## Radar State

- Documentation radar state: `waiting_for_official_docs_review`
- External fetch executed: `false`
- Migration allowed: `false`

## Required Sources

- `local_antigravity_cli_version`: artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json
- `local_claude_cli_version`: artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json
- `local_codex_cli_version`: artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json
- `official_antigravity_cli_docs`: https://antigravity.google/docs/cli-using
- `official_claude_code_docs`: https://code.claude.com/docs
- `official_openai_codex_docs`: https://developers.openai.com/codex
- `provider_sdk_release_notes`: provider_official_release_notes
- `repo_AGENTS_model_contract`: AGENTS.md
