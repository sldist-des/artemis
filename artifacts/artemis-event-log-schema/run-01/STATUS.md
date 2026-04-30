# STATUS

- Ticket: TKT-016
- State: Handoff
- Owner: Codex
- Artifact: `artifacts/artemis-event-log-schema/run-01/`

## Done

- Defined canonical ARTEMIS event schemas.
- Added a read-only event log generator using existing Exec Pack and adapter artifacts.
- Covered Exec Pack task discovery, GitHub Issues readiness, Codex app-server contract, Claude Code contract and Validation Gate events.
- Kept adapter-specific details in `payload` so the Control Plane can consume a stable envelope without owning canonical state.

## Evidence

- `docs/schemas/artemis-event.schema.json`
- `docs/schemas/artemis-event-log.schema.json`
- `scripts/artemis-event-log.sh`
- `EVENT_LOG_SCHEMA.md`
- `event-log.example.json`
