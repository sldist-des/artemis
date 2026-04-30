# STATUS

- Ticket: TKT-014
- State: Handoff
- Owner: Codex
- Artifact: `artifacts/artemis-codex-app-server-adapter/run-01/`

## Done

- Reviewed official Codex app-server documentation and the OpenAI Symphony article.
- Added a local read-only Codex app-server adapter probe.
- Mapped Codex `thread`, `turn`, `item`, approvals, notifications, and metadata to ARTEMIS tasks, attempts, events, Human Gates, Control Plane events, and workspace state.
- Preserved terminal-first control as an explicit invariant.
- Kept daemon startup, remote transport, auth changes, and remote writes out of scope.

## Evidence

- `CODEX_APP_SERVER_ADAPTER.md`
- `codex-app-server-adapter.json`
- `schema-index.txt`
- `check-logs/codex-app-server-help.txt`
- `check-logs/codex-app-server-schema.txt`
- `check-logs/codex-version.txt`
