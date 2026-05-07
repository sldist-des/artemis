# VALIDATION

## Resultado local

- Overall: `memory_zone_ready`.
- Required files missing: `0`.
- Commands executed: `0`.
- Remote writes allowed: `false`.

## Comandos

- `scripts/artemis-memory-zone.sh --artifact-root artifacts/artemis-validation-gate/run-01/memory-zone-check --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`
