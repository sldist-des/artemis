# VALIDATION

## Validacoes

- `scripts/artemis-workspace-runtime-handoff.sh --artifact-root artifacts/artemis-workspace-runtime-handoff/run-01 --json`: passou.
- `sh -n scripts/artemis-workspace-runtime-handoff.sh`: passou.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: passou com `passed=32`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passou.
- `scripts/validate-artemis.sh`: passou com `ARTEMIS validation passed`.
- `git diff --check`: passou.
- Smoke visual do Control Plane: passou com screenshot em `/tmp/artemis-tkt029-control-plane.png`.

## Cenarios cobertos

- Runtime real: 3 workspaces permanecem `pending`.
- Validacao sintetica: `approved_ready`, `deferred` e `rejected` sao exercitados sem comandos reais.

## Gaps

- Nenhuma decisao humana real foi aprovada, deferida ou rejeitada.
- Cleanup real permanece fora de escopo.
