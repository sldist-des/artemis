# ARTEMIS AGENT RUNTIME DRY-RUN PREFLIGHT

- `contract_ready`: `passed` - contract overall: agent_launch_contract_ready
- `profile_selected`: `passed` - codex_terminal
- `required_gates_present`: `passed` - auth_gate, budget_gate, command_gate, project_gate, remote_write_gate, rollback_gate, task_gate, validation_gate, workspace_gate
- `execute_false`: `passed` - execute=false
- `runtime_not_started`: `passed` - runtime_started=false
- `agents_not_started`: `passed` - agents_started=0
- `commands_not_executed`: `passed` - commands_executed=0
- `remote_writes_blocked`: `passed` - remote_writes_allowed=false
- `auth_gate`: `passed` - not_required_for_dry_run
- `budget_gate`: `human_gate` - max_paid_tokens=0 until explicit budget approval
- `workspace_gate`: `passed` - write_scope=none and worktree_policy=not_materialized
- `rollback_gate`: `passed` - dry-run and future runtime abort rules recorded
- `validation_gate`: `passed` - future runtime must declare tests/checks/screenshots before Done
