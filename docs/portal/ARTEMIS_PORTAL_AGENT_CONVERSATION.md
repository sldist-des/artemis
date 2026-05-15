# ARTEMIS Portal Agent Conversation

O Agent Conversation e o contrato que define como humanos conversam com agentes
no portal sem transformar cada mensagem em execucao automatica.

Ele nao envia prompt para provider, nao inicia runtime, nao executa comando e
nao guarda transcript bruto. Ele registra intencao, resumo, redaction, eventos e
gates para que o portal seja claro para humanos e seguro para agentes.

## Regra central

Conversa aprovada nao e permissao de execucao. Ela pode pedir status, criar
intencao de tarefa, pedir validacao, abrir Human Gate ou solicitar stop, mas
command plan, execution gate e runtime continuam separados.

```text
Human message
  -> Redaction
  -> Intent classification
  -> Task/event routing
  -> Human Gate when needed
  -> Runtime Session observation
```

## Message record

Campos obrigatorios:

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

Campos proibidos:

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

## Regras de enforcement

- Mensagens sobre execucao precisam referenciar Runtime Session.
- Conversa nao inicia agente nem executa comando.
- Command, remote write, deploy, secret access e budget increase exigem gate
  separado.
- Raw prompt, transcript completo, secrets, chaves privadas e raw runtime output
  sao proibidos em artifacts git.
- Mensagem que altera tarefa precisa gerar evento e evidencia.
- Stop request deve ir para a policy de stop do Runtime Session antes de
  qualquer nova acao do agente.
- Respostas de agente mostradas a humanos precisam ser resumidas ou redigidas
  antes de persistencia.

## Fora de escopo neste corte

- enviar mensagem para provider;
- receber resposta real de agente;
- abrir socket ou stream;
- iniciar Codex app-server ou Claude Code;
- executar comando;
- gastar tokens;
- guardar prompt bruto ou transcript completo;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: `TKT-080 - ARTEMIS Portal Task Control Surface Contract`.
