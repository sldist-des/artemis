# ARTEMIS APPROVED WORKSPACE CLEANUP

- Generated at: 2026-05-04T17:10:04Z
- Mode: `dry_run`
- Overall: `human_gate`
- Reviewed: 1
- Ready to execute: 0
- Human Gate: 1
- Failed: 0
- Executed commands: 0

## Results

### TKT-FIX-REJECTED - human_gate

- Contract status: `rejected`
- Execute requested: False
- Executed: False

Blockers:
- decision is rejected, not approved for cleanup execution

## Invariants

- Default mode is dry-run.
- pending and deferred decisions never execute.
- rejected decisions never execute.
- approval requires identity, timestamp, reason, and exact commands.
- approved_commands must exactly match the generated cleanup review commands.
- Only local git worktree remove, lock rm, and git branch -d commands are allowlisted.
- Remote GitHub operations are out of scope.
