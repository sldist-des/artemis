# ARTEMIS Portal Workspace Session Contract

- Overall: `blocked`
- Runtime auth executed: `false`
- Vault lease issued: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Worktree created: `false`
- Branch changed: `false`
- Remote state mutated: `false`
- Next cut: `TKT-078 - ARTEMIS Portal Runtime Session Contract`

## Regra central

Nenhum assignment pode chegar ao launcher sem uma sessao de workspace que declare repositorio, worktree, branch policy, writer lock, allowed write roots, forbidden paths e dirty-worktree policy.

## Selected workspace policy

- Workspace policy: `workspace:single-writer-worktree`
- Max writers: `1`
- Requires writer lock: `true`
- Remote writes allowed: `false`
- Dirty worktree policy: `detect_and_report_before_launch`

## Session required fields

- `workspace_session_id`
- `assignment_id`
- `project_id`
- `ticket`
- `agent_profile_id`
- `workspace_policy_id`
- `budget_policy_id`
- `repository_path`
- `worktree_path`
- `branch_policy`
- `writer_lock`
- `allowed_write_roots`
- `forbidden_paths`
- `dirty_worktree_policy`
- `validation_policy_id`
- `opened_at`
- `expires_at`
- `session_state`
- `evidence`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `provider_billing_secret`
- `runtime_command_output`
- `git_remote_token`
- `ssh_private_key`

## Allowed write roots

- `repository_worktree`
- `artifact_root`
- `tmp_validation_root`

## Forbidden paths

- `.git/config`
- `.git/hooks`
- `.env`
- `.env.*`
- `secrets/`
- `private/`
- `production/`
- `node_modules/`
- `vendor/`

## Enforcement rules

- A Workspace Session must consume an accepted Run Assignment and ready Budget Ledger.
- A writer agent requires an exclusive writer lock before launcher preflight.
- Verifier agents must use read-only mode or a separate workspace session.
- Dirty worktree state must be detected and reported before runtime launch.
- Forbidden paths cannot be written by portal-managed agents.
- Remote writes, branch protection changes and deploys require separate Human Gate authority.
- Workspace approval is not runtime execution permission.
- The session record must not contain secrets, provider tokens, private keys or raw command output.

## Validation

- `run_assignment_ready`: passed - Workspace Session consumes an accepted Run Assignment.
- `budget_ledger_ready`: passed - Workspace Session consumes a ready Budget Ledger before runtime spend.
- `workspace_policy_bound`: failed - Assignment workspace policy resolves to a concrete workspace policy.
- `single_writer_lock_declared`: passed - Writer sessions are constrained to one writer per worktree.
- `write_scope_declared`: passed - Allowed write roots and forbidden paths are declared.
- `no_runtime_execution`: passed - This cut records workspace policy only and cannot start runtime.
- `no_remote_mutation`: passed - Remote writes remain blocked until an explicit Human Gate.
- `no_secret_values_recorded`: passed - No provider secrets, project secrets, SSH keys or raw command output are stored.
