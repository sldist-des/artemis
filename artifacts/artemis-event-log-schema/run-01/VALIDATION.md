# VALIDATION

## Commands

```bash
scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json
```

Result:

- Schema version: `1`
- Events generated: `5`
- Event types:
  - `task.discovered`
  - `runner.readiness_checked`
  - `adapter.contract_recorded`
  - `validation.completed`

## Notes

- The script is read-only.
- The script reads existing local JSON artifacts and `control-plane/tasks.json`.
- It does not start runners.
- It does not write remote state.
- It does not persist events in a database.

## Gaps

- Existing adapters do not yet emit canonical events directly.
- Schema validation is structural-by-contract in this cut; no external JSON Schema validator dependency was added.
- Control Plane does not yet render the event log.
