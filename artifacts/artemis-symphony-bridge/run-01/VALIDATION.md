# VALIDATION

## Resultado local

- Overall: `runner_plan_ready`.
- Ticket in dispatch plan: `true`.
- Runner planned: `true`.
- Execute requested: `false`.
- Commands executed: `0`.
- Automatic daemon: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-bridge.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json" --artifact-root artifacts/artemis-symphony-bridge/run-01 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
