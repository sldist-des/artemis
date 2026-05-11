# ARTEMIS AGENT RUNTIME LAUNCHER PREFLIGHT VALIDATION

- Overall: `human_gate`
- Decision intake ready: `false`
- Preflight checks: `5`
- Passed: `4`
- Failed: `0`
- Human Gate: `1`
- Launcher execution allowed: `false`
- Runtime execution allowed: `false`
- Commands executed: `0`
- Remote writes allowed: `false`

## Checks

- `decision_intake_exists`: `passed` - artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json
- `decision_intake_ready`: `human_gate` - overall=human_gate intake_state=pending
- `runtime_not_started`: `passed` - runtime_started=False
- `commands_not_executed`: `passed` - commands_executed=0
- `remote_writes_blocked`: `passed` - remote_writes_allowed=False
