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

- `scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-queue-execution/run-01/queue/symphony-queue.json --ticket TKT-948 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json" --artifact-root artifacts/artemis-symphony-queue-execution/run-01 --execute --validation-gate artifacts/artemis-symphony-queue-execution/run-01/fixtures/validation-gate.json --decision artifacts/artemis-symphony-queue-execution/run-01/fixtures/decision.json --json`
