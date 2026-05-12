# ARTEMIS Portal Agent Registry

O Agent Registry e o catalogo de agentes que o ARTEMIS Portal pode oferecer
para um projeto. Ele nao e uma lista livre de modelos. E um contrato de perfis,
capabilities, limites, gates e validacoes.

## Regra central

O portal escolhe um perfil registrado. O perfil pede lease curto ao Credential
Vault, respeita budget, usa worktree escopada e passa por validacao antes de
handoff.

```text
Project task
  -> Agent Registry profile
  -> Budget policy
  -> Credential Vault lease
  -> Workspace policy
  -> Runner adapter
  -> Validation Gate
  -> Completion review
```

## Perfil de agente

Cada perfil deve declarar:

- `agent_id`;
- nome de exibicao;
- provider;
- adapter;
- runtime;
- policy de modelo;
- familias de papel;
- tipos de tarefa recomendados;
- capabilities padrao;
- capabilities proibidas;
- limites de concorrencia e duracao;
- policy de budget;
- policy de validacao;
- policy de Human Gate;
- policy de workspace.

O perfil nunca deve declarar token, refresh token, private key, senha, cookie ou
qualquer segredo bruto.

## Perfis iniciais

### Codex Frontier Engineer

Uso recomendado:

- implementacao longa;
- refactor complexo;
- raciocinio multi-arquivo;
- plano de validacao de alto risco.

O modelo concreto vem de policy da organizacao e descoberta do provider. O
contrato nao deve acoplar seguranca, budget ou gates a um nome fixo de modelo.

### Claude Code Mapper

Uso recomendado:

- mapear repositorio;
- entender linguagem e framework;
- executar slices medios;
- produzir docs e handoff.

Este perfil e melhor como trabalho curto ou medio. Tarefas longas devem ser
quebradas ou encaminhadas para outro perfil conforme policy humana.

### ARTEMIS Verifier

Uso recomendado:

- validar claims;
- revisar cobertura de testes;
- checar evidencias;
- aceitar ou bloquear handoff tecnico.

O verificador nao deve validar sua propria execucao sem uma camada separada de
review.

## Capabilities

Capabilities seguras por padrao:

- `read_repo`;
- `run_local_tests`;
- `read_artifacts`;
- `produce_handoff`;
- `request_human_gate`.

Capabilities que exigem validacao:

- `write_worktree`;
- `open_pr_draft`;
- `push_branch`;
- `remote_write`.

Capabilities proibidas por padrao:

- ler secrets em plaintext;
- burlar Human Gate;
- fazer push sem gate;
- alterar branch protection;
- alterar CODEOWNERS sem gate;
- deploy de producao.

## Estados

- `draft`;
- `ready`;
- `waiting_for_provider_connection`;
- `waiting_for_vault_lease`;
- `waiting_for_budget`;
- `waiting_for_human_gate`;
- `available`;
- `assigned`;
- `running`;
- `validating`;
- `blocked`;
- `disabled`.

## Assignment rules

- Um escritor por worktree.
- Provider precisa estar conectado antes do perfil ficar disponivel.
- Vault lease e obrigatorio antes de runtime provider-backed.
- Budget policy e obrigatoria antes de gasto de token.
- Remote write fica desligado ate Human Gate explicito.
- Trabalho longo ou de alto risco deve priorizar perfil frontier de Codex, salvo
  policy humana em contrario.
- Mapeamento de repositorio e slices medios podem usar perfil Claude Code quando
  a conexao estiver disponivel.

## Fora de escopo neste corte

- iniciar agente real;
- autenticar provider;
- emitir lease real;
- gastar tokens;
- fazer push, PR, deploy ou mutacao remota;
- criar banco real de registry;
- criar scheduler real.

Proximo corte recomendado: `TKT-075 - ARTEMIS Portal Run Assignment Contract`.
