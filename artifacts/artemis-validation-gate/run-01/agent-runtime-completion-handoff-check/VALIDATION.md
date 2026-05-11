# ARTEMIS AGENT RUNTIME COMPLETION HANDOFF VALIDATION

- Overall: `human_gate`
- Handoff state: `waiting_for_post_execution_validation_completed`
- Human Gate: `1`

## Checks

- `post_execution_validation_gate_exists`: `passed` - artifacts/artemis-validation-gate/run-01/agent-runtime-post-execution-validation-gate-check/post-execution-validation-gate.json
- `post_execution_validation_completed`: `human_gate` - overall=human_gate completed=False
- `completion_not_done_without_validation`: `passed` - post_completed=false ready_for_done=false
- `runtime_result_classified`: `passed` - commands_executed=0 failed_commands=0
- `validation_evidence_classified`: `passed` - validations_executed=0 validation_results=0
- `rollback_state_classified`: `passed` - rollback_required=false rollback_keys=2
- `remote_writes_blocked`: `passed` - remote=false production=false secrets=false
