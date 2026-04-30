# VALIDATION

## Checks planejados

- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `git diff --check`
- Screenshot HTTP do Control Plane em desktop e mobile.

## Resultado

- `scripts/validate-artemis.sh`: passed.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=19 failed=0 human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passed; event log regenerado com TKT-019 ativo.
- `git diff --check`: passed.
- Screenshot desktop: `/tmp/artemis-control-plane-desktop.png`.
- Screenshot mobile: `/tmp/artemis-control-plane-mobile.png`.

## Human Gates conhecidos

- GitHub auth ainda invalido para push.
- GitHub Issues adapter permanece read-only/local ate autenticacao e owners reais serem configurados.
