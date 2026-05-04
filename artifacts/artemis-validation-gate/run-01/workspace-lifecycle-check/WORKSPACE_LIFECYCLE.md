# ARTEMIS WORKSPACE LIFECYCLE INVENTORY

- Generated at: 2026-05-04T16:48:23Z
- Mode: `read_only`
- Locks: 3
- ARTEMIS worktrees: 3
- Active: 0
- Review ready: 3
- Decision required: 0

## Workspaces

### TKT-021 - review_ready

- Title: Materializar workspace ARTEMIS controlado
- Writer: Architect
- Branch: `artemis/tkt-021-materializar-workspace-artemis-contr` (exists: True, merged into HEAD: True)
- Worktree: `../veri-artemis-worktrees/tkt-021` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-021.lock`
- Artifact root: `artifacts/artemis-workspace-materialization/run-01` (exists: True, STATUS.md: True)
- Dirty count: 0
- Cleanup decision: `human_review_before_cleanup`
- Reason: branch is merged, worktree is clean, lock and artifacts are present

### TKT-022 - review_ready

- Title: Executar runner no workspace materializado
- Writer: Architect
- Branch: `artemis/tkt-022-executar-runner-no-workspace-materia` (exists: True, merged into HEAD: True)
- Worktree: `../veri-artemis-worktrees/tkt-022` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-022.lock`
- Artifact root: `artifacts/artemis-runner-workspace-execution/run-01` (exists: True, STATUS.md: True)
- Dirty count: 0
- Cleanup decision: `human_review_before_cleanup`
- Reason: branch is merged, worktree is clean, lock and artifacts are present

### TKT-023 - review_ready

- Title: Loop de validacao e fix em workspace isolado
- Writer: Architect
- Branch: `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace` (exists: True, merged into HEAD: True)
- Worktree: `../veri-artemis-worktrees/tkt-023` (exists: True, registered: True)
- Lock: `.artemis/locks/tkt-023.lock`
- Artifact root: `artifacts/artemis-validation-fix-loop/run-01` (exists: True, STATUS.md: True)
- Dirty count: 0
- Cleanup decision: `human_review_before_cleanup`
- Reason: branch is merged, worktree is clean, lock and artifacts are present

## Review Criteria

- Never remove a worktree or lock automatically.
- Review-ready means branch is already merged into current HEAD, worktree is clean, lock exists, and artifact STATUS.md exists.
- Decision-required means missing metadata, missing branch/worktree, dirty worktree, or unreadable lock.
- Active means the workspace should stay available until its branch and handoff are reviewed.
