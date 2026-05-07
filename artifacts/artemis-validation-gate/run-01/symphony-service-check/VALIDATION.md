# VALIDATION

## Resultado local

- Overall: `service_bridge_plan_ready`.
- Daemon overall: `heartbeat_ready`.
- Queue overall: `queue_ready`.
- Queue bridge overall: `bridge_plan_ready`.
- Commands executed: `0`.
- Execute requested: `false`.
- Execute supported by service: `false`.
- Runner auto execution allowed: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-service.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json --artifact-root artifacts/artemis-validation-gate/run-01/symphony-service-check --ticks 1 --interval 0 --max-concurrency 1 --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json" --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
