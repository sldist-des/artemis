# VALIDATION

## Entradas validadas

- Pending gate: `artifacts/artemis-human-decision-pending-gate/run-01/human-decision-pending-gate.json`.
- Intake: `artifacts/artemis-human-decision-intake/run-01/human-decision-intake.json`.
- Decision file: `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`.

## Comandos apos preenchimento humano

- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01/approval-contract --json`
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01/cleanup-dry-run --json`
- `scripts/artemis-human-decision-intake.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01 --json`
- `scripts/artemis-human-decision-pending-gate.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-pending-gate/run-01 --json`
- `scripts/artemis-human-decision-reentry-contract.sh --pending-gate-root artifacts/artemis-human-decision-pending-gate/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-reentry-contract/run-01 --json`
- `scripts/validate-artemis.sh`

## Resultado local

Contrato registrado como `human_gate` com `preflight_allowed=false` e `cleanup_execution_allowed=false`.

## Verificacoes executadas neste corte

- `scripts/artemis-human-decision-reentry-contract.sh --artifact-root artifacts/artemis-human-decision-reentry-contract/run-01 --json`: `overall=human_gate`, `pending=3`, `preflight_allowed=false`, `cleanup_execution_allowed=false`.
- `scripts/validate-artemis.sh`: `ARTEMIS validation passed`.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: `passed=46`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: evento ativo `evt_tkt-039_task_discovered`; Validation Gate referenciado com `passed=46`, `failed=0`, `human_gate=2`.
- `scripts/artemis-dry-run.sh --input control-plane/tasks.json --json`: `eligible=1`, `blocked=0`, `human_gate=0`, `done=39`.
- `git diff --check`: sem whitespace errors.
- Control Plane smoke: `/tmp/artemis-tkt038-control-plane.png`.

## Gaps

- Nenhuma decisao humana real foi preenchida por este script.
- Nenhum preflight supervisionado foi executado.
- Nenhum cleanup real foi executado.
- Nenhum comando com `--execute` foi emitido.
