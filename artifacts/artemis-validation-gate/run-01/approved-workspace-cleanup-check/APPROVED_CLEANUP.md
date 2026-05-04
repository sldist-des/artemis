# ARTEMIS APPROVED WORKSPACE CLEANUP

- Generated at: 2026-05-04T14:47:14Z
- Mode: `dry_run`
- Overall: `human_gate`
- Reviewed: 3
- Ready to execute: 0
- Human Gate: 3
- Failed: 0
- Executed commands: 0

## Results

### TKT-021 - human_gate

- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

### TKT-022 - human_gate

- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

### TKT-023 - human_gate

- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved
- decided_by is missing
- decided_at is missing
- decision reason is missing
- approved_commands do not exactly match expected cleanup commands

## Invariants

- Default mode is dry-run.
- pending and deferred decisions never execute.
- approved_commands must exactly match the generated cleanup review commands.
- Only local git worktree remove, lock rm, and git branch -d commands are allowlisted.
- Remote GitHub operations are out of scope.
