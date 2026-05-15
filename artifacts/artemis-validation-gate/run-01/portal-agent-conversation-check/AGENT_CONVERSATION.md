# ARTEMIS Portal Agent Conversation Contract

- Overall: `agent_conversation_ready`
- Messages sent to provider: `0`
- Agent messages received: `0`
- Runtime execution allowed: `false`
- Runtime session started: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Remote state mutated: `false`
- Next cut: `TKT-080 - ARTEMIS Portal Task Control Surface Contract`

## Regra central

Conversas do portal podem registrar intencao, status, perguntas, respostas resumidas e gates, mas nao podem iniciar runtime, executar comandos, enviar segredo, guardar prompt bruto ou liberar remote write.

## Message required fields

- `message_id`
- `conversation_id`
- `runtime_session_id`
- `project_id`
- `ticket`
- `sender_type`
- `sender_id`
- `recipient_type`
- `created_at`
- `message_kind`
- `visibility`
- `body_summary`
- `intent`
- `safety_classification`
- `redaction_state`
- `event_refs`
- `evidence`

## Forbidden fields

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `provider_billing_secret`
- `raw_prompt`
- `full_prompt_transcript`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `git_remote_token`
- `ssh_private_key`

## Allowed intents

- `ask_status`
- `assign_task`
- `clarify_requirement`
- `request_validation`
- `approve_gate`
- `reject_gate`
- `pause_agent`
- `stop_agent`
- `summarize_context`

## Gated intents

- `execute_command`
- `push_remote`
- `deploy_production`
- `read_secret`
- `change_branch_protection`
- `increase_budget`

## Enforcement rules

- Conversation messages must reference a Runtime Session when discussing a live or planned agent run.
- Conversation approval does not execute commands or start agents.
- Command, remote write, deploy, secret access and budget increase intents require separate gates.
- Raw prompts, full transcripts, secrets, private keys and raw runtime output are forbidden in git artifacts.
- Every task-impacting message must produce an event reference and evidence.
- Stop requests must route to Runtime Session stop policy before any further agent action.
- Agent replies shown to humans must be summarized or redacted before persistence.

## Validation

- `runtime_session_ready`: passed - Agent Conversation consumes a ready Runtime Session.
- `message_schema_declared`: passed - Conversation message fields and forbidden raw/secret fields are declared.
- `intent_policy_declared`: passed - Allowed intents and gated intents are explicit.
- `redaction_policy_declared`: passed - Raw prompts are blocked and summaries are required.
- `event_bridge_declared`: passed - Conversation events are canonical but raw transcripts are not stored.
- `no_provider_messages`: passed - This cut does not send or receive provider-backed messages.
- `no_runtime_execution`: passed - Conversation cannot start runtime or execute commands.
- `no_secret_values_recorded`: passed - No secrets, raw prompts, raw runtime output or full transcripts are stored.
