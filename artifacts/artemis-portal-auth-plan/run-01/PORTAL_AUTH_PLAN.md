# ARTEMIS Portal Auth Plan

- Overall: `architecture_ready`
- Runtime auth executed: `false`
- Secrets written: `false`
- Remote state mutated: `false`
- Next cut: `TKT-073 - ARTEMIS Portal Credential Vault Contract`

## Auth layers

1. Portal auth: human user, organization, team, role and session.
2. Provider auth: OpenAI/Codex, Anthropic/Claude, GitHub and infra credentials.
3. Project/runtime auth: repository, worktree, deployment, database and secrets scope.

## Provider connections

- `openai_codex` via `codex_app_server`: Codex app-server ChatGPT/browser auth where supported, device-code flow where supported, API key or service credential for API-backed paths, external bearer token only behind explicit enterprise policy.
- `anthropic_claude` via `claude_agent_sdk`: ANTHROPIC_API_KEY, Amazon Bedrock credential, Google Vertex AI credential, enterprise provider credential.
- `github` via `github_app_or_oauth`: GitHub App, OAuth app, fine-grained PAT only as fallback.

## Credential vault rules

- encrypt provider tokens at rest.
- bind credentials to user/team/project scopes.
- inject short-lived runtime tokens only into supervised adapters.
- never write secrets into Exec Packs, artifacts, logs or prompts.
- support rotation, revocation and expiry.
- record audit entries for read, use, refresh and revoke.
- block provider use when budget, scope or policy is missing.

## Mandatory gates

- `portal_login`
- `provider_connected`
- `project_bound`
- `credential_scope_checked`
- `budget_policy_checked`
- `agent_launch_approved`
- `workspace_scope_checked`
- `remote_write_approved`
- `validation_gate_passed`
- `completion_review_accepted`

## Validation

- `portal_identity_separated`: passed - Portal auth, provider auth and project/runtime auth are separate layers.
- `vault_required`: passed - Provider credentials require vault storage and scoped injection; agents never receive raw long-lived secrets.
- `human_gates_preserved`: passed - Provider connection, agent launch, remote write and completion acceptance remain Human Gate surfaces.
- `no_runtime_auth_executed`: passed - This cut does not authenticate Codex, Claude, GitHub or any provider.
