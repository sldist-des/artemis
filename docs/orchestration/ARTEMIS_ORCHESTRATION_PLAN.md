# ARTEMIS Orchestration Plan

## 1. Decisao

ARTEMIS vai usar Symphony como inspiracao arquitetural, mas nao como copia literal.

Nome do sistema:

```text
ARTEMIS Orchestrator
```

Nome da superficie visual:

```text
ARTEMIS Control Plane
```

Evitar chamar a superficie principal de Kanban. O quadro visual pode ter colunas, mas a funcao real e controle operacional: estado, dono, evidencia, validacao, bloqueio e decisao humana.

## 2. Tese

Symphony orquestra agentes a partir de tarefas. ARTEMIS orquestra agentes a partir de tarefas com arquitetura, contexto, evidencia, validacao e revisao humana.

```text
Symphony: task -> workspace -> agent -> PR
ARTEMIS: intent -> context -> workspace -> agent -> validation -> evidence -> review -> human decision
```

O terminal continua soberano. O orquestrador deve reduzir supervisao manual, nao impedir intervencao humana direta.

## 3. Principios

### Simples

- Comecar local-first.
- Sem daemon ate o contrato estar claro.
- Sem banco ate haver necessidade real.
- Sem framework frontend ate a superficie local provar valor.

### State-of-the-art

- Usar a modelagem de thread/turn/item do Codex app-server.
- Usar a ideia Symphony de issue tracker como state machine.
- Usar Claude Code Agent SDK/headless, hooks e subagents como runner adapter.
- Usar testes, logs, screenshots e artifacts como produto da execucao.

### Completude

Uma tarefa orquestrada so pode ser considerada pronta quando tem:

- Exec Pack;
- workspace/worktree isolado;
- execucao registrada;
- validacao executada;
- evidencia anexada;
- revisao tecnica;
- decisao humana quando aplicavel;
- handoff final.

## 4. Arquitetura alvo

```text
ARTEMIS Control Plane
        |
        v
Task Source Adapter
  - Exec Packs locais
  - GitHub Issues
  - futuro: Linear/Notion
        |
        v
ARTEMIS Orchestrator
  - eligibility
  - bounded concurrency
  - retry/backoff
  - state reconciliation
  - stop/resume
        |
        v
Workspace Manager
  - branch
  - worktree
  - artifacts dir
  - cleanup policy
        |
        v
Runner Adapter
  - Codex CLI
  - Codex app-server
  - Claude Code headless / Agent SDK
        |
        v
Validation Gate
  - lint
  - tests
  - build
  - e2e
  - visual QA
  - security checks
        |
        v
Evidence Layer
  - logs
  - commands
  - diff
  - screenshots
  - PR links
  - handoff
```

## 5. Symphony: o que adotar

Adotar:

- tarefa como unidade de trabalho;
- estado da tarefa como state machine;
- workspace isolado por tarefa;
- runners sempre observaveis;
- retries com backoff;
- bounded concurrency;
- status surface para operador;
- restart recovery;
- workflow versionado no repo.

Nao adotar sem adaptacao:

- execucao continua sem gates;
- task tracker externo como unica fonte;
- merge automatizado sem revisao humana;
- agentes rodando sem evidencia minima;
- daemon antes de contrato operacional.

## 6. Codex app-server: uso planejado

Codex app-server deve ser tratado como runtime rico para uma fase posterior.

Mapeamento ARTEMIS:

| Codex app-server | ARTEMIS |
|---|---|
| Thread | Task / Exec Pack |
| Turn | tentativa de execucao ou revisao |
| Item | evento observavel |
| Approval request | gate humano ou policy gate |
| Notifications | eventos do Control Plane |
| Thread metadata | estado do workspace/tarefa |

Primeiro uso recomendado:

- leitor de eventos;
- captura de comandos, diffs e mensagens;
- alimentacao do Control Plane;
- nao como unica forma de controle.

## 7. Claude Code: uso planejado

Claude Code nao precisa ter app-server identico para participar.

Superficies equivalentes:

- headless CLI / `-p`;
- output JSON / stream JSON;
- Agent SDK;
- subagents;
- hooks;
- GitHub Actions.

Mapeamento ARTEMIS:

| Claude Code | ARTEMIS |
|---|---|
| headless run | Runner Adapter |
| stream-json | eventos para logs/control plane |
| subagents | agentes especializados |
| hooks | guardrails e evidencia |
| GitHub Actions | runner remoto supervisionado |

Claude deve seguir `AGENTS.md` como contrato comum. `CLAUDE.md` continua apenas adaptador fino.

## 8. Estados oficiais do Control Plane

| Estado | Significado | Entrada minima | Saida |
|---|---|---|---|
| Intake | demanda bruta | titulo e intencao | criar Exec Pack |
| Context | contexto em preparo | pedido e referencias | Exec Pack completo |
| Ready | pronto para execucao | escopo, validacao, owner | workspace criado |
| Running | agente executando | workspace e runner | diff/evidencia |
| Validating | gates rodando | comandos definidos | resultados |
| Review | revisao IA/tecnica | diff e evidencia | achados resolvidos |
| Human Gate | decisao humana | risco/resultado | aprovar, dividir, rejeitar |
| Handoff | entrega registrada | validação e decisao | mover para Done |
| Done | arquivado | handoff final | nenhum |
| Blocked | impedido | motivo claro | remover bloqueio |

## 9. Fases de implementacao

### Fase 0 - Renomear e alinhar linguagem

Objetivo: trocar “Kanban” por “Control Plane” onde for conceito principal.

Entregas:

- `control-plane/index.html`;
- docs atualizadas;
- redirect ou nota de compatibilidade para `kanban/index.html`;
- validacao local.

Aceite:

- nenhuma referencia conceitual nova chama o produto de Kanban;
- o quadro ainda abre localmente.

### Fase 1 - Spec do workflow

Objetivo: criar `ARTEMIS_WORKFLOW.md`, equivalente ARTEMIS ao `WORKFLOW.md` do Symphony.

Conteudo minimo:

- estados elegiveis;
- regras de dispatch;
- regras de parada;
- matriz de runners;
- comandos de validacao;
- formato de evidencia;
- politica de escalonamento.

Aceite:

- um agente consegue ler o workflow e saber quando pode agir;
- um humano consegue identificar quando deve intervir.

### Fase 2 - Task source local

Objetivo: ler Exec Packs locais e gerar estado do Control Plane.

Sem daemon ainda.

Entregas:

- script `scripts/artemis-tasks.sh` ou equivalente;
- saida JSON com tarefas, estados e evidencias;
- Control Plane carregando esse JSON estatico ou gerado.

Aceite:

- lista todos Exec Packs ativos;
- detecta artifacts existentes;
- nao escreve em tarefas.

### Fase 3 - Orchestrator dry-run

Objetivo: simular dispatch sem iniciar agentes.

Entregas:

- plano de dispatch;
- decisao de elegibilidade;
- razao para blocked/ready;
- logs estruturados.

Aceite:

- nenhuma execucao real ocorre;
- o operador ve exatamente o que seria iniciado.

### Fase 4 - Runner local supervisionado

Objetivo: permitir iniciar uma tarefa local com controle terminal-first.

Primeiro runner:

- Codex CLI em modo controlado.

Depois:

- Claude Code headless.

Aceite:

- cria worktree;
- grava log;
- grava artifact;
- roda validacao;
- para em Human Gate.

### Fase 5 - Validation Gate forte

Objetivo: tornar confiabilidade mensuravel.

Gates:

- `scripts/validate-artemis.sh`;
- lint/typecheck/build quando projeto alvo tiver;
- testes unitarios;
- e2e/smoke;
- screenshot/visual QA para UI;
- revisao IA;
- checagem de escopo contra Exec Pack.

Aceite:

- uma tarefa nao pode ir para Handoff sem resultado de gates;
- falhas viram Blocked ou Review, nao Done.

### Fase 6 - GitHub Issues adapter

Objetivo: usar GitHub como task source sem abandonar Exec Packs.

Regra:

```text
Issue define intencao.
Exec Pack define contrato.
Control Plane mostra estado.
```

Aceite:

- leitura de issues com labels ARTEMIS;
- links entre issue, Exec Pack, branch, PR e artifacts;
- nenhuma transicao destrutiva sem revisao.

### Fase 7 - Codex app-server adapter

Objetivo: capturar eventos ricos de Codex.

Aceite:

- thread id ligado ao Exec Pack;
- turn id ligado a tentativa;
- items relevantes viram eventos;
- approvals aparecem no Control Plane;
- terminal override continua possivel.

### Fase 8 - Claude Code adapter

Objetivo: tratar Claude Code como runner de mesmo nivel.

Aceite:

- execucao headless com JSON/stream quando viavel;
- hooks registram tool calls e stop/subagent stop;
- subagents especializados documentados;
- artifacts equivalentes aos do Codex runner.

## 10. Gatilhos de confiabilidade

Uma tarefa pode iniciar agente automaticamente somente se:

- Exec Pack completo;
- risco baixo ou medio permitido;
- worktree isolado disponivel;
- validacao definida;
- runner permitido;
- sem zona protegida;
- sem dependencia de decisao humana aberta.

Uma tarefa deve parar em Human Gate se:

- toca auth, billing, secrets, dados sensiveis ou producao;
- altera contrato publico;
- adiciona dependencia;
- falha em validacao;
- escopo cresce;
- agente cria follow-up arquitetural.

## 11. Acceptance criteria do plano

- Existe plano versionado de orquestracao.
- Existe decisao de nomenclatura: Control Plane, nao Kanban.
- Existem fases antes do daemon.
- Codex e Claude entram por adapters, nao por acoplamento direto ao metodo.
- Validacao e evidencia sao gates obrigatorios.
- Terminal override e requisito arquitetural explicito.

## 12. Riscos e mitigacoes

| Risco | Mitigacao |
|---|---|
| Orquestrador agir sem controle | dry-run antes de execucao real |
| Perder controle terminal-first | terminal override como invariant |
| Duplicar Symphony sem contexto ARTEMIS | spec propria antes de daemon |
| Claude e Codex divergirem | `AGENTS.md` canonico |
| Validacao fraca gerar falsa confianca | gates obrigatorios e artifacts |
| UI virar fonte de verdade | Exec Packs/artifacts continuam canonicos |

## 13. ADR

### Decisao

Criar ARTEMIS Orchestrator inspirado em Symphony, com Control Plane proprio e adapters para Codex/Claude.

### Drivers

- reduzir supervisao manual;
- manter controle humano;
- aumentar confiabilidade por validacao;
- permitir execucao multiagente sem perder rastreabilidade.

### Alternativas consideradas

1. Copiar Symphony diretamente.
   - Rejeitada: nao preserva as regras ARTEMIS de contexto, evidencia e handoff.

2. Usar apenas terminal interativo.
   - Rejeitada: nao escala bem para multiplas tarefas e agentes.

3. Criar daemon completo agora.
   - Rejeitada: risco alto antes de workflow, gates e nomenclatura estarem definidos.

### Por que escolhido

O caminho em fases permite usar o melhor de Symphony e app-server sem abrir mao de simplicidade, terminal-first e revisao humana.

### Consequencias

- O proximo trabalho deve ser renomear Kanban para Control Plane.
- O daemon so entra depois de dry-run e validation gates.
- Toda integracao com Codex/Claude deve passar por Runner Adapter.

### Follow-ups

- TKT-007: renomear Kanban para ARTEMIS Control Plane.
- TKT-008: criar `ARTEMIS_WORKFLOW.md`.
- TKT-009: criar task source local para Exec Packs.
- TKT-010: criar orchestrator dry-run.
