# VALIDATION

## Resultado local

- Overall: `runner_plan_ready`.
- Ticket in dispatch plan: `true`.
- Runner planned: `true`.
- Execute requested: `false`.
- Commands executed: `0`.
- Automatic daemon: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-bridge.sh --input artifacts/artemis-symphony-queue-bridge/run-01/fixtures/task-source.json --ticket TKT-947 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-bridge/run-01/fixtures/task-source.json" --artifact-root artifacts/artemis-symphony-queue-bridge/run-01/bridge --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
