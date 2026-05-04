# HUMAN CLEANUP DECISION TEMPLATE

Use this template only after reviewing `cleanup-review.json` and the required evidence.
Validate the filled decision with `scripts/artemis-human-cleanup-approval-contract.sh` before any executor run.

Rules: `approved` requires `decided_by`, ISO-8601 `decided_at`, `reason`, and every command exactly as listed. Partial approval must stay `deferred` with a reason and does not execute.

## TKT-021

- Decision: pending | approved | deferred | rejected
- Decided by:
- Decided at:
- Reason:
- Approved commands:
  - `git worktree remove ../veri-artemis-worktrees/tkt-021`
  - `rm .artemis/locks/tkt-021.lock`
  - `git branch -d artemis/tkt-021-materializar-workspace-artemis-contr`

## TKT-022

- Decision: pending | approved | deferred | rejected
- Decided by:
- Decided at:
- Reason:
- Approved commands:
  - `git worktree remove ../veri-artemis-worktrees/tkt-022`
  - `rm .artemis/locks/tkt-022.lock`
  - `git branch -d artemis/tkt-022-executar-runner-no-workspace-materia`

## TKT-023

- Decision: pending | approved | deferred | rejected
- Decided by:
- Decided at:
- Reason:
- Approved commands:
  - `git worktree remove ../veri-artemis-worktrees/tkt-023`
  - `rm .artemis/locks/tkt-023.lock`
  - `git branch -d artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`
