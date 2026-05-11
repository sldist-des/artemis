# ARTEMIS AGENT RUNTIME LAUNCHER SUPERVISED EXECUTION VALIDATION

- Overall: `human_gate`
- Launcher execution gate ready: `false`
- Execute requested: `false`
- Commands executed: `0`
- Failed: `0`
- Human Gate: `1`

## Checks

- `launcher_execution_gate_exists`: `passed` - artifacts/artemis-validation-gate/run-01/agent-runtime-launcher-execution-gate-check/launcher-execution-gate.json
- `launcher_execution_gate_ready`: `human_gate` - overall=human_gate gate_state=waiting_for_launcher_command_plan_ready
- `upstream_commands_not_executed`: `passed` - commands_executed=0
- `remote_writes_blocked`: `passed` - remote_writes_allowed=False
- `production_blocked`: `passed` - production_allowed=False
- `secrets_blocked`: `passed` - secrets_allowed=False
