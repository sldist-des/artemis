# VALIDATION

## Resultado local

- Overall: `heartbeat_ready`.
- Ticks completed: `2`.
- Heartbeat: `artifacts/artemis-validation-gate/run-01/symphony-daemon-check/heartbeat.json`.
- Heartbeat log: `artifacts/artemis-validation-gate/run-01/symphony-daemon-check/heartbeat.jsonl`.
- Commands executed: `0`.
- Runner auto execution allowed: `false`.
- Bridge called: `false`.
- Long-running process started: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-daemon.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json --artifact-root artifacts/artemis-validation-gate/run-01/symphony-daemon-check --ticks 2 --interval 0 --max-concurrency 1 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
