# ARTEMIS Portal Auth Plan

O ARTEMIS Portal deve ser o cockpit proprio para operar projetos, agentes,
validacoes, memoria, custos e Human Gates. Ele nao substitui `AGENTS.md`,
Exec Packs, Git, artifacts ou Validation Gate; ele orquestra essas fontes.

## Tres camadas de autenticacao

1. **Portal auth**: quem e o humano, qual organizacao/time ele representa,
   quais roles possui e qual sessao esta ativa.
2. **Provider auth**: conexoes com OpenAI/Codex, Anthropic/Claude, GitHub e
   demais provedores.
3. **Project/runtime auth**: acesso ao repositorio, worktree, servidor, banco,
   secrets e deploy do projeto.

Essas camadas nao devem ser misturadas. O login no portal nao autoriza por si
so um agente a rodar, gastar tokens, tocar GitHub ou alterar producao.

## Portal identity

O ARTEMIS pode usar Auth0, Clerk, Supabase Auth, Keycloak ou OIDC proprio. A
decisao de produto fica aberta, mas o contrato minimo exige:

- organizacoes/times;
- roles;
- MFA;
- expiracao de sessao;
- audit log por identidade humana;
- caminho enterprise com SAML/SCIM quando necessario.

## Roles

| Role | Pode fazer |
|---|---|
| Owner | Gerenciar billing, provedores, projetos e gates de alto risco. |
| Maintainer | Conectar repos, criar tarefas e iniciar agentes aprovados. |
| Reviewer | Revisar diffs, evidencias e gates tecnicos. |
| Operator | Criar tarefas e iniciar execucoes supervisionadas de baixo risco. |
| Viewer | Ver projetos, eventos e handoffs. |

## Provider auth

### OpenAI / Codex

Codex entra por Runner Adapter do ARTEMIS. Para o portal, o caminho preferido e
usar Codex app-server quando o objetivo for experiencia rica com threads,
approvals e eventos. Auth pode variar entre browser/ChatGPT, device-code, API
key ou token externo conforme o ambiente suportado. O portal nao deve capturar
sessao local solta do usuario; deve registrar uma conexao explicita e auditavel.

Fonte: https://developers.openai.com/codex/app-server

### Anthropic / Claude Code

Claude entra por Runner Adapter do ARTEMIS usando Claude Code ou Agent SDK. O
caminho correto para portal e BYOK/API key, credencial empresarial ou provedor
suportado como Bedrock/Vertex quando aplicavel. O portal nao deve simular login
pessoal de `claude.ai`.

Fonte: https://code.claude.com/docs/en/agent-sdk/overview

### GitHub

GitHub deve preferir GitHub App ou OAuth. PAT fino pode existir como fallback,
mas deve ser escopado, expiravel e auditado.

## Credential Vault

Antes de qualquer auth real, o ARTEMIS precisa de um Credential Vault:

- tokens criptografados em repouso;
- escopo por usuario, time, projeto e provedor;
- injecao temporaria apenas no Runner Adapter supervisionado;
- rotacao e revogacao;
- expiracao;
- auditoria de leitura, uso, refresh e revoke;
- bloqueio quando budget, escopo ou policy estiver ausente;
- proibicao de secrets em prompts, artifacts, Exec Packs e logs.

Agentes nunca recebem secrets longos diretamente. Eles recebem capacidade
temporaria via adapter, com escopo minimo.

## Agent Management

O portal deve gerenciar:

- Agent Profile;
- Runner Adapter;
- Capability Policy;
- Project Binding;
- Budget Policy;
- Validation Policy;
- Human Gate Policy.

Estados de agente:

```text
draft -> ready -> waiting_for_auth -> waiting_for_budget
  -> waiting_for_human_gate -> running -> validating
  -> blocked | handoff -> done
```

## Gates obrigatorios

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

## Custo e token ledger

Todo launch real deve registrar limites antes de rodar:

- organizacao;
- projeto;
- usuario;
- provedor;
- modelo;
- agente;
- tarefa;
- tentativa/run;
- max tokens;
- max custo;
- max wall time;
- max agentes paralelos;
- stop rule.

## Fora de escopo neste corte

- implementar login real;
- armazenar tokens;
- criar MCP/REST server;
- iniciar Codex app-server;
- iniciar Claude Code/SDK;
- criar GitHub App;
- executar agente pago.

Proximo corte recomendado: `TKT-073 - ARTEMIS Portal Credential Vault Contract`.
