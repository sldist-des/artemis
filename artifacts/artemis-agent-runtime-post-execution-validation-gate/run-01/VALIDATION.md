# ARTEMIS AGENT RUNTIME POST-EXECUTION VALIDATION GATE VALIDATION

- Overall: `human_gate`
- Post-validation state: `waiting_for_execution_result_intake_ready`
- Intake ready: `false`
- Execute requested: `false`
- Validations executed: `0`
- Human Gate: `1`

## Checks

- `execution_result_intake_exists`: `passed` - artifacts/artemis-agent-runtime-execution-result-intake/run-01/execution-result-intake.json
- `execution_result_intake_ready`: `human_gate` - overall=human_gate result_ready=False
- `plan_only_not_validated`: `passed` - intake_ready=false validations_executed=0
- `runtime_logs_available`: `passed` - logs=0 commands_executed=0
- `validation_commands_declared`: `passed` - required=false commands=0
- `rollback_state_reviewed`: `passed` - rollback_required=false rollback_keys=2
- `remote_writes_blocked`: `passed` - remote=false production=false secrets=false
