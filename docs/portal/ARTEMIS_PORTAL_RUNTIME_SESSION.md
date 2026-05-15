# ARTEMIS Portal Runtime Session

O Runtime Session e o contrato que transforma workspace, budget, lease policy e
launcher preflight em uma sessao supervisionada pelo portal.

Ele nao inicia Codex, Claude Code, sockets, streaming, comandos ou agentes. Ele
define a fronteira que o portal deve respeitar antes de qualquer runtime real.

## Regra central

Runtime Session aprovado nao e permissao de comando. Ele apenas prepara a
supervisao que um command plan e execution gate futuros poderao consumir.

```text
Workspace Session
  -> Runtime Session
  -> Supervision policy
  -> Heartbeat
  -> Transcript policy
  -> Stop rules
  -> Command plan
  -> Execution gate
```

## Session record

Campos obrigatorios:

- `runtime_session_id`
- `workspace_session_id`
- `assignment_id`
- `project_id`
- `ticket`
- `agent_profile_id`
- `provider_id`
- `adapter`
- `runtime_surface`
- `credential_lease_policy_id`
- `workspace_policy_id`
- `budget_policy_id`
- `supervision_policy_id`
- `command_boundary`
- `heartbeat_policy`
- `transcript_policy`
- `stop_rules`
- `validation_policy_id`
- `opened_at`
- `expires_at`
- `session_state`
- `evidence`

Campos proibidos:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `provider_billing_secret`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `full_prompt_transcript`
- `git_remote_token`
- `ssh_private_key`

## Lifecycle gates

- `workspace_session_ready`
- `budget_ledger_bound`
- `credential_lease_policy_bound`
- `launcher_preflight_present`
- `command_plan_required`
- `human_execution_gate_required`
- `validation_policy_bound`
- `cost_ledger_update_required`
- `completion_handoff_required`

## Supervision

- heartbeat obrigatorio;
- event stream obrigatorio;
- botao/parada humana obrigatoria;
- pause de agente suportado;
- transcript resumido obrigatorio;
- raw output e prompt completo proibidos em artifact git.

## Stop rules

- parar antes de qualquer segredo em claro;
- parar antes de comando fora do command plan;
- parar antes de remote write sem Human Gate separado;
- parar ao atingir limite de budget, token, agentes ou duracao;
- parar se path proibido for tocado;
- parar em conflito de dirty worktree;
- parar em falha de validacao sem retry policy aprovada;
- parar imediatamente por solicitacao humana.

## Fora de escopo neste corte

- autenticar provider;
- emitir vault lease real;
- abrir socket ou stream;
- iniciar Codex app-server ou Claude Code;
- executar comando;
- gastar tokens;
- armazenar stdout/stderr bruto;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: `TKT-079 - ARTEMIS Portal Agent Conversation Contract`.
