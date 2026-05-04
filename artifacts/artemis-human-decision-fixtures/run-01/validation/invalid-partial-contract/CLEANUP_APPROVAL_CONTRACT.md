# ARTEMIS HUMAN CLEANUP APPROVAL CONTRACT

- Generated at: 2026-05-04T17:10:04Z
- Overall: `failed`
- Decision source: `artifacts/artemis-human-decision-fixtures/run-01/fixtures/invalid-partial-approval.json`

## Contract

- Valid decisions: `pending`, `approved`, `deferred`, `rejected`
- Metadata required for: `approved`, `deferred`, `rejected`
- Required metadata fields: `decided_by`, `decided_at`, `reason`
- `approved` requires `approved_commands` to exactly match `commands_after_approval`.
- Partial approval does not execute; use `deferred` with a reason.
- `pending`, `deferred`, and `rejected` must not include approved commands.

## Summary

- Reviewed: 1
- Pending: 0
- Approved ready: 0
- Deferred: 0
- Rejected: 0
- Invalid: 1
- Execution allowed: 0

## Results

### TKT-FIX-PARTIAL - invalid

- Decision: `approved`
- Execution allowed: False

Blockers:
- approved_commands must exactly match commands_after_approval

## Invariants

- Approval requires identity, timestamp, reason, and exact commands.
- Deferred and rejected are explicit human decisions but never execute cleanup.
- Partial command approval is not executable approval.
- Pending remains an open Human Gate.
- Remote operations are out of scope.
