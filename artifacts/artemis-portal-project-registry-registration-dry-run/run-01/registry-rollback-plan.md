# Registry Rollback Plan

This rollback is a future plan only because no write happened in this cut.

If a later approved write installs the proposed records and must be reverted:

1. Remove the `registry.project` record for the candidate.
2. Remove the generated `selector.entry` for the candidate.
3. Append a `registry.audit` rollback event referencing the failed write.
4. Re-run the Project Registry read model generation.
5. Re-run `scripts/validate-artemis.sh`.
6. Keep project switching and runtime blocked until post-rollback review passes.

No rollback command is executed by this dry-run.
