# STATUS

## Resultado

TKT-038 definiu o contrato read-only de reentrada apos decisao humana.

## Estado da reentrada

- Overall: `human_gate`.
- Reviewed: `3`.
- Approved ready: `0`.
- Pending: `3`.
- Deferred: `0`.
- Rejected: `0`.
- Invalid: `0`.
- Executed commands: `0`.
- Preflight allowed: `false`.
- Cleanup execution allowed: `false`.
- Next lane: `human_must_fill_decision_record`.

## Contrato por estado

### approved_ready

- Meaning: Decision record and dry-run agree that a workspace can enter a future supervised preflight.
- Allows preflight: `true`.
- Allows executor: `false`.
- Required next step: Create or run a later preflight artifact; do not execute cleanup from this contract.

### pending

- Meaning: Human decision fields are still incomplete.
- Allows preflight: `false`.
- Allows executor: `false`.
- Required next step: Human fills decision_record and reruns intake plus this reentry contract.

### deferred

- Meaning: Human chose to revisit later.
- Allows preflight: `false`.
- Allows executor: `false`.
- Required next step: Keep workspace state and record the deferral.

### rejected

- Meaning: Human declined cleanup for that workspace.
- Allows preflight: `false`.
- Allows executor: `false`.
- Required next step: Record refusal and keep workspace state.

### invalid

- Meaning: Decision metadata or command list is inconsistent.
- Allows preflight: `false`.
- Allows executor: `false`.
- Required next step: Fix the decision record before any next lane.

## Invariantes preservados

- Reentry is read-only and is not an executor.
- approved_ready permits only a future supervised preflight.
- approved_ready does not execute cleanup by itself.
- pending, deferred, rejected, and invalid do not enter an executor.
- No command with --execute is emitted by this contract.
- Remote writes remain Human Gate.
