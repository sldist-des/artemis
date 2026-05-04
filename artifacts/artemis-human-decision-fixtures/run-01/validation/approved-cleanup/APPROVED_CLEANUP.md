# ARTEMIS APPROVED WORKSPACE CLEANUP

- Generated at: 2026-05-04T17:09:49Z
- Mode: `dry_run`
- Overall: `passed`
- Reviewed: 1
- Ready to execute: 1
- Human Gate: 0
- Failed: 0
- Executed commands: 0

## Results

### TKT-FIX-APPROVED - ready_to_execute

- Contract status: `approved_ready`
- Execute requested: False
- Executed: False

Approved commands:
- `git worktree remove ../artemis-fixtures/worktrees/approved-exact`
- `rm .artemis/locks/tkt-fix-approved.lock`
- `git branch -d artemis/fixture-approved-exact`

## Invariants

- Default mode is dry-run.
- pending and deferred decisions never execute.
- rejected decisions never execute.
- approval requires identity, timestamp, reason, and exact commands.
- approved_commands must exactly match the generated cleanup review commands.
- Only local git worktree remove, lock rm, and git branch -d commands are allowlisted.
- Remote GitHub operations are out of scope.
