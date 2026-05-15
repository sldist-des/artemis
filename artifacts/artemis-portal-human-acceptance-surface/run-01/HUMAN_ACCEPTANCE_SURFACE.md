# ARTEMIS Portal Human Acceptance Surface Contract

- Overall: `human_acceptance_surface_ready`
- Acceptance state: `blocked_by_human_gate_ack`
- Validation passed: `129`
- Validation failed: `0`
- Human gates: `2`
- Acceptance recorded: `false`
- Accepted: `false`
- Done Ledger handoff allowed: `false`
- Task state mutated: `false`
- Runtime execution allowed: `false`
- Runtime session started: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `NONE - ARTEMIS Portal supervised control spine complete`

## Regra central

Aceite humano decide, mas nao acontece de forma implicita. Agentes podem preparar resumo e handoff; somente o humano owner pode aceitar, rejeitar ou deferir.

## Acceptance required fields

- `acceptance_surface_id`
- `project_id`
- `ticket`
- `evidence_surface_id`
- `validation_gate_ref`
- `completion_review_gate_ref`
- `done_ledger_ref`
- `decision`
- `decided_by`
- `decision_authority`
- `reason`
- `accepted_evidence_refs`
- `rejected_evidence_refs`
- `deferred_blocker_refs`
- `residual_risk_acknowledged`
- `human_gate_acknowledged`
- `done_ledger_handoff_allowed`
- `event_refs`
- `decided_at`

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
- `provider_secret`
- `git_remote_token`
- `ssh_private_key`
- `unredacted_user_data`
- `auto_accept_flag`
- `background_approval`
- `implicit_acceptance`

## Decision model

- `accepted`
- `rejected`
- `deferred`
- `needs_more_evidence`
- `blocked_by_human_gate`

## Enforcement rules

- Evidence can recommend readiness, but only a human owner can accept.
- No acceptance is recorded by this contract fixture.
- Accepted cannot be available while failed checks exist.
- Human Gates must be acknowledged explicitly before accepted can feed Done Ledger.
- Reject and defer decisions must preserve reason or blocker references.
- Agents can prepare summaries and handoffs but cannot approve their own work.
- Done Ledger handoff remains blocked until a real accepted decision exists.

## Validation

- `validation_evidence_surface_ready`: passed - Human Acceptance Surface consumes a ready Validation Evidence Surface contract.
- `acceptance_schema_declared`: passed - Acceptance fields and forbidden raw/secret/implicit acceptance fields are declared.
- `authority_model_declared`: passed - Agents can prepare evidence but cannot approve or mark done.
- `failed_checks_gate_declared`: passed - Acceptance is disabled while failed checks exist.
- `human_gate_ack_required`: passed - Human Gates require explicit human acknowledgement before acceptance.
- `done_ledger_handoff_blocked`: passed - Done Ledger handoff remains blocked because no real acceptance was recorded.
- `no_runtime_execution`: passed - Human acceptance contract cannot start runtime or execute commands in this cut.
- `no_acceptance_recorded`: passed - This cut defines acceptance semantics but records no real acceptance.
- `no_task_state_mutation`: passed - No task state, remote state or Done Ledger state is mutated.
- `no_secret_values_recorded`: passed - No secrets, raw prompts, raw runtime output or full transcripts are stored.
