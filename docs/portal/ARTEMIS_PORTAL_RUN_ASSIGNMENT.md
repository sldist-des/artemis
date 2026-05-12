# ARTEMIS Portal Run Assignment

O Run Assignment e o contrato que transforma uma tarefa do projeto em uma
atribuicao supervisionada para um perfil registrado. Ele fica entre o Agent
Registry e o launcher real.

## Regra central

Nenhum agente roda apenas porque existe uma tarefa. A tarefa precisa ser
vinculada a perfil, capabilities, budget, workspace, vault lease policy,
validacao, Human Gate e stop rule.

```text
Task / Exec Pack
  -> Agent Registry profile
  -> Run Assignment
  -> Budget policy
  -> Workspace policy
  -> Credential lease policy
  -> Validation policy
  -> Launcher preflight
```

## Assignment record

Campos obrigatorios:

- `assignment_id`
- `project_id`
- `task_id`
- `ticket`
- `exec_pack`
- `requested_by`
- `requested_at`
- `risk`
- `task_shape`
- `agent_profile_id`
- `provider_id`
- `adapter`
- `allowed_capabilities`
- `forbidden_capabilities`
- `budget_policy_id`
- `validation_policy_id`
- `human_gate_policy_id`
- `workspace_policy_id`
- `credential_lease_policy_id`
- `evidence_policy_id`
- `stop_rule`
- `expires_at`

Campos proibidos:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `runtime_command_output`
- `provider_billing_secret`

## Estados

- `requested`
- `policy_checking`
- `waiting_for_provider_connection`
- `waiting_for_vault_lease`
- `waiting_for_budget`
- `waiting_for_workspace`
- `waiting_for_human_gate`
- `ready_for_launcher_preflight`
- `rejected`
- `expired`

## Gates

Antes de ficar pronto para launcher preflight:

- task contract presente;
- perfil registrado;
- capability permitida;
- capability proibida ausente;
- budget policy vinculada;
- workspace policy vinculada;
- validation policy vinculada;
- credential lease policy vinculada;
- Human Gate policy vinculada;
- stop rule vinculada.

## Regras de selecao

- Apenas perfis do Agent Registry podem ser escolhidos.
- Risco, duracao e capabilities da tarefa precisam caber no perfil.
- Um perfil escritor exige workspace ou worktree exclusivo.
- Verificador nao deve validar a propria implementacao sem separacao de review.
- Vault lease e apenas planejado aqui; emissao real pertence ao Credential
  Vault.
- Budget policy precede gasto de token.
- Human Gate precede provider auth, remote write, producao, deploy ou runtime
  longo.
- Launcher preflight consome assignment aceito; este contrato nao executa
  runtime.

## Fora de escopo neste corte

- autenticar provider;
- emitir vault lease real;
- iniciar Codex app-server ou Claude Code;
- executar comando;
- gastar tokens;
- criar fila/scheduler real;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: `TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract`.
