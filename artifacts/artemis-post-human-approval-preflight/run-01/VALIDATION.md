# VALIDATION

## Entradas validadas

- Reentry contract: `artifacts/artemis-human-decision-reentry-contract/run-01/human-decision-reentry-contract.json`.
- Intake: `artifacts/artemis-human-decision-intake/run-01/human-decision-intake.json`.
- Decision file: `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`.

## Comandos apos preenchimento humano

- `scripts/artemis-human-decision-intake.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-intake/run-01 --json`
- `scripts/artemis-human-decision-reentry-contract.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-human-decision-reentry-contract/run-01 --json`
- `scripts/artemis-post-human-approval-preflight.sh --reentry-root artifacts/artemis-human-decision-reentry-contract/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-post-human-approval-preflight/run-01 --json`
- `scripts/validate-artemis.sh`

## Resultado local

Preflight registrado como `human_gate` com `supervised_preflight_allowed=false` e `cleanup_execution_allowed=false`.

## Verificacoes executadas neste corte

- `scripts/artemis-post-human-approval-preflight.sh --artifact-root artifacts/artemis-post-human-approval-preflight/run-01 --json`: `overall=human_gate`, `pending=3`, `supervised_preflight_allowed=false`, `cleanup_execution_allowed=false`.
- `scripts/artemis-tasks.sh`: `total=40`, `done=40`, nenhuma tarefa ativa.
- `scripts/artemis-dry-run.sh --input control-plane/tasks.json --json`: `eligible=0`, `blocked=0`, `human_gate=0`, `done=40`.
- `scripts/validate-artemis.sh`: `ARTEMIS validation passed`.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: `passed=48`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: `events=18`, Validation Gate com `passed=48`, `failed=0`, `human_gate=2`.
- `git diff --check`: sem whitespace errors.
- Control Plane smoke: `/tmp/artemis-tkt039-control-plane.png`.

## Gaps

- Nenhuma decisao humana real foi preenchida por este script.
- Nenhum executor supervisionado foi executado.
- Nenhum cleanup real foi executado.
- Nenhum comando com `--execute` foi emitido.
