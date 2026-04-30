# HANDOFF

## Result

TKT-015 is complete as a local contract and readiness adapter.

Claude Code is now modeled as an ARTEMIS Runner Adapter. `AGENTS.md` remains the canonical shared contract and `CLAUDE.md` remains only a runtime-specific entry point.

## Human Gate Rules

- `--dangerously-skip-permissions`, `--allow-dangerously-skip-permissions` and `--permission-mode bypassPermissions` are forbidden unless a future Exec Pack explicitly authorizes them.
- Remote control and remote sessions require Human Gate.
- Unreviewed MCP servers, plugins, broad Bash/Edit/Write access and remote writes require Human Gate.
- Hooks that block prompt/tool/stop flow become ARTEMIS Human Gate or policy gate events.

## Next

Proceed to TKT-016: define the canonical ARTEMIS event log schema shared by Codex app-server, Claude Code, GitHub Issues and future runner adapters.
