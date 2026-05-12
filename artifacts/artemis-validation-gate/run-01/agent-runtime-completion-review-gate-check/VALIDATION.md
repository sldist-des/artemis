# ARTEMIS AGENT RUNTIME COMPLETION REVIEW GATE VALIDATION

- Overall: `human_gate`
- Review state: `waiting_for_completion_handoff_ready`
- Human Gate: `1`

## Checks

- `completion_handoff_exists`: `passed` - artifacts/artemis-validation-gate/run-01/agent-runtime-completion-handoff-check/completion-handoff.json
- `completion_handoff_ready`: `human_gate` - overall=human_gate ready=False
- `human_decision_record_exists`: `passed` - artifacts/artemis-validation-gate/run-01/agent-runtime-completion-review-gate-check/completion-review-decision.json
- `human_decision_pending_or_valid`: `passed` - decision=pending
- `done_not_authorized_without_human_acceptance`: `passed` - accepted_ready=false done_authorized=False
- `runtime_and_validation_evidence_reviewed`: `passed` - commands_executed=0 validations_executed=0
- `remote_close_blocked`: `passed` - remote_close_authorized=False
