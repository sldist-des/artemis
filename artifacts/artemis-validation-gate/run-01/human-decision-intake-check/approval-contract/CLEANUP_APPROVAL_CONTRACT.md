# ARTEMIS HUMAN CLEANUP APPROVAL CONTRACT

- Generated at: 2026-05-11T13:31:40Z
- Overall: `human_gate`
- Decision source: `artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json`

## Contract

- Valid decisions: `pending`, `approved`, `deferred`, `rejected`
- Metadata required for: `approved`, `deferred`, `rejected`
- Required metadata fields: `decided_by`, `decided_at`, `reason`
- `approved` requires `approved_commands` to exactly match `commands_after_approval`.
- Partial approval does not execute; use `deferred` with a reason.
- `pending`, `deferred`, and `rejected` must not include approved commands.

## Summary

- Reviewed: 3
- Pending: 3
- Approved ready: 0
- Deferred: 0
- Rejected: 0
- Invalid: 0
- Execution allowed: 0

## Results

### TKT-021 - pending

- Decision: `pending`
- Execution allowed: False

Warnings:
- pending is an open human decision and cannot execute cleanup

### TKT-022 - pending

- Decision: `pending`
- Execution allowed: False

Warnings:
- pending is an open human decision and cannot execute cleanup

### TKT-023 - pending

- Decision: `pending`
- Execution allowed: False

Warnings:
- pending is an open human decision and cannot execute cleanup

## Invariants

- Approval requires identity, timestamp, reason, and exact commands.
- Deferred and rejected are explicit human decisions but never execute cleanup.
- Partial command approval is not executable approval.
- Pending remains an open Human Gate.
- Remote operations are out of scope.
