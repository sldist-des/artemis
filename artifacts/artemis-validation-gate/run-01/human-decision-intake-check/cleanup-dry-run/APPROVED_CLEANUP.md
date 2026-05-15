# ARTEMIS APPROVED WORKSPACE CLEANUP

- Generated at: 2026-05-15T17:23:13Z
- Mode: `dry_run`
- Overall: `human_gate`
- Reviewed: 3
- Ready to execute: 0
- Human Gate: 3
- Failed: 0
- Executed commands: 0

## Results

### TKT-021 - human_gate

- Contract status: `pending`
- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved for cleanup execution

### TKT-022 - human_gate

- Contract status: `pending`
- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved for cleanup execution

### TKT-023 - human_gate

- Contract status: `pending`
- Execute requested: False
- Executed: False

Blockers:
- decision is pending, not approved for cleanup execution

## Invariants

- Default mode is dry-run.
- pending and deferred decisions never execute.
- rejected decisions never execute.
- approval requires identity, timestamp, reason, and exact commands.
- approved_commands must exactly match the generated cleanup review commands.
- Only local git worktree remove, lock rm, and git branch -d commands are allowlisted.
- Remote GitHub operations are out of scope.
