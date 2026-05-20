# ARTEMIS Control Plane Project Registry Home State

- Overall: `control_plane_project_registry_home_state_ready`
- Surface: `human_home_state`
- Selected project: `ARTEMIS Method Kit`
- Selected root: `/srv/veri`
- Candidates in review: `1`
- Technical surface primary: `false`
- Project switching allowed: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-096 - Project Registry Human Review Gate`

## Rendered meaning

The Control Plane home can now say which project is selected, whether a candidate is waiting for review, and that runtime remains blocked.

## Checks

- `control_plane_tokens_present`: passed - Control Plane contains registry intake source, loader, renderer and home-state tokens.
- `registry_intake_ready`: passed - Registry Intake artifact is ready for home consumption.
- `selected_project_visible`: passed - Home state can show the selected read-only project.
- `candidate_review_visible`: passed - Home state can show candidate review without making it selectable.
- `technical_surface_not_primary`: passed - Technical audit detail remains hidden from the primary home surface.
- `project_switching_still_blocked`: passed - Home state does not allow project switching.
- `runtime_still_blocked`: passed - Home state does not allow runtime execution.
- `no_runtime_side_effects`: passed - No agents, commands or tokens are produced by the home state contract.
