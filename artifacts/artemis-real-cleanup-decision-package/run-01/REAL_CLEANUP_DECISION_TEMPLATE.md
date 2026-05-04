# REAL CLEANUP DECISION TEMPLATE

Edit `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json` only after reviewing each workspace evidence.

For each `decision_record`:

- Keep `decision` as `pending` while the decision is open.
- Use `approved` only when all cleanup commands are accepted exactly.
- Use `deferred` when cleanup should wait.
- Use `rejected` when cleanup should not happen.
- Fill `decided_by`, ISO-8601 `decided_at`, and `reason` for approved, deferred, or rejected.
- Keep `approved_commands` empty unless decision is approved.

Validation:

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-real-cleanup-decision-package/run-01/validation/approval-contract --json
```

```bash
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-real-cleanup-decision-package/run-01/validation/approved-cleanup-dry-run --json
```
