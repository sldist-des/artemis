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

Tratar a superficie principal como ARTEMIS Control Plane. O quadro visual pode ter colunas, mas a funcao real e controle operacional: estado, dono, evidencia, validacao, bloqueio e decisao humana.

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

Objetivo: consolidar ARTEMIS Control Plane como nome da superficie visual e operacional.

Entregas:

- `control-plane/index.html`;
- docs atualizadas;
- nota de compatibilidade somente se uma URL publica antiga existir;
- validacao local.

Aceite:

- nenhuma referencia conceitual nova usa vocabulario de quadro generico como nome do produto;
- o quadro ainda abre localmente.

### Fase 1 - Spec do workflow

Objetivo: criar `ARTEMIS_WORKFLOW.md`, equivalente ARTEMIS ao `WORKFLOW.md` do Symphony.

Estado: concluido em TKT-008.

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

Estado: concluido em TKT-009.

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

Estado: concluido em TKT-010.

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

Estado: concluido em TKT-011.

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

Estado: concluido em TKT-012.

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

Estado: concluido localmente em TKT-013; segue em Human Gate para autenticacao GitHub real.

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

Estado: concluido como contrato local read-only em TKT-014.

Aceite:

- thread id ligado ao Exec Pack;
- turn id ligado a tentativa;
- items relevantes viram eventos;
- approvals aparecem no Control Plane;
- terminal override continua possivel.

### Fase 8 - Claude Code adapter

Objetivo: tratar Claude Code como runner de mesmo nivel.

Estado: concluido como contrato local read-only em TKT-015.

Aceite:

- execucao headless com JSON/stream quando viavel;
- hooks registram tool calls e stop/subagent stop;
- subagents especializados documentados;
- artifacts equivalentes aos do Codex runner.

### Fase 9 - Event log canonico

Objetivo: unificar eventos vindos de Exec Packs, GitHub Issues, Codex app-server e Claude Code.

Estado: concluido como schema e exemplo read-only em TKT-016.

Aceite:

- schema versionado para eventos ARTEMIS;
- adapters produzem campos compativeis;
- Control Plane consegue consumir eventos sem virar fonte canonica;
- Human Gates e evidencias ficam rastreaveis por ticket, tentativa e runner.

### Fase 10 - Adapters emitindo eventos canonicos

Objetivo: fazer os adapters existentes emitirem `events.json` no schema ARTEMIS.

Estado: concluido em TKT-017.

Aceite:

- GitHub Issues adapter emite eventos canonicos;
- Codex app-server adapter emite eventos canonicos;
- Claude Code adapter emite eventos canonicos;
- Validation Gate valida existencia dos eventos;
- JSON especifico de cada adapter continua disponivel para diagnostico.

### Fase 11 - Timeline de eventos no Control Plane

Objetivo: renderizar o event log canonico no Control Plane como timeline read-only.

Estado: concluido em TKT-018.

Aceite:

- Control Plane carrega event log local quando servido por HTTP;
- eventos aparecem como timeline compacta;
- timeline aponta para artifacts;
- timeline nao permite alterar estado canonico;
- fallback continua funcional quando `events.json` nao existe.

### Fase 12 - Workspace Manager ARTEMIS

Objetivo: definir o contrato local para worktrees, branches, locks e artifacts por tarefa antes de automatizar execucao paralela.

Estado: concluido em TKT-019.

Aceite:

- cada tarefa elegivel tem estrategia explicita de workspace;
- um agente escritor por worktree continua garantido;
- conflitos e mudancas fora de escopo geram Human Gate;
- limpeza de workspace e handoff ficam auditaveis;
- dry-run consegue explicar por que uma tarefa pode ou nao iniciar.

### Fase 13 - Eventos de tentativa do runner

Objetivo: fazer o runner supervisionado registrar ciclo de tentativa como eventos canonicos.

Estado: concluido em TKT-020.

Aceite:

- tentativa planejada gera `runner.attempt_planned`;
- tentativa executada gera `runner.attempt_started` e `runner.attempt_completed`;
- `workspace.json`, `dry-run.json`, comando e resultado aparecem como evidencia;
- falha tecnica vira evento com severidade adequada;
- Control Plane consegue consumir o ciclo sem editar estado canonico.

### Fase 14 - Materializacao controlada de workspace

Objetivo: criar branch, worktree e lock local somente quando readiness estiver `ready` e houver comando explicito.

Estado: concluido em TKT-021.

Aceite:

- `scripts/artemis-workspace.sh` ganha modo explicito de criacao ou comando dedicado;
- nenhum workspace e criado sem flag clara;
- lock registra ticket, writer, branch e artifact root;
- conflitos permanecem Human Gate;
- limpeza/abandono de workspace fica documentada.

### Fase 15 - Execucao no workspace materializado

Objetivo: fazer o runner supervisionado executar comandos dentro do worktree materializado quando explicitamente solicitado.

Estado: concluido em TKT-022.

Aceite:

- runner verifica lock/worktree antes de executar;
- cwd real aparece em artifacts e eventos;
- execucao em main worktree nao e usada para escrita quando workspace materializado estiver ativo;
- comandos remotos, destrutivos e deploy continuam Human Gate;
- runner continua terminal-first e sem daemon.

### Fase 16 - Loop de validacao e fix

Objetivo: formalizar nova tentativa de fix/retry no workspace isolado quando uma validacao falha.

Estado: concluido em TKT-023.

Aceite:

- tentativa falha vira `blocked`;
- retry preserva evidencia anterior;
- nova tentativa registra eventos canonicos;
- handoff explica o que falhou, o que mudou e o que foi revalidado;
- Human Gate vence quando escopo, risco ou conflito crescem.

### Fase 17 - Inventario de lifecycle de workspaces

Objetivo: listar workspaces, branches, locks e artifact roots ARTEMIS sem executar limpeza automatica.

Estado: concluido em TKT-024.

Aceite:

- inventario le locks e worktrees locais;
- cada workspace mostra branch, lock, artifact root e estado de revisao;
- divergencias viram decisao humana documentada;
- nenhum worktree ou lock e removido automaticamente;
- artifacts registram o estado local antes de qualquer decisao de limpeza.

### Fase 18 - Revisao de cleanup de workspace

Objetivo: definir o procedimento humano para remover worktrees, branches locais e locks depois do inventario.

Estado: concluido em TKT-025.

Aceite:

- cleanup continua manual e auditavel;
- inventario de lifecycle e pre-condicao;
- workspace sujo ou branch nao integrada exige decisao humana;
- remocao local registra artifact de decisao;
- push, merge e PR continuam fora do fluxo automatico.

### Fase 19 - Execucao local de cleanup aprovada

Objetivo: definir se ARTEMIS deve ter um executor local de cleanup que so rode comandos aprovados explicitamente no artifact de decisao humana.

Estado: concluido em TKT-026.

Aceite:

- executor recusa decisoes `pending`, `deferred` ou sem comandos explicitos;
- comandos permitidos sao estritamente locais;
- remocao de worktree, lock e branch local e auditada;
- dry-run continua disponivel antes de qualquer execucao;
- GitHub remoto continua Human Gate.

### Fase 20 - Handoff de runtime local limpo

Objetivo: decidir como registrar que workspaces locais foram limpos ou mantidos depois de uma decisao humana.

Estado: concluido em TKT-027.

Aceite:

- resultado de cleanup vira artifact duravel;
- workspaces mantidos continuam listados no inventario;
- nenhuma memoria local e apagada sem registro;
- Control Plane mostra workspace limpo, mantido ou pendente;
- push e sincronizacao remota continuam Human Gate.

### Fase 21 - Politica de aprovacao humana para cleanup

Objetivo: definir o formato minimo da decisao humana aprovada para que um executor local possa sair de `pending`.

Estado: concluido em TKT-028.

Aceite:

- template de decisao vira schema ou contrato validavel;
- aprovacao exige identidade, timestamp e razao;
- comandos aprovados devem ser exatos e auditaveis;
- decisao parcial mantem workspace pendente;
- execucao continua fora ate decisao real existir.

### Fase 22 - Estados de decisao no handoff de runtime

Objetivo: refletir `deferred` e `rejected` no handoff local sem executar cleanup.

Estado: concluido em TKT-029.

Aceite:

- runtime handoff diferencia decisao aberta, deferida e rejeitada;
- workspace rejeitado nao some do historico;
- decisao deferida preserva proximo passo humano;
- Control Plane mostra o estado de decisao sem sugerir execucao automatica.

### Fase 23 - Fixtures de decisao humana

Objetivo: criar fixtures documentadas para `approved`, `deferred`, `rejected` e casos invalidos sem tocar workspaces reais.

Estado: concluido em TKT-030.

Aceite:

- fixtures vivem sob `artifacts` ou `docs` e sao claramente nao-executaveis;
- validacao cobre decisao aprovada exata, parcial invalida, deferida e rejeitada;
- executor continua dry-run por padrao;
- fixtures nao referenciam worktrees reais como alvo de execucao.

### Fase 24 - Pacote de decisao humana real

Objetivo: preparar um pacote de decisao real para TKT-021, TKT-022 e TKT-023 sem executar cleanup automaticamente.

Estado: concluido em TKT-031.

Aceite:

- pacote mostra opcoes `approved`, `deferred` e `rejected` por workspace;
- humano consegue preencher identidade, timestamp e razao;
- comando de validacao informa exatamente o que ficaria pronto;
- execucao real continua fora ate aprovacao humana explicita.

### Fase 25 - Human Gate visual para cleanup real

Objetivo: expor o estado do pacote real de decisao no Control Plane sem sugerir execucao automatica.

Estado: concluido em TKT-032.

Aceite:

- Control Plane mostra que decisoes reais continuam `pending`;
- evidencia aponta para o pacote real preenchivel;
- UI nao apresenta cleanup como acao automatica;
- validacao continua mostrando Human Gate ate decisao humana preenchida.

### Fase 26 - Runbook assistido de decisao humana

Objetivo: orientar o humano a preencher o pacote real de decisao sem que o agente aprove ou execute cleanup.

Estado: concluido em TKT-033.

Aceite:

- runbook deixa claro quando usar `approved`, `deferred` e `rejected`;
- timestamp, identidade e razao ficam obrigatorios;
- comandos exatos sao destacados como requisito de aprovacao;
- validacao continua antes de qualquer executor.

### Fase 27 - Consistencia do runbook de decisao humana

Objetivo: validar que o runbook assistido nao diverge do pacote real de decisao.

Estado: concluido em TKT-034.

Aceite:

- comandos documentados batem com `real-cleanup-decision.json`;
- tickets e evidencias esperadas sao conferidos;
- exemplos continuam claramente nao-executaveis;
- checagem permanece read-only e sem `--execute`.

### Fase 28 - Checkpoint local do pacote de decisao humana

Objetivo: consolidar a camada de decisao humana de cleanup como pacote local pronto para uso supervisionado.

Estado: concluido em TKT-035.

Aceite:

- evidencias de pacote real, runbook, consistencia e Control Plane ficam reunidas;
- riscos residuais sao registrados;
- cleanup real continua Human Gate;
- proximo corte fica claro antes de qualquer execucao.

### Fase 29 - Intake supervisionado da decisao humana

Objetivo: validar uma decisao humana preenchida em modo read-only antes de qualquer executor de cleanup.

Estado: concluido em TKT-036.

Aceite:

- decisao preenchida e classificada como `approved_ready`, `deferred`, `rejected`, `pending` ou `invalid`;
- nenhum comando com `--execute` e emitido;
- aprovacao parcial segue bloqueada;
- handoff aponta explicitamente se o proximo passo e executor supervisionado ou novo Human Gate.

### Fase 30 - Human Gate de decisao pendente

Objetivo: registrar a pausa operacional enquanto a decisao humana real continua pendente.

Estado: concluido em TKT-037.

Aceite:

- artifact declara que `pending` nao autoriza cleanup;
- campos humanos obrigatorios ficam listados;
- comandos de validacao apos preenchimento ficam claros;
- reentrada segura aponta de volta para o intake antes de qualquer executor.

### Fase 31 - Contrato de reentrada apos decisao humana

Objetivo: definir o caminho read-only depois que o humano preencher a decisao real.

Estado: proximo corte em TKT-038.

Aceite:

- estados de reentrada sao explicitos;
- `approved_ready` aponta apenas para preflight futuro;
- estados `pending`, `deferred`, `rejected` e `invalid` permanecem sem executor;
- comandos de validacao de retorno ficam versionados.

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
- Existe decisao de nomenclatura: ARTEMIS Control Plane.
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

- O proximo trabalho deve concluir a renomeacao para ARTEMIS Control Plane.
- O daemon so entra depois de dry-run e validation gates.
- Toda integracao com Codex/Claude deve passar por Runner Adapter.

### Follow-ups

- TKT-014: preparar Codex app-server adapter.
