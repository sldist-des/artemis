# ARTEMIS Symphony Spec

ARTEMIS Symphony e a especificacao do nosso orquestrador proprio inspirado pelo OpenAI Symphony, sem copiar sua implementacao.

## Decisao

Criar um Symphony ARTEMIS proprio:

- local-first;
- terminal-first;
- orientado por Exec Packs;
- com workspaces isolados;
- com eventos e evidencias versionadas;
- com Human Gates explicitos;
- compativel com Codex CLI, Codex app-server, Claude Code e GitHub Issues.

O OpenAI Symphony continua como referencia arquitetural externa. ARTEMIS Symphony e uma implementacao de metodo e contratos no repositorio ARTEMIS.

## Referencia externa

OpenAI Symphony descreve um servico que observa trabalho em um tracker, cria workspaces isolados, executa agentes, aplica um workflow versionado e publica evidencia observavel.

ARTEMIS adota a ideia operacional, mas muda as prioridades:

| Referencia Symphony | ARTEMIS Symphony |
|---|---|
| Tracker externo como origem frequente | Exec Pack local como contrato canonico, GitHub Issues como adapter |
| Servico longo | Fases locais verificaveis antes de daemon |
| Workspace isolado | Branch, worktree, lock e artifact root por tarefa |
| Coding agent runner | Runner Adapter para Codex CLI, Codex app-server e Claude Code |
| Workflow versionado | `ARTEMIS_WORKFLOW.md`, `AGENTS.md` e Exec Packs |
| Observabilidade | `events.json`, Validation Gate, Control Plane e handoff |
| PR como prova comum | Evidencia local primeiro; PR remoto continua Human Gate |

## Modelo de dominio

### Task

Unidade operacional. Em ARTEMIS, a fonte canonica e o Exec Pack em `docs/exec-packs/active/` ou `docs/exec-packs/done/`.

Campos minimos:

- ticket;
- titulo;
- estado;
- owner;
- risco;
- escopo;
- fora de escopo;
- validacao;
- evidencias obrigatorias.

### Workspace

Ambiente isolado para uma task.

Campos minimos:

- branch;
- worktree path;
- lock path;
- artifact root;
- writer;
- cleanup state.

### Attempt

Tentativa de execucao ou validacao feita por runner supervisionado.

Campos minimos:

- attempt id;
- comando;
- cwd;
- runner;
- resultado;
- logs;
- eventos canonicos.

### Gate

Ponto de parada por politica, risco, validacao ou decisao humana.

Tipos minimos:

- validation;
- policy;
- human;
- remote;
- cleanup;
- security.

### Evidence

Prova versionada de trabalho ou decisao.

Arquivos minimos por tarefa material:

- `STATUS.md`;
- `VALIDATION.md`;
- `HANDOFF.md`;
- JSON especifico do script, quando houver.

## State machine

```text
intake
  -> context
  -> ready
  -> planned
  -> running
  -> validating
  -> review
  -> human_gate
  -> handoff
  -> done
```

Estados alternativos:

- `blocked`: nao ha proximo passo seguro;
- `failed`: validacao tecnica falhou;
- `cancelled`: humano interrompeu o fluxo;
- `closed_without_execution`: contrato registrou que nada deve ser executado.

## Arquitetura alvo

```text
Task Source
  -> Eligibility Engine
  -> Workspace Manager
  -> Runner Adapter
  -> Validation Gate
  -> Review/Human Gate
  -> Evidence Layer
  -> Control Plane
```

## Camadas

### 1. Policy Layer

Arquivos:

- `AGENTS.md`;
- `ARTEMIS_WORKFLOW.md`;
- `docs/invariants/core.md`;
- Exec Packs.

Responsabilidade:

- definir regras operacionais;
- proteger escopo;
- preservar gates humanos;
- orientar Codex e Claude com a mesma fonte canonica.

### 2. Task Source Layer

Arquivos e scripts:

- `scripts/artemis-tasks.sh`;
- `scripts/artemis-github-issues.sh`;
- `control-plane/tasks.json`.

Responsabilidade:

- transformar Exec Packs e futuros trackers em tarefas;
- nao executar agentes;
- preservar estado canonico no repositorio.

### 3. Eligibility Layer

Arquivos e scripts:

- `scripts/artemis-dry-run.sh`;
- `scripts/artemis-workspace.sh`.

Responsabilidade:

- decidir se uma tarefa pode ser planejada;
- apontar Human Gate ou bloqueio;
- evitar execucao sem contrato minimo.

### 4. Workspace Layer

Arquivos e scripts:

- `scripts/artemis-workspace.sh`;
- `scripts/artemis-workspace-lifecycle.sh`;
- `scripts/artemis-workspace-cleanup-review.sh`.

Responsabilidade:

- criar e inventariar workspaces;
- controlar locks;
- separar cleanup real de revisao humana.

### 5. Runner Layer

Arquivos e scripts:

- `scripts/artemis-runner.sh`;
- `scripts/artemis-codex-app-server.sh`;
- `scripts/artemis-claude-code.sh`.

Responsabilidade:

- executar ou planejar tentativas supervisionadas;
- emitir eventos;
- manter terminal override.

### 6. Validation Layer

Arquivos e scripts:

- `scripts/validate-artemis.sh`;
- `scripts/artemis-validation-gate.sh`.

Responsabilidade:

- provar estado tecnico;
- separar falhas tecnicas de Human Gates;
- impedir handoff sem evidencia.

### 7. Evidence Layer

Arquivos:

- `artifacts/**/STATUS.md`;
- `artifacts/**/VALIDATION.md`;
- `artifacts/**/HANDOFF.md`;
- `artifacts/**/events.json`.

Responsabilidade:

- preservar memoria operacional;
- permitir retomada por humano, Codex ou Claude;
- alimentar Control Plane.

### 8. Control Plane Layer

Arquivos:

- `control-plane/index.html`;
- `control-plane/tasks.json`;
- `artifacts/artemis-event-log-schema/run-01/event-log.example.json`.

Responsabilidade:

- mostrar estado e evidencia;
- nao virar fonte canonica;
- operar sem daemon.

## Modos de execucao

### Modo 0 - Read-only local

Estado atual.

- gera tarefas;
- simula dispatch;
- valida readiness;
- registra artifacts.

Componente implementado:

- `scripts/artemis-symphony-kernel.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_KERNEL.md`

Contrato:

- le `control-plane/tasks.json` ou task source equivalente;
- usa `scripts/artemis-dry-run.sh` como fonte de elegibilidade;
- aplica bounded concurrency apenas no plano;
- escreve `symphony-kernel.json`, `dry-run.json`, `events.json`, `STATUS.md`, `VALIDATION.md` e `HANDOFF.md`;
- nao executa agentes.

### Modo 1 - Runner supervisionado local

Ja existe como contrato.

- planeja tentativa;
- exige `--execute` explicito;
- registra evento;
- pode usar worktree.

Ponte implementada:

- `scripts/artemis-symphony-bridge.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_BRIDGE.md`

Contrato:

- roda o kernel antes do runner;
- seleciona apenas tickets presentes no `dispatch_plan`;
- cria tentativa supervisionada plan-only por padrao;
- exige `--execute` para rodar comando;
- nao inicia daemon.

### Modo 2 - Symphony local daemon

Implementado como dry-run finito.

- observa `control-plane/tasks.json` ou Exec Packs;
- executa loop com polling;
- respeita bounded concurrency;
- nunca passa Human Gate automaticamente;
- registra heartbeat e plano;
- nao chama bridge ou runner automaticamente.

Daemon dry-run implementado:

- `scripts/artemis-symphony-daemon.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md`

Contrato:

- usa `--ticks` para manter a execucao finita e auditavel;
- chama apenas `scripts/artemis-symphony-kernel.sh`;
- escreve `symphony-daemon.json`, `heartbeat.json`, `heartbeat.jsonl`, `events.json`, `STATUS.md`, `VALIDATION.md` e `HANDOFF.md`;
- mantem `commands_executed=0`;
- mantem `runner_auto_execution_allowed=false`;
- preserva Human Gates observados pelo kernel.

### Modo 2.5 - Fila supervisionada local

Implementado como fila read-only revisavel.

- le `symphony-daemon.json`;
- abre o kernel do ultimo tick;
- transforma `dispatch_plan` em itens `review_required`;
- nao escolhe comando de execucao;
- nao chama bridge ou runner automaticamente.

Fila supervisionada implementada:

- `scripts/artemis-symphony-queue.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md`

Contrato:

- a fila e derivada de evidencia do daemon e do kernel;
- cada item exige terminal override;
- `bridge_called=false`;
- `runner_called=false`;
- `runner_auto_execution_allowed=false`;
- `commands_executed=0`;
- Human Gates continuam fora da fila executavel.

### Modo 2.6 - Queue Bridge plan-only

Implementado como ponte supervisionada a partir de um item revisado da fila.

- le `symphony-queue.json`;
- seleciona exatamente um item por `--ticket` ou `--queue-id`;
- exige comando explicito via `--command`;
- valida que o item esta em `review_required`;
- valida `terminal_override_required=true`;
- chama `scripts/artemis-symphony-bridge.sh` sem `--execute`;
- mantem `commands_executed=0`;
- registra `validation_gate_required_before_execute=true`.

Queue Bridge implementado:

- `scripts/artemis-symphony-queue-bridge.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md`

Contrato:

- a fila continua sendo entrada supervisionada, nao daemon executavel;
- a chamada ao bridge e plan-only neste corte;
- `execute_requested=false`;
- `runner_executed=false`;
- Human Gates continuam explicitos;
- execucao real fica reservada para corte posterior com Validation Gate.

### Modo 2.7 - Queue Execution opt-in

Implementado como extensao explicita do Queue Bridge.

- `--execute` e opt-in no terminal;
- `--validation-gate` e obrigatorio;
- `--decision` e obrigatorio;
- Validation Gate deve ter `summary.failed=0`;
- se Validation Gate estiver em `human_gate`, a decisao deve reconhecer os
  Human Gates externos;
- a decisao deve ter `decision=approved`;
- `ticket`, `queue_id`, `command` e `validation_gate` devem bater exatamente;
- o bridge recebe `--execute` somente depois dessas validacoes;
- o runner continua bloqueando comandos remotos, destrutivos e deploys.

Execucao opt-in implementada:

- `scripts/artemis-symphony-queue-bridge.sh --execute`
- `docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md`

Contrato:

- modo padrao continua plan-only;
- `commands_executed=1` so ocorre quando `execute_requested=true`,
  Validation Gate passa e a decisao e exata;
- Human Gates continuam explicitos;
- execucao real nao pode ser disparada por daemon, fila read-only ou Control
  Plane.

### Modo 2.8 - Service supervisionado finito

Implementado como ciclo local que compoe daemon, fila e Queue Bridge plan-only.

- roda daemon dry-run finito;
- materializa fila supervisionada;
- chama Queue Bridge apenas quando o terminal fornece ticket ou queue id e
  comando explicitos;
- nao aceita `--execute`;
- nunca passa `--execute` para o Queue Bridge;
- mantem `commands_executed=0`;
- encerra ao final do ciclo, sem processo persistente.

Service supervisionado implementado:

- `scripts/artemis-symphony-service.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_SERVICE.md`

Contrato:

- service e agregador local de evidencias, nao executor automatico;
- terminal override continua obrigatorio;
- execucao real continua pertencendo ao Queue Bridge com `--execute`,
  Validation Gate e decisao exata;
- Human Gates continuam explicitos;
- Control Plane continua observacional.

### Modo 3 - Fonte remota supervisionada

Implementado em `TKT-050` como Remote Source de intake read-only a partir do
GitHub Issues adapter.

- consome `scripts/artemis-github-issues.sh`;
- normaliza issues em `task-source.json` supervisionado;
- preserva GitHub Issues como intencao/evidencia, nao autoridade;
- exige Exec Pack local como contrato de execucao;
- bloqueia dispatch direto;
- bloqueia escritas remotas;
- mantem `commands_executed=0`;
- registra evento canonico para Control Plane e handoff.

Fonte remota supervisionada implementada:

- `scripts/artemis-symphony-remote-source.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_SOURCE.md`

Contrato:

- GitHub Issues como task source remoto supervisionado;
- PR como evidencia futura, nao como gatilho automatico;
- branch protection e CODEOWNERS continuam humanos;
- push/merge continuam gates humanos ate politica real ser definida;
- item remoto precisa passar por intake revisavel antes de fila/service.

### Modo 3.1 - Intake remoto revisavel

Implementado em `TKT-051` como revisao read-only antes de qualquer promocao
local.

- consome `remote-source.json`;
- valida binding local de Exec Pack, owner, risco e URL remota;
- gera `remote-intake.json` e `review-source.json`;
- mantem `review-source.json` em `state=human`;
- bloqueia promocao automatica;
- bloqueia dispatch direto;
- bloqueia escritas remotas;
- mantem `commands_executed=0`;
- registra evento canonico para Control Plane e handoff.

Intake remoto revisavel implementado:

- `scripts/artemis-symphony-remote-intake.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_INTAKE.md`

Contrato:

- Remote Intake e pacote de revisao, nao executor;
- item remoto revisado so pode virar fonte local executavel apos decisao
  humana explicita em corte posterior;
- Queue, Service, Bridge e Runner nao sao chamados pelo intake;
- Human Gates continuam explicitos.

### Modo 3.2 - Remote Promotion / Promocao local do intake remoto

Implementado em `TKT-052` como gate de decisao humana exata entre Remote Intake
e qualquer fonte local executavel.

- consome `remote-intake.json`;
- exige arquivo de decisao com ticket, Exec Pack, owner, risco, evidencia,
  comando terminal, Validation Gate e aprovador;
- aceita apenas item `review_ready`;
- gera `remote-promotion.json` e `promoted-source.json`;
- fonte promovida fica local em `state=ready`;
- registra comando terminal, mas nao executa;
- nao chama Queue, Service, Bridge ou Runner;
- bloqueia dispatch direto;
- bloqueia escritas remotas;
- mantem `commands_executed=0`;
- registra evento canonico para Control Plane e handoff.

Promocao local implementada:

- `scripts/artemis-symphony-remote-promotion.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_PROMOTION.md`

Contrato:

- Remote Intake define revisao, nao autoridade de execucao;
- decisao humana exata define autoridade de promocao local;
- Exec Pack local continua sendo contrato de execucao;
- Validation Gate continua obrigatorio antes de qualquer execucao posterior;
- PRs, comentarios, labels e branches continuam bloqueados ate contrato
  explicito.

### Modo 3.3 - Memory Zone humano-AI

Implementado em `TKT-053` como contrato read-only de memoria compartilhada entre
humanos, Codex, Claude Code e futuros agentes.

- usa Tolaria como referencia de vault markdown/git humano-AI;
- usa CocoIndex como referencia de indice incremental com freshness e lineage;
- separa Human Vault, Project Memory e Derived Index;
- trata markdown, artifacts e git como fontes de verdade portaveis;
- trata indices derivados como read models reconstruiveis;
- exclui secrets e credenciais por padrao;
- nao instala novas dependencias;
- nao inicia indexador, banco, embeddings ou runtime;
- registra evento canonico para Control Plane e handoff.

Memory Zone implementada:

- `scripts/artemis-memory-zone.sh`
- `docs/memory/ARTEMIS_MEMORY_ZONE.md`

Contrato:

- Memory Zone fornece contexto, nao autoridade de execucao;
- agentes podem propor atualizacoes de memoria, mas alteracoes sensiveis passam
  por Human Gate;
- Project Operations Graph consome essa memoria como contexto;
- nenhum indice derivado substitui arquivos fonte, artifacts ou git.

### Modo 3.4 - Project Operations Graph

Implementado em `TKT-054` como contrato read-only do grafo operacional do
projeto.

- modela projeto, tarefas, agentes, gates, validacao, memoria, custos e
  artifacts;
- usa `control-plane/tasks.json`, Event Log, Validation Gate e Memory Zone como
  entradas;
- gera nos e arestas auditaveis por evidencia local;
- responde perguntas operacionais sobre estado, responsaveis, bloqueios,
  validacao, contexto seguro e custo;
- nao instala banco de grafo, embeddings, indexador ou runtime;
- nao executa agentes;
- nao substitui Exec Packs, artifacts, Event Log ou Git.

Project Operations Graph implementado:

- `scripts/artemis-project-graph.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md`

Contrato:

- o grafo e read model, nao autoridade de execucao;
- cada aresta precisa ser explicavel por evidencia local;
- Control Plane pode consumir o grafo, mas continua observacional;
- Human Gates, Validation Gate e budget gates continuam nao bypassaveis.

### Modo 3.5 - Project Graph View

Implementado em `TKT-055` como visualizacao read-only do Project Operations
Graph no Control Plane.

- renderiza metricas, nos, relacoes, perguntas operacionais e limites;
- consome `artifacts/artemis-project-graph/run-01/project-graph.json`;
- usa HTML/CSS/JS local sem dependencia nova;
- nao inicia servidor persistente, banco de grafo, canvas engine ou runtime;
- nao executa agentes, runners, bridges ou filas;
- nao torna o Control Plane canonico.

Project Graph View implementado:

- `scripts/artemis-project-graph-view.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH_VIEW.md`

Contrato:

- a view e uma leitura operacional para humanos e agentes;
- a fonte de verdade continua em Git, Exec Packs, artifacts, Event Log e
  Validation Gate;
- qualquer interatividade futura que envolva runtime, auth, rede, custo ou
  escrita precisa passar por Human Gate.

### Modo 3.6 - Project Brief

Implementado em `TKT-056` como explicacao humana e acionavel do Project
Operations Graph.

- traduz o grafo para linguagem simples;
- mostra o que esta pronto, onde ha Human Gate e qual proxima acao faz sentido;
- serve como porta de entrada para pessoas que nao conhecem todos os artifacts;
- consome `artifacts/artemis-project-graph/run-01/project-graph.json`;
- consome `artifacts/artemis-project-graph-view/run-01/project-graph-view.json`;
- nao inicia runtime, runner, bridge, fila, agente, banco de grafo ou servidor;
- nao torna o briefing nem o Control Plane canonicos.

Project Brief implementado:

- `scripts/artemis-project-brief.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md`

Contrato:

- Project Brief e explicacao, nao fonte de verdade;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- qualquer modo guiado futuro precisa preservar terminal-first, budget gates e
  Human Gates.

### Modo 3.7 - Guided Collaboration

Implementado em `TKT-057` como entrada guiada read-only para pessoas escolherem
projeto, tarefa, perfil de agente, gates e evidencia antes de runtime real.

- consome Project Brief, Project Graph, task source e Control Plane;
- mostra projeto em foco, etapas de escolha, perfis de agente, Human Gates,
  budget/auth/remoto e evidencia esperada;
- diferencia Codex frontier, Claude Code rapido, verifier e humano owner;
- preserva terminal-first como trilha auditavel;
- nao inicia agente, app-server, SDK, bridge, queue, daemon ou servidor;
- nao autentica contas, nao cria issue, nao faz push, nao abre PR e nao aprova
  Human Gates.

Guided Collaboration implementado:

- `scripts/artemis-guided-collaboration.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_GUIDED_COLLABORATION.md`

Contrato:

- Guided Collaboration e orientacao operacional, nao fonte de verdade;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- escolhas guiadas futuras so podem virar execucao por contrato supervisionado
  explicito com budget, auth, comandos, rollback e evidencia.

### Modo 3.8 - Agent Launch Contract

Implementado em `TKT-058` como contrato supervisionado read-only antes de
qualquer lancamento real de Codex app-server, Claude Code, Codex terminal-first
ou verifier.

- consome Guided Collaboration, Project Brief, Project Graph, task source e
  Control Plane;
- explicita perfis de runtime, auth, budget, comando, workspace, rollback,
  evidencia e stop rule;
- define `execute=false` como padrao para todos os perfis;
- registra `agents_started=0`, `runtime_started=false`, `commands_executed=0` e
  `remote_writes_allowed=false`;
- exige Human Gate antes de contas pessoais, custo, rede, remoto, producao,
  secrets ou execucao longa;
- nao inicia app-server, SDK, CLI remota, subagente pago, fila, daemon, bridge
  ou qualquer processo de runtime.

Agent Launch Contract implementado:

- `scripts/artemis-agent-launch-contract.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md`

Contrato:

- Agent Launch Contract e preflight, nao launcher;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- o proximo runtime deve primeiro materializar um dry-run auditavel antes de
  permitir execucao real.

### Modo 3.9 - Agent Runtime Dry-Run

Implementado em `TKT-059` como ensaio auditavel entre o Agent Launch Contract e
qualquer runtime real de Codex app-server, Claude Code, Codex terminal-first ou
verifier.

- consome `agent-launch-contract.json`;
- materializa um pedido de runtime com projeto, tarefa, perfil, modelo, budget,
  auth, comando, workspace, rollback, evidencia e stop rule;
- registra preflight e runtime log sem iniciar app-server, SDK, CLI, subagente,
  fila, daemon ou runner real;
- mantem `execute=false`, `runtime_started=false`, `agents_started=0`,
  `commands_executed=0`, `paid_tokens_authorized=0` e
  `remote_writes_allowed=false`;
- conserva auth e budget como Human Gates antes de qualquer custo, rede, remoto,
  producao, secrets ou execucao longa;
- prepara o proximo corte para aprovar ou rejeitar runtime real com comando,
  escopo, custo e rollback exatos.

Agent Runtime Dry-Run implementado:

- `scripts/artemis-agent-runtime-dry-run.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DRY_RUN.md`

Contrato:

- Agent Runtime Dry-Run e ensaio, nao launcher;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- qualquer runtime real ainda depende de Human Gate explicito com budget, auth,
  comando, workspace, rollback e evidencia.

### Modo 3.10 - Agent Runtime Approval Gate

Implementado em `TKT-060` como gate humano entre o dry-run de runtime e qualquer
tentativa futura de launcher real.

- consome `runtime-dry-run.json`;
- gera pacote de aprovacao humana com pedido, requisitos, checklist, template de
  decisao, validacao e handoff;
- mantem a decisao inicial como `pending`;
- aceita apenas `pending`, `approved`, `deferred` e `rejected`;
- `approved` exige identidade humana, timestamp, razao, perfil, runtime,
  politica de comando, politica de modelo, budget positivo, auth, workspace,
  rollback, validacao e comandos aprovados exatos;
- `pending`, `deferred` e `rejected` nao podem liberar comandos;
- nao inicia Codex app-server, Claude Code, SDK, CLI, subagente, fila, daemon,
  dependencia, push, PR, deploy, segredo, producao ou tokens pagos.

Agent Runtime Approval Gate implementado:

- `scripts/artemis-agent-runtime-approval-gate.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_APPROVAL_GATE.md`

Resultado esperado:

- `agent_runtime_approval_gate_ready`;
- `runtime_execution_allowed=false`;
- `execute=false`;
- `commands_executed=0`;
- `paid_tokens_authorized=0`;
- evento canonico `approval.requested`.

### Modo 3.11 - Agent Runtime Decision Intake

Implementado em `TKT-061` como intake read-only da decisao humana emitida pelo
Agent Runtime Approval Gate.

- consome `runtime-approval-gate.json` e `runtime-approval-decision.json`;
- classifica a decisao como `pending`, `approved_ready`, `deferred`,
  `rejected` ou `invalid`;
- preserva `runtime_execution_allowed=false` e `commands_executed=0`;
- libera apenas `launcher_preflight_allowed=true` quando a decisao humana
  aprovada estiver completa, coerente e rastreavel;
- valida identidade, timestamp ISO, razao, projeto, tarefa, perfil, runtime,
  superficie de comando, politica de modelo, budget, auth, workspace, rollback,
  validacao e comandos aprovados exatos;
- rejeita comandos remotos ou produtivos como `git push`, `gh pr`, `gh issue`,
  `gh repo`, `gh api`, `deploy`, `kubectl`, `scp`, `rsync` e `ssh`;
- nao inicia Codex app-server, Claude Code, SDK, CLI, subagente, fila, daemon,
  dependencia, push, PR, deploy, segredo, producao ou tokens pagos.

Agent Runtime Decision Intake implementado:

- `scripts/artemis-agent-runtime-decision-intake.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DECISION_INTAKE.md`

Resultado esperado:

- `human_gate` enquanto a decisao estiver `pending`;
- `ready_for_launcher_preflight` apenas para `approved_ready`;
- `launcher_preflight_allowed=false` por padrao;
- `runtime_execution_allowed=false`;
- `commands_executed=0`;
- evento canonico `approval.intake_recorded`.

### Modo 3.12 - Agent Runtime Launcher Preflight

Implementado em `TKT-062` como preflight read-only entre o Decision Intake e
qualquer plano futuro de comandos de launcher.

- consome `runtime-decision-intake.json`;
- exige `overall=ready_for_launcher_preflight`, `intake_state=approved_ready`
  e `launcher_preflight_allowed=true` para ficar pronto;
- enquanto a decisao humana estiver `pending`, permanece em `human_gate` com
  `preflight_state=waiting_for_approved_ready`;
- revalida identidade, timestamp, runtime, perfil, superficie de comando,
  comandos aprovados, budget, auth, workspace, branch, dirty state, rollback e
  evidencias de validacao;
- captura contexto Git (`branch`, `HEAD` e dirty state) como evidencia;
- produz `launcher_package` apenas para o proximo corte de planejamento;
- nao inicia Codex app-server, Claude Code, SDK, CLI, subagente, fila, daemon,
  dependencia, push, PR, deploy, segredo, producao ou tokens pagos.

Agent Runtime Launcher Preflight implementado:

- `scripts/artemis-agent-runtime-launcher-preflight.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_PREFLIGHT.md`

Resultado esperado:

- `human_gate` enquanto o Decision Intake nao estiver `approved_ready`;
- `launcher_preflight_ready` apenas quando a decisao aprovada passar na
  revalidacao local;
- `launcher_execution_allowed=false`;
- `runtime_execution_allowed=false`;
- `commands_executed=0`;
- evento canonico `runner.preflight_recorded`.

### Modo 3.13 - Agent Runtime Launcher Command Plan

Implementado em `TKT-063` como plano read-only entre o Launcher Preflight e
qualquer futura execucao supervisionada.

- consome `launcher-preflight.json`;
- exige `overall=launcher_preflight_ready`, `preflight_state=preflight_ready`
  e `launcher_preflight_allowed=true` para ficar pronto;
- enquanto o preflight estiver em Human Gate, permanece em `human_gate` com
  `plan_state=waiting_for_launcher_preflight_ready`;
- materializa comandos planejados apenas a partir do `launcher_package`;
- vincula runtime, profile, command surface, budget, stop rule, workspace,
  rollback, logs e validacoes;
- captura contexto Git (`branch`, `HEAD` e dirty state) como evidencia;
- nao inicia Codex app-server, Claude Code, SDK, CLI, subagente, fila, daemon,
  dependencia, push, PR, deploy, segredo, producao ou tokens pagos;
- nao executa comandos planejados.

Agent Runtime Launcher Command Plan implementado:

- `scripts/artemis-agent-runtime-launcher-command-plan.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_COMMAND_PLAN.md`

Resultado esperado:

- `human_gate` enquanto o Launcher Preflight nao estiver
  `launcher_preflight_ready`;
- `launcher_command_plan_ready` apenas quando o preflight aprovado passar na
  materializacao local;
- `launcher_execution_allowed=false`;
- `runtime_execution_allowed=false`;
- `commands_executed=0`;
- evento canonico `runner.attempt_planned`.

## Invariantes

- ARTEMIS Symphony nao executa cleanup real sem decisao humana.
- ARTEMIS Symphony nao faz push, PR, merge ou configuracao remota sem gate humano.
- Exec Pack e contrato canonico de tarefa.
- `AGENTS.md` e fonte canonica para agentes.
- Control Plane e visualizacao, nao fonte de verdade.
- Todo runner deve emitir evidencia.
- Toda conclusao precisa de validacao ou handoff honesto.

## Proximo corte recomendado

`TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`

Objetivo:

- consumir apenas `launcher-command-plan.json` em estado
  `launcher_command_plan_ready`;
- criar um gate explicito antes de qualquer execucao real;
- exigir confirmacao final de comando, budget, logs, rollback, validacao e
  limites de remoto/producao/secrets;
- preservar controle terminal-first e Human Gates antes de acionar agentes.

Esse sera o proximo passo de implementacao do nosso Symphony proprio.
