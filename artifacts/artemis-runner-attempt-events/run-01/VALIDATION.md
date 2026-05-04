# VALIDATION

## Checks planejados

- `scripts/artemis-runner.sh --ticket TKT-020 --command "scripts/artemis-dry-run.sh" --artifact-root artifacts/artemis-runner-attempt-events/run-01`
- `scripts/artemis-runner.sh --ticket TKT-021 --command "true" --execute --artifact-root artifacts/artemis-runner-attempt-events/run-01`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `git diff --check`

## Resultado

- `scripts/artemis-runner.sh --ticket TKT-020 --command "scripts/artemis-dry-run.sh" --artifact-root artifacts/artemis-runner-attempt-events/run-01`: passed; tentativa `20260504T134153Z-2-tkt-020` gerou `events.json`.
- `scripts/artemis-runner.sh --ticket TKT-021 --command "true" --execute --artifact-root artifacts/artemis-runner-attempt-events/run-01`: passed; tentativa `20260504T134653Z-2-tkt-021` gerou `runner.attempt_planned`, `runner.attempt_started` e `runner.attempt_completed`.
- `scripts/validate-artemis.sh`: passed.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=22 failed=0 human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passed; event log agregado inclui eventos de tentativa do runner.
- `git diff --check`: passed.

## Human Gates conhecidos

- GitHub auth ainda invalido para push.
- GitHub Issues adapter permanece read-only/local ate autenticacao e owners reais serem configurados.
