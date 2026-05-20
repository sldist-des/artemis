# ARTEMIS Control Plane Runtime Gateway View

- Overall: `control_plane_runtime_gateway_view_ready`
- Surface: `read_only_status_view`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-086 - Runtime Gateway Project Selector Contract`

## Rendered meaning

The Control Plane now shows Runtime Gateway operator status in the simple view. Codex app-server and Claude Code appear as planned but not connected. Antigravity CLI appears as blocked until capability discovery.

## Checks

- `control_plane_tokens_present`: passed - Control Plane contains the Runtime Gateway view, source URL, loader and renderer tokens.
- `runtime_gateway_service_ready`: passed - Runtime Gateway Service artifact is ready for read-only consumption.
- `operator_cards_supported`: passed - Service exposes Codex app-server, Claude Code and Antigravity CLI for the panel.
- `panel_still_read_only`: passed - The rendered state must keep direct runtime launch disabled.
- `no_runtime_side_effects`: passed - No agents, commands or tokens are produced by the view contract.
