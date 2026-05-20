# ARTEMIS Portal External Project Registration

O External Project Registration define como um projeto fora do repositorio
ARTEMIS pode entrar no catalogo do portal.

Ele existe porque "conectar pelo terminal" e "aparecer como projeto selecionavel
no painel" nao sao a mesma coisa. O terminal prova que o projeto existe naquela
maquina. O registro decide se esse projeto pode virar alvo do ARTEMIS.

## Fluxo

```text
Terminal no projeto
  -> npx artemis connect --project .
  -> Local Project Connect artifact
  -> External Project Registration
  -> Human review
  -> Project Selector
  -> Workspace Session
  -> Runtime Gateway
```

## Entrada pretendida

Quando o pacote publico existir:

```bash
npx artemis connect --project . --register
```

Neste repositorio, o equivalente validado e:

```bash
scripts/artemis-portal-external-project-registration.sh --json
```

Esse comando nao escaneia o servidor e nao registra projetos arbitrarios. Ele
consome um artifact de Local Project Connect e cria um contrato de registro
read-only para revisao.

## Regras de registro

- Projeto externo so pode ser candidato se veio de um connect executado no
  terminal da maquina onde o projeto existe.
- Browser nao pode fornecer caminho de filesystem como autoridade.
- Registro nao equivale a selecao ativa.
- Registro nao equivale a permissao de runtime.
- Projeto precisa ter Git root ou policy explicita de projeto sem Git.
- Projeto precisa ter `AGENTS.md` ou contrato equivalente.
- Projeto precisa declarar comandos de validacao antes de runtime.
- Fornecedores detectados no PATH nao significam auth conectada.
- Antigravity CLI fica experimental ate capability discovery e revisao de
  adapter.

## Project registry record

Campos obrigatorios:

- `project_id`;
- `display_name`;
- `source_connect_artifact`;
- `project_path`;
- `repo_root`;
- `git_branch`;
- `git_remote`;
- `agents_contract_present`;
- `provider_discovery`;
- `validation_commands`;
- `trust_review_state`;
- `registration_state`;
- `selected`;
- `runtime_execution_allowed`;
- `remote_writes_allowed`;
- `human_review_required`.

Campos proibidos:

- `plaintext_secret`;
- `raw_access_token`;
- `raw_refresh_token`;
- `private_key_material`;
- `session_cookie`;
- `ssh_private_key`;
- `provider_billing_secret`;
- `raw_provider_auth_state`;
- `raw_stdout`;
- `raw_stderr`;
- `full_prompt_transcript`;
- `git_remote_token`.

## Estados

- `candidate_from_terminal_connect`;
- `waiting_for_human_review`;
- `registered_read_only`;
- `selected_read_only`;
- `waiting_for_workspace_policy`;
- `waiting_for_provider_auth`;
- `waiting_for_budget`;
- `waiting_for_human_runtime_gate`;
- `ready_for_runtime_gateway`;
- `blocked`;
- `rejected`.

## Fora de escopo neste corte

- publicar pacote npm;
- gravar registry persistente editavel;
- cadastrar projeto externo real automaticamente;
- trocar projeto ativo no painel;
- criar workspace ou worktree;
- autenticar provider;
- iniciar Codex app-server, Claude Code ou Antigravity CLI;
- executar comandos;
- gastar tokens;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: renderizar a fila de candidatos/registro externo no
Control Plane antes de permitir troca de projeto.
