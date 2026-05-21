# ARTEMIS Control Plane Operational Decision Home

- Overall: `control_plane_operational_decision_home_ready`
- Surface: `operational_decision_home`
- Primary state: `Decisao pendente`
- Primary action: `Preencher decisao humana`
- Decision template: `artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-template.json`
- Candidate registration allowed: `false`
- Project switching allowed: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-099 - Project Registry Registration Gate`

## Checks

- `decision_intake_ready`: passed - Operational home consumes Project Registry Decision Intake.
- `decision_pending_visible`: passed - Home can show pending decision state.
- `next_action_visible`: passed - Home exposes the immediate operational next action.
- `decision_template_linked`: passed - Home links to the fillable decision template artifact.
- `blockers_visible`: passed - Home exposes the blocking operational constraints.
- `control_plane_tokens_present`: passed - Control Plane contains operational decision home tokens.
- `project_switching_still_blocked`: passed - Operational home does not allow project switching.
- `runtime_still_blocked`: passed - Operational home does not allow runtime execution.
- `no_runtime_side_effects`: passed - No agents, commands or tokens are produced by the operational home.
