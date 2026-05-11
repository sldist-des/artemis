# VALIDATION

## Resultado local

- Overall: `ready_with_human_gates`.
- Application ready: `true`.
- Tasks: `64/64 done`.
- Validation technical failures: `0`.

## Comandos de verificacao

- `scripts/artemis-application-readiness.sh --artifact-root artifacts/artemis-application-readiness/run-01 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Blockers

- Nenhum blocker tecnico local.

## Warnings

- Nenhum warning local.
