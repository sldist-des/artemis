# VALIDATION

## Resultado local

- Overall: `dispatch_plan_ready`.
- Tasks total: `1`.
- Eligible: `1`.
- Selected for dispatch: `1`.
- Max concurrency: `1`.
- Commands executed: `0`.
- Runner execution allowed: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-kernel.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json --artifact-root artifacts/artemis-symphony-queue-execution/run-01/bridge/kernel --max-concurrency 1 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
