# VALIDATION

## Validacoes

- `scripts/artemis-human-decision-fixtures.sh --artifact-root artifacts/artemis-human-decision-fixtures/run-01 --json`: passou com 5 fixtures.
- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/approved-exact.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/approved-contract --json`: passou com `approved_ready=1`.
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/approved-exact.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/approved-cleanup --json`: passou em dry-run com `ready_to_execute=1` e `executed_commands=0`.
- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/deferred.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/deferred-contract --json`: passou com `deferred=1`.
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/deferred.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/deferred-cleanup --json`: passou em dry-run com `human_gate=1`.
- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/rejected.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/rejected-contract --json`: passou com `rejected=1`.
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/rejected.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/rejected-cleanup --json`: passou em dry-run com `human_gate=1`.
- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/invalid-partial-approval.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/invalid-partial-contract --json`: passou como teste negativo com `invalid=1`.
- `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-human-decision-fixtures/run-01/fixtures/invalid-missing-metadata.json --artifact-root artifacts/artemis-human-decision-fixtures/run-01/validation/invalid-missing-contract --json`: passou como teste negativo com `invalid=1`.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: passou com `passed=34`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passou.
- `scripts/validate-artemis.sh`: passou com `ARTEMIS validation passed`.
- `git diff --check`: passou.
- Smoke visual do Control Plane: passou com screenshot em `/tmp/artemis-tkt030-control-plane.png`.

## Gaps

- Nenhuma fixture foi executada com `--execute`.
- Nenhuma decisao humana real foi aplicada a workspaces locais.
