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

- `scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-service/run-01/queue/symphony-queue.json --ticket TKT-949 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json" --artifact-root artifacts/artemis-symphony-service/run-01/queue-bridge --json`
