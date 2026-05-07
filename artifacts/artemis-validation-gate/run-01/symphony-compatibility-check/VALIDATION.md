# VALIDATION

## Resultado local

- Overall: `spec_ready`.
- Layers: `17`.
- Layers with missing files: `0`.
- Tasks: `53/53 done`.
- Next cut defined: `true`.

## Comandos de verificacao

- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Blockers

- Nenhum blocker tecnico local.
