# VALIDATION

## Resultado

- Overall: `runner_executed`.
- Queue item found: `true`.
- Bridge planned: `true`.
- Execute requested: `true`.
- Commands executed: `1`.
- Runner executed: `true`.
- Validation Gate passed: `true`.
- Approval exact: `true`.
- Validation Gate required before execute: `true`.

## Comando

- `scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-queue/run-01/symphony-queue.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json" --artifact-root artifacts/artemis-symphony-queue-execution/run-01 --execute --validation-gate artifacts/artemis-validation-gate/run-01/queue-bridge-validation-gate-fixture.json --decision artifacts/artemis-validation-gate/run-01/queue-bridge-decision-fixture.json --json`
