# ARTEMIS WORKSPACE CLEANUP REVIEW

- Generated at: 2026-05-04T17:20:47Z
- Mode: `read_only`
- Reviewed: 3
- Eligible for human cleanup approval: 3
- Deferred: 0

## Reviews

### TKT-021 - eligible_for_human_cleanup_approval

- Title: Materializar workspace ARTEMIS controlado
- Lifecycle state: `review_ready`
- Cleanup allowed by script: False
- Human decision required: True

Required evidence:
- `artifacts/artemis-workspace-materialization/run-01/STATUS.md`
- `artifacts/artemis-workspace-materialization/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-materialization/run-01/HANDOFF.md`
- `.artemis/locks/tkt-021.lock`
- `../veri-artemis-worktrees/tkt-021`
- `artemis/tkt-021-materializar-workspace-artemis-contr`

Commands after explicit approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-021`
- `rm .artemis/locks/tkt-021.lock`
- `git branch -d artemis/tkt-021-materializar-workspace-artemis-contr`

### TKT-022 - eligible_for_human_cleanup_approval

- Title: Executar runner no workspace materializado
- Lifecycle state: `review_ready`
- Cleanup allowed by script: False
- Human decision required: True

Required evidence:
- `artifacts/artemis-runner-workspace-execution/run-01/STATUS.md`
- `artifacts/artemis-runner-workspace-execution/run-01/VALIDATION.md`
- `artifacts/artemis-runner-workspace-execution/run-01/HANDOFF.md`
- `.artemis/locks/tkt-022.lock`
- `../veri-artemis-worktrees/tkt-022`
- `artemis/tkt-022-executar-runner-no-workspace-materia`

Commands after explicit approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-022`
- `rm .artemis/locks/tkt-022.lock`
- `git branch -d artemis/tkt-022-executar-runner-no-workspace-materia`

### TKT-023 - eligible_for_human_cleanup_approval

- Title: Loop de validacao e fix em workspace isolado
- Lifecycle state: `review_ready`
- Cleanup allowed by script: False
- Human decision required: True

Required evidence:
- `artifacts/artemis-validation-fix-loop/run-01/STATUS.md`
- `artifacts/artemis-validation-fix-loop/run-01/VALIDATION.md`
- `artifacts/artemis-validation-fix-loop/run-01/HANDOFF.md`
- `.artemis/locks/tkt-023.lock`
- `../veri-artemis-worktrees/tkt-023`
- `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`

Commands after explicit approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-023`
- `rm .artemis/locks/tkt-023.lock`
- `git branch -d artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`

## Invariants

- This command never removes worktrees, branches, or locks.
- A pending decision is not approval.
- A human decision must name the exact commands approved for local cleanup.
- Dirty worktrees, unmerged branches, and missing evidence defer cleanup.
