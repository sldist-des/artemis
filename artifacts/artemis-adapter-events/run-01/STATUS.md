# STATUS

- Ticket: TKT-017
- State: Handoff
- Owner: Codex
- Artifact: `artifacts/artemis-adapter-events/run-01/`

## Done

- Added `scripts/artemis_event_common.py` as the shared helper for canonical ARTEMIS event envelopes.
- Updated GitHub Issues, Codex app-server and Claude Code adapters to emit `events.json` alongside their adapter-specific JSON.
- Updated Validation Gate to emit `events.json`.
- Updated Validation Gate checks to require canonical events from adapters.
- Preserved adapter-specific diagnostic JSONs.

## Evidence

- `artifacts/artemis-github-issues-adapter/run-01/events.json`
- `artifacts/artemis-codex-app-server-adapter/run-01/events.json`
- `artifacts/artemis-claude-code-adapter/run-01/events.json`
- `artifacts/artemis-validation-gate/run-01/events.json`
- `scripts/artemis_event_common.py`
