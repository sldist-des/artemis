# VALIDATION

## Resultado local

- Overall: `heartbeat_ready`.
- Ticks completed: `2`.
- Heartbeat: `artifacts/artemis-symphony-daemon/run-01/heartbeat.json`.
- Heartbeat log: `artifacts/artemis-symphony-daemon/run-01/heartbeat.jsonl`.
- Commands executed: `0`.
- Runner auto execution allowed: `false`.
- Bridge called: `false`.
- Long-running process started: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-daemon.sh --input control-plane/tasks.json --artifact-root artifacts/artemis-symphony-daemon/run-01 --ticks 2 --interval 0 --max-concurrency 1 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
