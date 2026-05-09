# VALIDATION

## Resultado local

- Overall: `remote_promotion_human_gate`.
- Promoted source tasks: `0`.
- Direct dispatch allowed: `false`.
- Remote writes allowed: `false`.
- Queue called: `false`.
- Bridge called: `false`.
- Runner called: `false`.
- Commands executed: `0`.

## Comandos

- `scripts/artemis-symphony-remote-promotion.sh --remote-intake artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json --decision <decision.json> --artifact-root artifacts/artemis-symphony-promotion/run-01 --json`
- `scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-promotion/run-01/promoted-source.json --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`
