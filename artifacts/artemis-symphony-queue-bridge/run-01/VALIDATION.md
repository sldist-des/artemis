# VALIDATION

## Resultado

- Overall: `bridge_plan_ready`.
- Queue item found: `true`.
- Bridge planned: `true`.
- Execute requested: `false`.
- Commands executed: `0`.
- Runner executed: `false`.
- Validation Gate passed: `false`.
- Approval exact: `false`.
- Validation Gate required before execute: `true`.

## Comando

- `scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-queue/run-01/symphony-queue.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json" --artifact-root artifacts/artemis-symphony-queue-bridge/run-01 --json`
