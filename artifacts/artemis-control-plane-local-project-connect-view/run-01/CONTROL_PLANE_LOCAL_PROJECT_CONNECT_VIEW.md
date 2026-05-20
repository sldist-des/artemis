# ARTEMIS Control Plane Local Project Connect View

- Overall: `control_plane_local_project_connect_view_ready`
- Surface: `read_only_status_view`
- Project path: `/srv/veri`
- Providers rendered: `3`
- Terminal project access required: `true`
- Browser filesystem access allowed: `false`
- Provider auth connected: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-089 - External Project Registration Contract`

## Rendered meaning

The Control Plane now shows the project connected from the terminal before Runtime Gateway operators. Provider binaries can appear detected, but auth and runtime remain blocked.

## Checks

- `control_plane_tokens_present`: passed - Control Plane contains Local Project Connect markup, source URL, loader and renderer tokens.
- `local_project_connect_ready`: passed - Local Project Connect artifact is ready for read-only consumption.
- `terminal_project_access_visible`: passed - The view must preserve terminal-first project access and block browser filesystem access.
- `provider_discovery_visible`: passed - The view supports Codex, Claude Code and Antigravity CLI local discovery state.
- `runtime_still_blocked`: passed - Rendered provider discovery must not imply provider auth or runtime permission.
- `no_runtime_side_effects`: passed - No agents, commands or tokens are produced by the view contract.
