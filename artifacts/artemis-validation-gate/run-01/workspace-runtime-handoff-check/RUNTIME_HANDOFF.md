# ARTEMIS WORKSPACE RUNTIME HANDOFF

- Generated at: 2026-05-11T14:32:09Z
- Mode: `read_only`
- Total: 3
- Cleaned: 0
- Kept: 0
- Pending: 3
- Approved ready: 0
- Deferred: 0
- Rejected: 0
- Needs decision: 0

## Workspaces

### TKT-021 - pending

- Title: Materializar workspace ARTEMIS controlado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Decision: `pending`
- Contract status: `pending`
- Execution allowed: False
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-021` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-021.lock`
- Branch: `artemis/tkt-021-materializar-workspace-artemis-contr` (exists: True)
- Artifact root: `artifacts/artemis-workspace-materialization/run-01`

Blockers:
- decision is pending, not approved for cleanup execution

### TKT-022 - pending

- Title: Executar runner no workspace materializado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Decision: `pending`
- Contract status: `pending`
- Execution allowed: False
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-022` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-022.lock`
- Branch: `artemis/tkt-022-executar-runner-no-workspace-materia` (exists: True)
- Artifact root: `artifacts/artemis-runner-workspace-execution/run-01`

Blockers:
- decision is pending, not approved for cleanup execution

### TKT-023 - pending

- Title: Loop de validacao e fix em workspace isolado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Decision: `pending`
- Contract status: `pending`
- Execution allowed: False
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-023` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-023.lock`
- Branch: `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace` (exists: True)
- Artifact root: `artifacts/artemis-validation-fix-loop/run-01`

Blockers:
- decision is pending, not approved for cleanup execution

## Invariants

- This handoff does not remove worktrees, branches, locks, or artifacts.
- Artifacts are the durable memory of local runtime decisions.
- A workspace with pending cleanup remains visible in lifecycle inventory.
- Deferred and rejected decisions remain visible and never imply cleanup execution.
- Approved-ready is not cleaned until the executor records command execution.
- A cleaned workspace must still appear in handoff evidence.
