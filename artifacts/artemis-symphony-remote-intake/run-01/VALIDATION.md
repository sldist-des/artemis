# VALIDATION

## Resultado local

- Overall: `remote_intake_ready`.
- Review source state: `human`.
- Promotion allowed: `0`.
- Direct dispatch allowed: `false`.
- Remote writes allowed: `false`.
- Commands executed: `0`.

## Comandos

- `scripts/artemis-symphony-remote-intake.sh --remote-source artifacts/artemis-symphony-remote-source/run-01/remote-source.json --artifact-root artifacts/artemis-symphony-remote-intake/run-01 --json`
- `scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-remote-intake/run-01/review-source.json --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`
