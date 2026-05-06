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

Alvo futuro.

- observa `control-plane/tasks.json` ou Exec Packs;
- executa loop com polling;
- respeita bounded concurrency;
- nunca passa Human Gate automaticamente;
- chama runner supervisionado somente para tarefas elegiveis.

### Modo 3 - Tracker remoto

Futuro.

- GitHub Issues como task source remoto;
- PR como evidencia;
- branch protection e CODEOWNERS humanos;
- push/merge continuam gates humanos ate politica real ser definida.

## Invariantes

- ARTEMIS Symphony nao executa cleanup real sem decisao humana.
- ARTEMIS Symphony nao faz push, PR, merge ou configuracao remota sem gate humano.
- Exec Pack e contrato canonico de tarefa.
- `AGENTS.md` e fonte canonica para agentes.
- Control Plane e visualizacao, nao fonte de verdade.
- Todo runner deve emitir evidencia.
- Toda conclusao precisa de validacao ou handoff honesto.

## Proximo corte recomendado

`TKT-044 - Control Plane do ARTEMIS Symphony Bridge`

Objetivo:

- expor evidencias de kernel, bridge e runner;
- preservar Control Plane como superficie observacional;
- mostrar comandos executados, quando houver;
- manter Exec Pack como fonte canonica.

Esse sera o terceiro passo de implementacao do nosso Symphony proprio.
