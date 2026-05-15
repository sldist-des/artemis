# ARTEMIS Portal Validation Evidence Surface Contract

- Overall: `validation_evidence_surface_ready`
- Readiness state: `human_gate`
- Validation passed: `127`
- Validation failed: `0`
- Human gates: `2`
- Acceptance recorded: `false`
- Task state mutated: `false`
- Runtime execution allowed: `false`
- Runtime session started: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract`

## Regra central

Validation evidence mostra provas, falhas, Human Gates e lacunas em linguagem humana, mas nao aceita entrega, nao marca done e nao executa nada.

## Evidence required fields

- `evidence_surface_id`
- `project_id`
- `ticket`
- `control_id`
- `validation_gate_ref`
- `project_graph_ref`
- `evidence_kind`
- `claim`
- `source_artifact`
- `status`
- `severity`
- `human_readable_summary`
- `machine_check_ref`
- `blocker_refs`
- `event_refs`
- `generated_at`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `raw_prompt`
- `full_prompt_transcript`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `provider_secret`
- `git_remote_token`
- `ssh_private_key`
- `unredacted_user_data`

## Evidence kinds

- `validation_gate_summary`
- `test_result`
- `static_check`
- `json_schema_check`
- `artifact_presence`
- `graph_consistency`
- `human_gate_status`
- `residual_risk`
- `not_tested_gap`

## Status model

- `passed`
- `failed`
- `human_gate`
- `not_run`
- `not_applicable`
- `blocked`

## Enforcement rules

- Validation Evidence Surface explains evidence; it does not accept work.
- Failed checks and Human Gates must be visible before any acceptance flow.
- Raw prompts, full transcripts, secrets and raw runtime output are forbidden in evidence artifacts.
- Every evidence card must point to a source artifact or explicit not-tested gap.
- Done and acceptance remain blocked until a future Human Acceptance Surface records human decision.
- Evidence summaries must distinguish technical pass from human approval.

## Validation

- `task_control_surface_ready`: passed - Validation Evidence Surface consumes a ready Task Control Surface contract.
- `validation_gate_available`: passed - Validation Gate summary is available for evidence rendering.
- `project_graph_available`: passed - Project Graph summary is available for project-level evidence context.
- `evidence_schema_declared`: passed - Evidence fields and forbidden raw/secret fields are declared.
- `acceptance_boundary_declared`: passed - Evidence can show readiness but cannot accept work or mark done.
- `display_policy_declared`: passed - Failed checks and Human Gates are visible while raw runtime output remains blocked.
- `no_runtime_execution`: passed - Validation evidence cannot start runtime or execute commands in this cut.
- `no_acceptance_recorded`: passed - This cut records evidence only and does not accept work or mutate task state.
- `no_secret_values_recorded`: passed - No secrets, raw prompts, raw runtime output or full transcripts are stored.
