# ARTEMIS WORKSPACE RUNTIME HANDOFF

- Generated at: 2026-05-04T16:01:16Z
- Mode: `read_only`
- Total: 3
- Cleaned: 0
- Kept: 0
- Pending: 3
- Needs decision: 0

## Workspaces

### TKT-021 - pending

- Title: Materializar workspace ARTEMIS controlado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-021` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-021.lock`
- Branch: `artemis/tkt-021-materializar-workspace-artemis-contr` (exists: True)
- Artifact root: `artifacts/artemis-workspace-materialization/run-01`

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

### TKT-022 - pending

- Title: Executar runner no workspace materializado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-022` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-022.lock`
- Branch: `artemis/tkt-022-executar-runner-no-workspace-materia` (exists: True)
- Artifact root: `artifacts/artemis-runner-workspace-execution/run-01`

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

### TKT-023 - pending

- Title: Loop de validacao e fix em workspace isolado
- Reason: cleanup decision remains gated by human approval
- Lifecycle state: `review_ready`
- Cleanup status: `human_gate`
- Cleanup executed: False
- Worktree: `../veri-artemis-worktrees/tkt-023` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-023.lock`
- Branch: `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace` (exists: True)
- Artifact root: `artifacts/artemis-validation-fix-loop/run-01`

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

## Invariants

- This handoff does not remove worktrees, branches, locks, or artifacts.
- Artifacts are the durable memory of local runtime decisions.
- A workspace with pending cleanup remains visible in lifecycle inventory.
- A cleaned workspace must still appear in handoff evidence.
