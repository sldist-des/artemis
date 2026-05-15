# ARTEMIS Portal Task Control Surface

O Task Control Surface e o contrato que transforma intents de conversa em
controles visiveis de tarefa no portal sem transformar clique em execucao
automatica.

Ele nao muda estado canonico de tarefa, nao inicia runtime, nao executa comando,
nao envia mensagem para provider e nao grava secrets. Ele registra controle,
autoridade, gate necessario, validacao exigida, evidencia e evento para que a
interface seja clara para humanos e segura para agentes.

## Regra central

Controle de tarefa e uma superficie de intencao auditavel. A autoridade real
continua nos Exec Packs, Validation Gate, Human Gate, Command Plan, Execution
Gate, Runtime Session e Done Ledger.

```text
Conversation intent
  -> Task control visibility
  -> Authority and gate check
  -> Event and evidence record
  -> Validation or Human Gate when needed
  -> Runtime only through separate execution gates
```

## Control record

Campos obrigatorios:

- `control_id`
- `project_id`
- `ticket`
- `conversation_id`
- `runtime_session_id`
- `assignment_id`
- `control_kind`
- `label`
- `current_task_state`
- `requested_transition`
- `actor_type`
- `actor_id`
- `authority_level`
- `gate_requirement`
- `validation_requirement`
- `budget_impact`
- `command_plan_ref`
- `event_refs`
- `evidence`

Campos proibidos:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `raw_prompt`
- `full_prompt_transcript`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `git_remote_token`
- `ssh_private_key`
- `unreviewed_command`
- `auto_execute_flag`

## Controles permitidos como intent

- `view_task`
- `assign_task_intent`
- `request_agent_status`
- `request_validation`
- `open_human_gate`
- `pause_runtime_session`
- `stop_runtime_session`
- `request_handoff_review`

## Controles bloqueados sem gate separado

- `start_runtime`
- `execute_command`
- `push_remote`
- `deploy_production`
- `read_secret`
- `increase_budget`
- `change_branch_protection`
- `mark_done_without_validation`

## Regras de enforcement

- Task controls nao sao autoridade direta de execucao.
- Controles de runtime, comando, remote write, secrets e budget roteiam para
  Human Gate ou gates de runtime.
- Um controle pode registrar evento e evidencia, mas nao altera estado canonico
  sozinho.
- Controle desabilitado precisa mostrar gate, validacao ou dependencia de
  budget faltante.
- Transicao para done exige evidencia de validacao e review de conclusao antes
  de ledger.
- Stop tem prioridade sobre nova atribuicao ou novo runtime.
- Prompt bruto, transcript completo, secrets e raw runtime output sao proibidos
  em artifacts do Task Control Surface.

## Fora de escopo neste corte

- alterar `control-plane/tasks.json` por clique;
- iniciar runtime;
- executar comando;
- enviar mensagem para provider;
- receber resposta real de agente;
- gastar tokens;
- criar branch, worktree, PR, push ou deploy;
- guardar prompt bruto, transcript completo, secrets ou output bruto.

Proximo corte recomendado: `TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract`.
