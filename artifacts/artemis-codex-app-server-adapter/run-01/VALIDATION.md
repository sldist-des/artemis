# VALIDATION

## Commands

```bash
scripts/artemis-codex-app-server.sh --artifact-root artifacts/artemis-codex-app-server-adapter/run-01 --json
```

Result:

- Overall: `passed`
- Generated schema files during temporary local probe: `227`
- Default approved first-cut transport: `stdio`

## Notes

- The script runs `codex app-server --help` and `codex app-server generate-json-schema` only.
- It does not start `codex app-server`.
- It does not open WebSocket transport.
- It does not mutate Codex auth, config, plugins, apps, files, or remote state.

## Gaps

- No app-server client loop was implemented in TKT-014.
- No live thread or turn was started.
- WebSocket transport remains a future Human Gate item.
