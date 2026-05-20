# ARTEMIS Portal Runtime Gateway

O Runtime Gateway e a fronteira operacional entre o painel ARTEMIS e os
runtimes reais de agentes.

Ele existe para permitir um portal multi-operador sem transformar o frontend em
terminal remoto irrestrito. O painel nao fala diretamente com Codex, Claude Code
ou outro CLI. O painel fala com o Gateway; o Gateway valida projeto, tarefa,
auth, budget, workspace, command plan, Human Gate e evidencia antes de chamar um
adapter.

## Regra central

Todo operador entra por adapter registrado. Nenhum provider recebe prompt,
token, comando ou workspace sem contrato aceito.

```text
Portal UI
  -> Runtime Gateway
  -> Project selector
  -> Operator registry
  -> Credential Vault lease
  -> Budget Ledger
  -> Workspace Session
  -> Command Plan
  -> Human Execution Gate
  -> Runtime Adapter
  -> Validation Evidence
  -> Human Acceptance
```

## Operadores suportados por contrato

### Codex app-server

Uso recomendado:

- tarefas longas;
- refactors complexos;
- execucao supervisionada com thread, turn, item, approvals e artifacts;
- verificacao forte antes de handoff.

O app-server nao deve ser iniciado pelo painel sem Gateway, lease, budget,
workspace, command plan e Human Gate.

### Claude Code

Uso recomendado:

- mapear repositorio;
- entender linguagem, framework e estrutura;
- executar slices curtos ou medios;
- produzir handoff ou revisao.

Claude Code nao precisa ter app-server identico. Ele participa como runtime
adapter de mesmo nivel, obedecendo `AGENTS.md`, workspace policy, budget,
evidencia e gates.

### Antigravity CLI

Uso recomendado neste contrato:

- runtime futuro/experimental;
- somente depois de descoberta local de CLI, auth, flags, modo headless,
  politica de logs e contrato de saida.

Enquanto a superficie oficial/local nao for confirmada, o estado deve ser
`unverified_adapter`. Ele pode aparecer no portal como opcao planejada, mas nao
como operador disponivel.

## Adapter record

Campos obrigatorios:

- `operator_id`;
- `display_name`;
- `provider_id`;
- `adapter`;
- `runtime_surface`;
- `connection_state`;
- `auth_state`;
- `credential_lease_required`;
- `budget_policy_required`;
- `workspace_session_required`;
- `command_plan_required`;
- `human_execution_gate_required`;
- `validation_required`;
- `cost_tracking_required`;
- `stop_rules`;
- `allowed_operations`;
- `forbidden_operations`;
- `evidence_outputs`.

Campos proibidos:

- `plaintext_secret`;
- `raw_access_token`;
- `raw_refresh_token`;
- `private_key_material`;
- `session_cookie`;
- `full_prompt_transcript`;
- `raw_runtime_stdout`;
- `raw_runtime_stderr`;
- `provider_billing_secret`;
- `git_remote_token`.

## Estados do Gateway

- `contract_only`;
- `waiting_for_project`;
- `waiting_for_operator_connection`;
- `waiting_for_credential_lease`;
- `waiting_for_budget`;
- `waiting_for_workspace`;
- `waiting_for_command_plan`;
- `waiting_for_human_execution_gate`;
- `ready_for_supervised_launch`;
- `running`;
- `paused`;
- `stopping`;
- `validating`;
- `waiting_for_human_acceptance`;
- `complete`;
- `blocked`;
- `disabled`.

## Operacoes do portal

Permitidas antes de runtime real:

- listar projetos registrados;
- listar operadores registrados;
- mostrar estado de conexao;
- criar tarefa em modo draft;
- gerar assignment;
- gerar command plan;
- pedir Human Gate;
- mostrar budget planejado;
- mostrar evidencia e validacao.

Proibidas antes de gate:

- enviar prompt para provider;
- iniciar app-server, Claude Code, Antigravity ou outro runtime;
- executar comando;
- gastar token;
- abrir websocket de runtime;
- escrever remoto;
- fazer push, PR ou deploy;
- armazenar secrets ou stdout/stderr bruto.

## Multi-operador

O ARTEMIS deve permitir varios operadores, mas com limites:

- um escritor por worktree;
- um runtime por assignment;
- varios leitores/verificadores podem existir se nao competirem pelo mesmo
  arquivo;
- perfis de alto custo precisam de budget explicito;
- perfis experimentais ficam bloqueados ate capability discovery;
- verifier nao aprova a propria execucao sem separacao de review;
- humano owner pode pausar, parar ou rejeitar a qualquer momento.

## Para leigos

O Gateway e o porteiro do painel.

O painel pode mostrar botoes como "pedir ao Codex" ou "pedir ao Claude", mas o
porteiro confere antes:

- qual projeto e;
- qual tarefa e;
- quem esta autorizado;
- quanto pode gastar;
- onde pode mexer;
- qual comando sera permitido;
- como provar que funcionou;
- quando uma pessoa precisa aprovar.

Se alguma dessas partes faltar, o agente nao roda.

## Fora de escopo neste corte

- iniciar Codex app-server;
- iniciar Claude Code;
- iniciar Antigravity CLI;
- autenticar provider;
- emitir lease real;
- gastar tokens;
- executar comandos;
- abrir websocket;
- fazer push, PR, deploy ou mutacao remota;
- armazenar prompts completos, secrets ou logs brutos.

Proximo corte recomendado: criar o endpoint/local service que exponha este
contrato para o Control Plane sem executar runtime real.
