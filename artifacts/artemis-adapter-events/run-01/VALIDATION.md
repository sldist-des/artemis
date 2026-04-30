# VALIDATION

## Commands

```bash
scripts/artemis-github-issues.sh --artifact-root artifacts/artemis-github-issues-adapter/run-01 --json
scripts/artemis-codex-app-server.sh --artifact-root artifacts/artemis-codex-app-server-adapter/run-01 --json
scripts/artemis-claude-code.sh --artifact-root artifacts/artemis-claude-code-adapter/run-01 --json
scripts/artemis-validation-gate.sh --json
scripts/validate-artemis.sh
```

## Result

- GitHub Issues adapter emitted `events.json` with `runner.readiness_checked`.
- Codex app-server adapter emitted `events.json` with `adapter.contract_recorded`.
- Claude Code adapter emitted `events.json` with `adapter.contract_recorded`.
- Validation Gate emits `events.json` with `validation.completed`.
- Validation Gate now checks canonical event files.

## Gaps

- No backend or database was introduced.
- Control Plane does not yet render the canonical event stream.
- Event schema validation remains dependency-free.
