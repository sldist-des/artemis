# ARTEMIS HUMAN DECISION FIXTURES

- Generated at: 2026-05-11T14:32:00Z
- Mode: `read_only`
- Fixtures: 5
- Valid: 3
- Invalid: 2
- Execute allowed: 0

## Fixtures

### approved-exact

- Description: Valid approval with exact commands.
- Path: `artifacts/artemis-validation-gate/run-01/human-decision-fixtures-check/fixtures/approved-exact.json`
- Expected contract state: `approved_ready`
- Expected executor status: `ready_to_execute`
- Expected overall: `passed`
- Execute allowed: False

### deferred

- Description: Valid deferral with metadata and no approved commands.
- Path: `artifacts/artemis-validation-gate/run-01/human-decision-fixtures-check/fixtures/deferred.json`
- Expected contract state: `deferred`
- Expected executor status: `human_gate`
- Expected overall: `passed`
- Execute allowed: False

### rejected

- Description: Valid rejection with metadata and no approved commands.
- Path: `artifacts/artemis-validation-gate/run-01/human-decision-fixtures-check/fixtures/rejected.json`
- Expected contract state: `rejected`
- Expected executor status: `human_gate`
- Expected overall: `passed`
- Execute allowed: False

### invalid-partial-approval

- Description: Invalid approval because only part of the command list is approved.
- Path: `artifacts/artemis-validation-gate/run-01/human-decision-fixtures-check/fixtures/invalid-partial-approval.json`
- Expected contract state: `invalid`
- Expected executor status: `human_gate`
- Expected overall: `failed`
- Execute allowed: False

### invalid-missing-metadata

- Description: Invalid approval because required human metadata is missing.
- Path: `artifacts/artemis-validation-gate/run-01/human-decision-fixtures-check/fixtures/invalid-missing-metadata.json`
- Expected contract state: `invalid`
- Expected executor status: `human_gate`
- Expected overall: `failed`
- Execute allowed: False

## Invariants

- Fixtures are synthetic and read-only.
- Fixtures must not be passed to cleanup with --execute.
- Approved fixtures prove exact command matching, not real cleanup authorization.
- Invalid fixtures must fail the contract before execution.
