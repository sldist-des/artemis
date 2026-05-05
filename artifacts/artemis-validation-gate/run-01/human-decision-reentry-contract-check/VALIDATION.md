# VALIDATION

## Entradas validadas

- Pending gate: `artifacts/artemis-validation-gate/run-01/human-decision-pending-gate-check/human-decision-pending-gate.json`.
- Intake: `artifacts/artemis-validation-gate/run-01/human-decision-intake-check/human-decision-intake.json`.
- Decision file: `artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json`.

## Comandos apos preenchimento humano

- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01/approval-contract --json`
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01/cleanup-dry-run --json`
- `scripts/artemis-human-decision-intake.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01 --json`
- `scripts/artemis-human-decision-pending-gate.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-pending-gate/run-01 --json`
- `scripts/artemis-human-decision-reentry-contract.sh --pending-gate-root artifacts/artemis-human-decision-pending-gate/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-validation-gate/run-01/human-decision-reentry-contract-check --json`
- `scripts/validate-artemis.sh`

## Resultado local

Contrato registrado como `human_gate` com `preflight_allowed=false` e `cleanup_execution_allowed=false`.

## Gaps

- Nenhuma decisao humana real foi preenchida por este script.
- Nenhum preflight supervisionado foi executado.
- Nenhum cleanup real foi executado.
- Nenhum comando com `--execute` foi emitido.
