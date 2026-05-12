# ARTEMIS REAL CLEANUP DECISION PACKAGE

- Generated at: 2026-05-12T17:35:33Z
- Mode: `read_only`
- Source review: `artifacts/artemis-validation-gate/run-01/workspace-cleanup-review-check/cleanup-review.json`
- Decision file: `artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json`
- Reviewed workspaces: 3
- Pending decisions: 3
- Execute allowed now: 0

## Human Fill Instructions

- Choose exactly one decision per workspace: pending, approved, deferred, or rejected.
- For approved, deferred, and rejected, fill decided_by, decided_at, and reason.
- For approved, copy every commands_after_approval entry into approved_commands in the same order.
- Leave approved_commands empty for pending, deferred, and rejected.
- Run the validation commands before any cleanup executor is considered.

## Validation Commands

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/validation/approval-contract --json
```

```bash
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json --artifact-root artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/validation/approved-cleanup-dry-run --json
```

## Workspaces

### TKT-021 - Materializar workspace ARTEMIS controlado

- Recommendation: `eligible_for_human_cleanup_approval`
- Lifecycle state: `review_ready`
- Decision options: `pending`, `approved`, `deferred`, `rejected`

Required evidence:
- `artifacts/artemis-workspace-materialization/run-01/STATUS.md`
- `artifacts/artemis-workspace-materialization/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-materialization/run-01/HANDOFF.md`
- `.artemis/locks/tkt-021.lock`
- `../veri-artemis-worktrees/tkt-021`
- `artemis/tkt-021-materializar-workspace-artemis-contr`

Commands after explicit human approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-021`
- `rm .artemis/locks/tkt-021.lock`
- `git branch -d artemis/tkt-021-materializar-workspace-artemis-contr`

### TKT-022 - Executar runner no workspace materializado

- Recommendation: `eligible_for_human_cleanup_approval`
- Lifecycle state: `review_ready`
- Decision options: `pending`, `approved`, `deferred`, `rejected`

Required evidence:
- `artifacts/artemis-runner-workspace-execution/run-01/STATUS.md`
- `artifacts/artemis-runner-workspace-execution/run-01/VALIDATION.md`
- `artifacts/artemis-runner-workspace-execution/run-01/HANDOFF.md`
- `.artemis/locks/tkt-022.lock`
- `../veri-artemis-worktrees/tkt-022`
- `artemis/tkt-022-executar-runner-no-workspace-materia`

Commands after explicit human approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-022`
- `rm .artemis/locks/tkt-022.lock`
- `git branch -d artemis/tkt-022-executar-runner-no-workspace-materia`

### TKT-023 - Loop de validacao e fix em workspace isolado

- Recommendation: `eligible_for_human_cleanup_approval`
- Lifecycle state: `review_ready`
- Decision options: `pending`, `approved`, `deferred`, `rejected`

Required evidence:
- `artifacts/artemis-validation-fix-loop/run-01/STATUS.md`
- `artifacts/artemis-validation-fix-loop/run-01/VALIDATION.md`
- `artifacts/artemis-validation-fix-loop/run-01/HANDOFF.md`
- `.artemis/locks/tkt-023.lock`
- `../veri-artemis-worktrees/tkt-023`
- `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`

Commands after explicit human approval:
- `git worktree remove ../veri-artemis-worktrees/tkt-023`
- `rm .artemis/locks/tkt-023.lock`
- `git branch -d artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`
