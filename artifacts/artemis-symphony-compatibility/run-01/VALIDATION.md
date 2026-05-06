# VALIDATION

## Resultado local

- Overall: `spec_ready`.
- Layers: `9`.
- Layers with missing files: `0`.
- Tasks: `42/42 done`.
- Next cut defined: `true`.

## Comandos de verificacao

- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Verificacoes executadas neste corte

- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`: `overall=spec_ready`, `layers_total=9`, `layers_with_missing_files=0`, `tasks_done=42/42`, `next_cut_defined=true`.
- `scripts/artemis-tasks.sh`: `total=42`, `done=42`, nenhuma tarefa ativa.
- `scripts/artemis-dry-run.sh --input control-plane/tasks.json --json`: `eligible=0`, `blocked=0`, `human_gate=0`, `done=42`.
- `scripts/validate-artemis.sh`: `ARTEMIS validation passed`.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: `passed=52`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: `events=18`, Validation Gate com `passed=52`, `failed=0`, `human_gate=2`.
- `git diff --check`: sem whitespace errors.
- Control Plane smoke: `/tmp/artemis-tkt041-control-plane.png`.

## Blockers

- Nenhum blocker tecnico local.
