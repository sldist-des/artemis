# ARTEMIS Portal Runtime Session Contract

- Overall: `blocked`
- Runtime execution allowed: `false`
- Runtime session started: `false`
- Runtime auth executed: `false`
- Vault lease issued: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-079 - ARTEMIS Portal Agent Conversation Contract`

## Regra central

Nenhuma sessao de runtime do portal pode iniciar agente sem Workspace Session pronta, lease policy, launcher preflight, command plan, execution gate, budget/cost ledger e Human Gate quando aplicavel.

## Session required fields

- `runtime_session_id`
- `workspace_session_id`
- `assignment_id`
- `project_id`
- `ticket`
- `agent_profile_id`
- `provider_id`
- `adapter`
- `runtime_surface`
- `credential_lease_policy_id`
- `workspace_policy_id`
- `budget_policy_id`
- `supervision_policy_id`
- `command_boundary`
- `heartbeat_policy`
- `transcript_policy`
- `stop_rules`
- `validation_policy_id`
- `opened_at`
- `expires_at`
- `session_state`
- `evidence`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `provider_billing_secret`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `full_prompt_transcript`
- `git_remote_token`
- `ssh_private_key`

## Lifecycle gates

- `workspace_session_ready`
- `budget_ledger_bound`
- `credential_lease_policy_bound`
- `launcher_preflight_present`
- `command_plan_required`
- `human_execution_gate_required`
- `validation_policy_bound`
- `cost_ledger_update_required`
- `completion_handoff_required`

## Stop rules

- Stop before any secret request or plaintext credential exposure.
- Stop before any command outside the approved command plan.
- Stop before remote write unless a separate Human Gate allows it.
- Stop when budget, token, agent-count or duration limits are reached.
- Stop when forbidden paths are touched.
- Stop when dirty-worktree conflict is detected.
- Stop on validation failure if no approved retry policy exists.
- Stop immediately on human stop request.

## Enforcement rules

- Runtime Session must consume a ready Workspace Session.
- Runtime Session must reference a launcher preflight artifact before command planning.
- Credential lease policy may be bound, but no real lease is issued in this cut.
- Runtime Session approval is not command execution permission.
- A command plan and execution gate remain required before any real agent command.
- Every runtime state transition must write an event and cost/usage evidence.
- Raw secrets, provider tokens, private keys, raw stdout/stderr and full prompt transcripts are forbidden in git artifacts.

## Validation

- `workspace_session_ready`: failed - Runtime Session consumes a ready Workspace Session.
- `launcher_preflight_present`: passed - Runtime Session can reference launcher preflight evidence.
- `preflight_does_not_allow_runtime`: passed - Existing launcher preflight artifact still blocks runtime execution until Human Gate.
- `credential_vault_contract_present`: passed - Runtime Session references the Credential Vault contract without issuing a lease.
- `supervision_policy_declared`: passed - Heartbeat, event stream, human stop and transcript policy are declared.
- `command_boundary_declared`: passed - Runtime commands must come from a future exact command plan.
- `no_runtime_execution`: passed - This cut records runtime session policy only and cannot execute commands.
- `no_secret_values_recorded`: passed - No provider secrets, project secrets, raw stdout/stderr or full prompt transcripts are stored.
