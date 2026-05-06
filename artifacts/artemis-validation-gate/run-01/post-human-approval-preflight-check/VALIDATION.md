# VALIDATION

## Entradas validadas

- Reentry contract: `artifacts/artemis-validation-gate/run-01/human-decision-reentry-contract-check/human-decision-reentry-contract.json`.
- Intake: `artifacts/artemis-validation-gate/run-01/human-decision-intake-check/human-decision-intake.json`.
- Decision file: `artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json`.

## Comandos apos preenchimento humano

- `scripts/artemis-human-decision-intake.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01 --json`
- `scripts/artemis-human-decision-reentry-contract.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-reentry-contract/run-01 --json`
- `scripts/artemis-post-human-approval-preflight.sh --reentry-root artifacts/artemis-human-decision-reentry-contract/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-validation-gate/run-01/post-human-approval-preflight-check --json`
- `scripts/validate-artemis.sh`

## Resultado local

Preflight registrado como `human_gate` com `supervised_preflight_allowed=false` e `cleanup_execution_allowed=false`.

## Gaps

- Nenhuma decisao humana real foi preenchida por este script.
- Nenhum executor supervisionado foi executado.
- Nenhum cleanup real foi executado.
- Nenhum comando com `--execute` foi emitido.
