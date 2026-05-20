# ARTEMIS Control Plane External Project Registration View

- Overall: `control_plane_external_project_registration_view_ready`
- Surface: `read_only_status_view`
- Candidates rendered: `1`
- External projects registered: `0`
- Project switching allowed: `false`
- Provider auth connected: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-093 - Project Selector Registry Intake`

## Rendered meaning

The Control Plane now shows terminal-connected projects as registration candidates. A candidate is not selected, not registered for runtime and still requires human review.

## Checks

- `control_plane_tokens_present`: passed - Control Plane contains External Project Registration markup, source URL, loader and renderer tokens.
- `external_project_registration_ready`: passed - External Project Registration artifact is ready for read-only consumption.
- `candidate_visible_without_registration`: passed - The view supports terminal-connect candidates without auto-registering projects.
- `project_switching_still_blocked`: passed - Project switching remains blocked while candidates wait for review.
- `browser_and_scan_still_blocked`: passed - The view preserves no-browser-filesystem and no-server-scan boundaries.
- `runtime_still_blocked`: passed - Rendered registration state must not imply provider auth or runtime permission.
- `no_runtime_side_effects`: passed - No agents, commands or tokens are produced by the view contract.
