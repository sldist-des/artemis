# VALIDATION

## Resultado local

- Overall: `human_gate`.
- GitHub adapter: `human_gate`.
- Tasks generated: `0`.
- Remote writes allowed: `false`.
- Runner auto execution allowed: `false`.
- Commands executed: `0`.

## Comandos

- `scripts/artemis-symphony-remote-source.sh --artifact-root artifacts/artemis-symphony-remote-source/run-01 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`
