# VALIDATION

## Resultado local

- Overall: `queue_ready`.
- Queue items: `1`.
- Review required: `1`.
- Commands executed: `0`.
- Bridge called: `false`.
- Runner called: `false`.
- Runner auto execution allowed: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-queue.sh --daemon artifacts/artemis-validation-gate/run-01/symphony-service-check/daemon/symphony-daemon.json --artifact-root artifacts/artemis-validation-gate/run-01/symphony-service-check/queue --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
