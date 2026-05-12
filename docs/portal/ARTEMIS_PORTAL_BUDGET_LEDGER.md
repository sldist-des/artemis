# ARTEMIS Portal Budget and Cost Ledger

O Budget and Cost Ledger e o contrato que impede um assignment de chegar ao
runtime sem limite explicito de custo, tokens, duracao e quantidade de agentes.

Ele nao calcula billing real. Ele define policy, ledger append-only e pontos de
parada para que Codex, Claude Code e futuros agentes operem com limite antes de
qualquer gasto.

## Regra central

Budget aprovado nao e permissao de execucao. Ele apenas permite que o launcher
preflight continue avaliando o assignment.

```text
Run Assignment
  -> Budget policy
  -> Cost ledger schema
  -> Human Gate threshold
  -> Hard stop rules
  -> Launcher preflight
```

## Budget policy

Cada policy deve declarar:

- `budget_policy_id`
- perfis de agente aplicaveis
- maximo de agentes
- maximo de minutos
- maximo de prompt tokens
- maximo de completion tokens
- maximo de tokens totais
- maximo de cost units estimadas
- threshold de Human Gate
- hard stop em limite

## Ledger entry

Campos obrigatorios:

- `ledger_entry_id`
- `assignment_id`
- `ticket`
- `agent_profile_id`
- `budget_policy_id`
- `provider_id`
- `model_policy`
- `phase`
- `recorded_at`
- `prompt_tokens`
- `completion_tokens`
- `total_tokens`
- `estimated_cost_units`
- `actual_cost_units`
- `limit_state`
- `human_gate_required`
- `evidence`

Campos proibidos:

- `raw_provider_invoice`
- `billing_api_secret`
- `card_number`
- `provider_account_secret`
- `plaintext_token`
- `runtime_command_output`

## Estados

- `draft`
- `estimated`
- `waiting_for_human_budget_gate`
- `approved_for_preflight`
- `spending`
- `limit_warning`
- `hard_stopped`
- `closed`
- `reconciled`

## Regras de enforcement

- Um Run Assignment precisa vincular budget policy conhecida antes do launcher
  preflight.
- Budget aprovado nao libera execucao sozinho.
- Human Gate e obrigatorio quando a estimativa ultrapassa o threshold da
  policy.
- Runtime deve parar ao ultrapassar tokens, tempo ou quantidade de agentes.
- Ledger entries sao append-only e precisam apontar para assignment, ticket e
  evidencia.
- Reconciliacao real de billing e trabalho futuro e nao pode armazenar secrets
  ou credenciais de billing.
- Remote write continua bloqueado mesmo quando budget estiver aprovado.

## Fora de escopo neste corte

- consultar billing real de provider;
- autenticar provider;
- emitir vault lease real;
- iniciar Codex app-server ou Claude Code;
- executar comando;
- gastar tokens;
- criar scheduler real;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: `TKT-077 - ARTEMIS Portal Workspace Session Contract`.
