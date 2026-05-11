# ARTEMIS AGENT RUNTIME EXECUTION RESULT INTAKE VALIDATION

- Overall: `human_gate`
- Intake state: `waiting_for_supervised_execution_result`
- Result ready: `false`
- Commands executed: `0`
- Failed commands: `0`
- Human Gate: `1`

## Checks

- `supervised_execution_exists`: `passed` - artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json
- `plan_only_not_success`: `passed` - attempt_planned=true result_ready=false
- `supervised_execution_completed`: `human_gate` - overall=human_gate executed=false
- `command_results_classified`: `passed` - commands_executed=0 failed_commands=0
- `validation_evidence_required`: `passed` - required_before_done=None
- `rollback_state_classified`: `passed` - rollback_required=false preserve_logs=None
- `remote_writes_blocked`: `passed` - remote=false production=false secrets=false
