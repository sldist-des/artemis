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
- Project Operations Graph deve consumir essa memoria no proximo corte;
- nenhum indice derivado substitui arquivos fonte, artifacts ou git.

## Invariantes

- ARTEMIS Symphony nao executa cleanup real sem decisao humana.
- ARTEMIS Symphony nao faz push, PR, merge ou configuracao remota sem gate humano.
- Exec Pack e contrato canonico de tarefa.
- `AGENTS.md` e fonte canonica para agentes.
- Control Plane e visualizacao, nao fonte de verdade.
- Todo runner deve emitir evidencia.
- Toda conclusao precisa de validacao ou handoff honesto.

## Proximo corte recomendado

`TKT-054 - Project Operations Graph do ARTEMIS Symphony`

Objetivo:

- modelar projeto, tarefas, agentes, dependencias, gates, validacoes, custos,
  memoria e artifacts como grafo operacional;
- usar Memory Zone como fonte de contexto;
- preparar o Control Plane operacional para mostrar estado vivo do projeto;
- preservar terminal-first, Human Gates, Validation Gate e budget gates.

Esse sera o decimo terceiro passo de implementacao do nosso Symphony proprio.
