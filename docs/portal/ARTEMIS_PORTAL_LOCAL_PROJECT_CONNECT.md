# ARTEMIS Portal Local Project Connect

O Local Project Connect define como um projeto local entra no ARTEMIS antes de
aparecer como projeto operavel no portal.

A regra e simples: acesso a projeto local e concedido pelo terminal, dentro do
diretorio do projeto. O navegador nao escolhe caminho do servidor, nao escaneia
pastas e nao ganha permissao de filesystem sozinho.

## Entrada pretendida

Quando o pacote publico existir, o caminho ergonomico sera:

```bash
npx artemis connect --project .
```

Neste repositorio, o equivalente validado e:

```bash
scripts/artemis-portal-local-project-connect.sh --project . --json
```

Esse comando roda no terminal, detecta o projeto atual e registra apenas um
contrato read-only. Ele nao autentica provider, nao abre Codex app-server, nao
inicia Claude Code, nao inicia Antigravity CLI, nao executa tarefa e nao gasta
token.

## Por que terminal-first

O portal pode ser acessado por celular ou navegador, mas o projeto local mora em
uma maquina especifica. Por isso, o humano ou desenvolvedor precisa executar o
connect no terminal da maquina onde o projeto existe.

Depois disso, o portal pode mostrar:

- qual projeto esta conectado;
- qual raiz Git foi detectada;
- se existe `AGENTS.md`;
- quais fornecedores estao disponiveis no PATH local;
- quais fornecedores ainda exigem auth, vault, budget e gates;
- se o Runtime Gateway pode ou nao aceitar uma tarefa.

## Fornecedores detectados

O connect deve procurar slots conhecidos:

- `codex`: Codex CLI e futuro Codex app-server;
- `claude_code`: Claude Code CLI ou SDK;
- `antigravity_cli`: `agy` ou `antigravity`, como adapter experimental.

Detectar binario nao significa estar autenticado. Tambem nao significa que o
portal pode iniciar runtime. A descoberta responde apenas: "esta maquina parece
ter esse fornecedor instalado?"

## Contrato do projeto conectado

Campos obrigatorios:

- `project_path`;
- `repo_root`;
- `git_branch`;
- `git_remote`;
- `agents_contract_present`;
- `claude_adapter_present`;
- `provider_discovery`;
- `npx_entrypoint`;
- `local_script_equivalent`;
- `terminal_project_access_required`;
- `browser_filesystem_access_allowed`;
- `runtime_execution_allowed`;
- `human_confirmation_required_for_runtime`.

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
- `full_prompt_transcript`.

## Estados

- `not_connected`;
- `terminal_discovered`;
- `registered_read_only`;
- `waiting_for_provider_auth`;
- `waiting_for_vault_lease`;
- `waiting_for_budget`;
- `waiting_for_human_gate`;
- `ready_for_runtime_gateway`;
- `blocked`.

## Invariantes

- Projeto local so entra pelo terminal.
- `npx artemis connect` e discovery, nao runtime.
- O portal nao recebe token bruto nem secret.
- O portal nao escolhe pasta arbitraria do servidor.
- Provider instalado nao equivale a provider autenticado.
- Adapter experimental, como Antigravity CLI, fica bloqueado ate capability
  discovery e revisao de contrato.
- Runtime real exige Project Selector, Credential Vault, Budget Ledger,
  Workspace Session, Runtime Gateway, Human Gate e Validation Gate.

## Fora de escopo neste corte

- publicar pacote npm;
- alterar projeto alvo;
- gravar arquivo dentro de projeto externo;
- autenticar Codex, Claude Code ou Antigravity;
- iniciar app-server, SDK ou CLI;
- executar tarefas;
- abrir websocket;
- gastar tokens;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: renderizar o projeto conectado e os fornecedores
detectados no Control Plane antes de adicionar cadastro de projetos externos.
