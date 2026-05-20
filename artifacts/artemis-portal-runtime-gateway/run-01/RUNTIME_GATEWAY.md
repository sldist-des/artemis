# ARTEMIS Portal Runtime Gateway Contract

- Overall: `runtime_gateway_ready`
- Panel can start runtime: `false`
- Runtime gateway required: `true`
- Secret values recorded: `false`
- Runtime auth executed: `false`
- Runtime session started: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-084 - ARTEMIS Portal Runtime Gateway Read-only Service`

## Regra simples

O painel nao fala direto com Codex, Claude Code ou Antigravity. O painel fala com o Runtime Gateway, e o Gateway so libera runtime depois de projeto, operador, auth, budget, workspace, command plan, Human Gate e validacao.

## Operadores

### Codex app-server

- Operator id: `codex_app_server`
- Provider: `openai_codex`
- Adapter: `codex_app_server`
- Runtime surface: `app_server`
- Connection state: `planned_not_connected`
- Auth state: `requires_provider_connection_and_vault_lease`
- Human execution gate required: `true`

Best for:

- long implementation.
- complex refactor.
- frontier reasoning.
- supervised approvals and artifacts.

Forbidden before gate:

- `start_without_gate`
- `receive_raw_secret`
- `run_unplanned_command`
- `remote_write_without_gate`
- `store_raw_stdout`
- `store_full_prompt_transcript`

### Claude Code

- Operator id: `claude_code`
- Provider: `anthropic_claude`
- Adapter: `claude_agent_sdk`
- Runtime surface: `cli_or_sdk`
- Connection state: `planned_not_connected`
- Auth state: `requires_provider_connection_and_vault_lease`
- Human execution gate required: `true`

Best for:

- repository mapping.
- language and framework orientation.
- short to medium implementation slices.
- handoff drafting.

Forbidden before gate:

- `start_without_gate`
- `receive_raw_secret`
- `run_unplanned_command`
- `remote_write_without_gate`
- `store_raw_stdout`
- `store_full_prompt_transcript`

### Antigravity CLI

- Operator id: `antigravity_cli`
- Provider: `antigravity`
- Adapter: `antigravity_cli`
- Runtime surface: `cli_unverified`
- Connection state: `unverified_adapter`
- Auth state: `blocked_until_capability_discovery`
- Human execution gate required: `true`

Best for:

- future operator adapter.
- experimental runtime after local discovery.
- only bounded tasks after contract review.

Forbidden before gate:

- `available_before_discovery`
- `start_without_gate`
- `receive_raw_secret`
- `run_unplanned_command`
- `remote_write_without_gate`
- `store_raw_stdout`
- `store_full_prompt_transcript`

## Portal operations allowed before gate

- `list_projects`
- `list_registered_operators`
- `show_connection_state`
- `create_draft_task`
- `draft_assignment`
- `draft_command_plan`
- `request_human_gate`
- `show_planned_budget`
- `show_validation_evidence`

## Portal operations forbidden before gate

- `send_prompt_to_provider`
- `start_runtime`
- `execute_command`
- `spend_tokens`
- `open_runtime_websocket`
- `remote_write`
- `push_branch`
- `open_pr`
- `deploy`
- `store_secret`
- `store_raw_runtime_logs`

## Checks

- `runtime_session_contract_ready`: passed - Gateway consumes Runtime Session before any provider launch.
- `agent_registry_contract_ready`: passed - Gateway operators are derived from registered/provider-aware profiles.
- `credential_vault_contract_ready`: passed - Gateway requires vault lease policy and never stores raw secrets.
- `multi_operator_adapters_declared`: passed - Codex app-server, Claude Code and Antigravity CLI adapter slots are declared.
- `experimental_adapter_blocked`: passed - Antigravity remains blocked until capability discovery confirms the local CLI contract.
- `no_runtime_side_effects`: passed - No auth, runtime session, agent launch, token spend, command execution or remote mutation happened.
- `gateway_required_before_panel_execution`: passed - Control Plane cannot directly start providers; it must pass through the Gateway.
