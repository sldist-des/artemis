# ARTEMIS AGENT RUNTIME DRY-RUN REQUEST

- Project: `ARTEMIS`
- Task: `TKT-067 - Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony`
- Profile: `codex_terminal`
- Runtime: `codex_cli`
- Command surface: `terminal`
- Execute: `false`
- Model policy: `inherited_or_human_approved`
- Budget approval: `human_required_before_runtime`
- Auth state: `not_required_for_dry_run`
- Workspace write scope: `none`

## Stop rule

Stop before any real runtime, paid token use, remote write, production touch, secret access or missing validation evidence.
