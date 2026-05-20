# ARTEMIS Portal External Project Registration

- Overall: `external_project_registration_ready`
- Candidate project: `veri`
- Candidate id: `veri_d55ae65706`
- Source connect artifact: `artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json`
- Project path: `/srv/veri`
- External projects registered: `0`
- Project switching allowed: `false`
- Browser filesystem access allowed: `false`
- Server scan allowed: `false`
- Provider auth connected: `false`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-090 - Control Plane External Project Registration View`

## Regras

- Only terminal connect artifacts can create project registration candidates.
- Browser-provided filesystem paths are not trusted registration authority.
- Registration candidates require human review before becoming selectable.
- Registration does not select the project and does not permit runtime execution.
- Detected provider binaries do not imply authenticated provider sessions.
- Runtime remains blocked until Project Selector, Credential Vault, Budget Ledger, Workspace Session, Runtime Gateway, Human Gate and Validation Gate pass.

## Checks

- `local_project_connect_ready`: passed - Registration consumes a Local Project Connect artifact before any project can become a candidate.
- `terminal_connect_is_source`: passed - The source of authority is terminal connect, not browser filesystem selection.
- `browser_and_scan_blocked`: passed - The registration contract blocks browser filesystem access and server-wide scans.
- `candidate_requires_human_review`: passed - Terminal-connected projects remain candidates until human review.
- `no_external_project_auto_registered`: passed - This cut does not automatically register or select external projects.
- `runtime_still_blocked`: passed - Registration candidate state does not grant runtime execution.
- `no_runtime_side_effects`: passed - No provider auth, runtime, agent launch, task command, token spend or remote mutation happened.
