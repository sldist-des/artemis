# VALIDATION

## Resultado local

- Overall: `idle`.
- Tasks total: `49`.
- Eligible: `0`.
- Selected for dispatch: `0`.
- Max concurrency: `1`.
- Commands executed: `0`.
- Runner execution allowed: `false`.

## Comandos de verificacao

- `scripts/artemis-symphony-kernel.sh --input control-plane/tasks.json --artifact-root artifacts/artemis-symphony-kernel/run-01 --max-concurrency 1 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
