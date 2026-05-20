# ARTEMIS Portal Local Project Connect

- Overall: `local_project_connect_ready`
- Project path: `/srv/veri`
- Repo root: `/srv/veri`
- Branch: `main`
- AGENTS.md present: `true`
- CLAUDE.md present: `true`
- Npx entrypoint planned: `npx artemis connect --project .`
- Local equivalent: `scripts/artemis-portal-local-project-connect.sh --project . --json`
- Terminal project access required: `true`
- Browser filesystem access allowed: `false`
- Provider auth connected: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-088 - Control Plane Local Project Connect View`

## Provider discovery

- `codex`: `terminal_binary_detected` - /usr/bin/codex
- `claude_code`: `terminal_binary_detected` - /root/.local/bin/claude
- `antigravity_cli`: `terminal_binary_detected` - /root/.local/bin/agy

## Checks

- `project_directory_exists`: passed - The terminal-provided project path must exist.
- `git_context_detected`: passed - A Git root is recorded for the local project.
- `agent_contract_detected`: passed - AGENTS.md is present before the project can be trusted by ARTEMIS operators.
- `provider_slots_declared`: passed - Codex, Claude Code and Antigravity CLI slots are declared for local discovery.
- `terminal_first_boundary`: passed - Project access is terminal-first and browser filesystem access is blocked.
- `runtime_still_blocked`: passed - Provider discovery does not authenticate providers or allow runtime.
- `no_runtime_side_effects`: passed - No provider auth, runtime, agent launch, task command, token spend or remote mutation happened.
