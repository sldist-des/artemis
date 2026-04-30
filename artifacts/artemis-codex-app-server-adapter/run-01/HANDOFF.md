# HANDOFF

## Result

TKT-014 is complete as a local contract and readiness adapter.

The adapter defines Codex app-server as an ARTEMIS event source and rich-client protocol, not as the owner of the method. Terminal control, Exec Packs, artifacts, Git, and Validation Gate remain canonical.

## Human Gate Rules

- WebSocket transport requires explicit Human Gate before use.
- Non-loopback listeners are forbidden without explicit Human Gate.
- `thread/shellCommand` requires Human Gate because the official app-server docs describe it as running outside the thread sandbox.
- Auth changes, config writes, filesystem writes/removes, plugin installs, marketplace installs, and remote writes require Human Gate.

## Next

Proceed to TKT-015: prepare the Claude Code adapter with equivalent ARTEMIS event, hook, subagent, and headless-runner mapping.
