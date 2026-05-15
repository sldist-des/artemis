# ARTEMIS Portal Task Control Surface Contract

- Overall: `task_control_surface_ready`
- Controls triggered: `0`
- Task state mutated: `false`
- Messages sent to provider: `0`
- Runtime execution allowed: `false`
- Runtime session started: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract`

## Regra central

Task controls tornam intents visiveis e auditaveis, mas nao mudam estado canonico, nao iniciam runtime e nao executam comandos sem gates separados.

## Control required fields

- `control_id`
- `project_id`
- `ticket`
- `conversation_id`
- `runtime_session_id`
- `assignment_id`
- `control_kind`
- `label`
- `current_task_state`
- `requested_transition`
- `actor_type`
- `actor_id`
- `authority_level`
- `gate_requirement`
- `validation_requirement`
- `budget_impact`
- `command_plan_ref`
- `event_refs`
- `evidence`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `raw_prompt`
- `full_prompt_transcript`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `git_remote_token`
- `ssh_private_key`
- `unreviewed_command`
- `auto_execute_flag`

## Control kinds

- `view_task`
- `assign_task_intent`
- `request_agent_status`
- `request_validation`
- `open_human_gate`
- `pause_runtime_session`
- `stop_runtime_session`
- `request_handoff_review`

## Blocked without gate

- `start_runtime`
- `execute_command`
- `push_remote`
- `deploy_production`
- `read_secret`
- `increase_budget`
- `change_branch_protection`
- `mark_done_without_validation`

## Enforcement rules

- Task controls are visible intent controls, not direct execution authority.
- Controls that affect runtime, commands, remote writes, secrets or budget must route to Human Gate or runtime gates.
- A task control can create an event and evidence record, but cannot mutate canonical task state by itself.
- Disabled controls must show the missing gate, validation or budget dependency.
- Done transitions require validation evidence and completion review before ledger update.
- Stop controls have priority over new task assignment or runtime start controls.
- Raw prompts, full transcripts, secrets and raw runtime output are forbidden in task-control artifacts.

## Validation

- `agent_conversation_ready`: passed - Task Control Surface consumes a ready Agent Conversation contract.
- `control_schema_declared`: passed - Control fields and forbidden raw/secret fields are declared.
- `gated_controls_declared`: passed - Runtime, command, remote write, secret and budget controls are blocked without gates.
- `ui_policy_declared`: passed - Disabled controls must show missing gate, validation or budget dependency.
- `event_bridge_declared`: passed - Task-control events are canonical and do not mutate task state.
- `no_task_state_mutation`: passed - This cut records the contract only and triggers no task control.
- `no_runtime_execution`: passed - Task controls cannot start runtime or execute commands in this cut.
- `no_secret_values_recorded`: passed - No secrets, raw prompts, raw runtime output or full transcripts are stored.
