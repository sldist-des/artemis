# REAL CLEANUP DECISION CHECKLIST

Before changing any decision from `pending`:

- Confirm the required STATUS, VALIDATION, and HANDOFF artifacts exist.
- Confirm the worktree path matches `git worktree list --porcelain`.
- Confirm the branch is already merged into current `HEAD`.
- Confirm the local worktree has no pending changes.
- Confirm the lock path matches the ticket.
- Copy cleanup commands exactly when approving.
- Run the validation commands and inspect their output.

Out of scope for this package:

- Running cleanup with `--execute`.
- Removing worktrees, branches, or locks.
- Pushing, merging, or changing remote GitHub settings.
