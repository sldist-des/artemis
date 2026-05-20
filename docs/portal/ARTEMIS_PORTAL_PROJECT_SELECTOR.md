# ARTEMIS Portal Project Selector

O Project Selector define como o portal escolhe qual projeto esta em contexto
antes de qualquer conversa com operador, assignment, workspace ou runtime.

Ele existe porque um painel multi-operador sem projeto selecionado vira um
terminal remoto ambiguo. O ARTEMIS precisa saber exatamente qual repositorio,
raiz, branch, policy, validacao e limites estao ativos antes de permitir Codex
app-server, Claude Code, Antigravity CLI ou outro agente.

## Regra central

Nenhum operador roda sem projeto selecionado e confirmado.

```text
Portal UI
  -> Project Selector
  -> Project record
  -> Trust policy
  -> Workspace policy
  -> Runtime Gateway
  -> Run Assignment
```

## Projeto atual

Neste corte, o selector registra somente o projeto local ARTEMIS:

- raiz: repositório atual;
- tipo: `method_kit_repository`;
- selecao: read-only;
- runtime real: bloqueado;
- projeto externo: nao registrado.

Isso evita a confusao atual: o painel mostra o ARTEMIS em `/srv/veri`, nao um
projeto operacional escolhido pelo usuario.

## Project record

Campos obrigatorios:

- `project_id`;
- `display_name`;
- `project_kind`;
- `root_path`;
- `repo_root`;
- `git_branch`;
- `git_remote`;
- `agents_contract`;
- `control_plane_path`;
- `artifact_root`;
- `task_source`;
- `validation_commands`;
- `workspace_policy_id`;
- `default_budget_policy_id`;
- `default_human_gate_policy_id`;
- `allowed_operator_ids`;
- `forbidden_paths`;
- `selection_state`;
- `trust_level`;
- `human_confirmation_required_for_runtime`;

Campos proibidos:

- `plaintext_secret`;
- `raw_access_token`;
- `raw_refresh_token`;
- `private_key_material`;
- `session_cookie`;
- `ssh_private_key`;
- `provider_billing_secret`;
- `git_remote_token`;

## Estados

- `unregistered`;
- `discovered`;
- `registered_read_only`;
- `selected_read_only`;
- `waiting_for_human_confirmation`;
- `ready_for_workspace_session`;
- `blocked`;
- `disabled`.

## Regras de selecao

- Projeto precisa ter `AGENTS.md` ou contrato equivalente.
- Projeto precisa ter raiz Git detectada ou policy explicita de projeto sem Git.
- Projeto precisa declarar comandos de validacao antes de runtime real.
- Projeto externo precisa de cadastro humano antes de aparecer como selecionavel.
- Caminhos fora do projeto nao podem ser usados como worktree por inferencia.
- Selector nao emite credential lease.
- Selector nao inicia operador.
- Selector nao permite escrita remota.
- Selector nao decide budget sozinho.

## Para leigos

O Project Selector responde: "em qual projeto estamos mexendo?"

Hoje a resposta e:

> Estamos no projeto ARTEMIS, que constrói o metodo e o portal.

Ainda nao e:

> Escolhi o sistema financeiro, o ERP, o site ou outro produto real.

Antes de usar operadores reais, o portal precisa deixar isso visivel.

## Ligacao com projeto local

Projeto local externo nao deve ser escolhido pelo navegador. O caminho correto e
o humano abrir um terminal no projeto e executar o connect do ARTEMIS:

```bash
npx artemis connect --project .
```

Enquanto o pacote npm nao existe, o contrato local validado e:

```bash
scripts/artemis-portal-local-project-connect.sh --project . --json
```

Esse connect alimenta o Project Selector com contexto de projeto e descoberta
read-only dos fornecedores instalados no PATH local.

## Fora de escopo neste corte

- cadastrar projetos externos reais;
- escanear o servidor inteiro;
- abrir seletor de filesystem;
- criar worktree;
- trocar branch;
- iniciar Codex app-server;
- iniciar Claude Code;
- iniciar Antigravity CLI;
- autenticar provider;
- executar comandos;
- gastar tokens;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: renderizar o Project Selector e o Local Project
Connect no Control Plane antes de qualquer acao de operador.
