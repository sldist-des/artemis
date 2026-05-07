# VALIDATION

## Resultado local

- Overall: `heartbeat_ready`.
- Ticks completed: `1`.
- Heartbeat: `artifacts/artemis-symphony-service/run-01/daemon/heartbeat.json`.
- Heartbeat log: `artifacts/artemis-symphony-service/run-01/daemon/heartbeat.jsonl`.
- Commands executed: `0`.
- Runner auto execution allowed: `false`.
- Bridge called: `false`.
- Long-running process started: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-daemon.sh --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json --artifact-root artifacts/artemis-symphony-service/run-01/daemon --ticks 1 --interval 0 --max-concurrency 1 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
