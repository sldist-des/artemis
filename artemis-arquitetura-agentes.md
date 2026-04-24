# ARTEMIS — Arquitetura Universal de Agentes de IA
## Documento complementar ao Fluxo ARTEMIS para Claude Code, Codex e agentes gerenciados

**Arquivo recomendado no repositório:** `docs/agents/ARTEMIS_AGENT_ARCHITECTURE.md`  
**Versão:** 1.0  
**Data de referência:** 2026-04-24  
**Status:** base arquitetural inicial  
**Escopo:** aplicável a qualquer projeto que use Claude Code, Codex, OpenAI Agents SDK, Claude Managed Agents, MCP, skills, hooks, sandboxes, worktrees e automações agentic.

---

## 1. Propósito

Este documento define a arquitetura ideal de agentes para o processo **ARTEMIS**.

O objetivo não é criar uma frota exagerada de agentes. O objetivo é criar um padrão que permita que **Claude Code e Codex construam, adaptem e mantenham a própria arquitetura de agentes do projeto**, sempre dentro de uma estrutura controlada, auditável e sustentável.

A arquitetura deve funcionar para:

- projetos pequenos, com um único agente executor;
- projetos médios, com separação entre preparação, implementação e revisão;
- projetos grandes, com múltiplos agentes especializados, worktrees, sandboxes, evidências e trilhas de revisão;
- produtos futuros, nos quais a arquitetura de agentes deixa de ser apenas um fluxo de terminal e passa a virar parte do próprio sistema.

A regra central é:

> **Agentes não substituem arquitetura. Agentes operam dentro de uma arquitetura.**

---

## 2. Tese arquitetural

O ARTEMIS usa uma arquitetura em camadas, não uma hierarquia caótica de prompts.

As camadas são:

1. **Plano de Controle** — humano, prioridades, arquitetura, risco e aprovação.
2. **Plano de Contexto** — documentos, memória, Context Packs, ADRs e invariantes.
3. **Plano de Agentes** — papéis especializados que planejam, executam, revisam e preservam conhecimento.
4. **Plano de Ferramentas** — Claude Code, Codex, SDKs, MCP, shell, hooks, skills, CI, sandboxes e worktrees.
5. **Plano de Evidência** — artifacts, traces, logs, validações, diffs, handoffs e relatórios.
6. **Plano de Governança** — permissões, guardrails, políticas de risco, aprovações e zonas protegidas.
7. **Plano de Evolução** — atualização contínua conforme Codex, Claude Code, OpenAI Agents SDK e Claude Platform mudam.

Essa separação é importante porque ferramentas agentic mudam rápido. O ARTEMIS não deve depender de um recurso específico de uma versão específica. Ele deve manter um **modelo operacional estável** e adaptar as ferramentas por baixo.

---

## 3. Princípios obrigatórios

### 3.1 Começar simples e escalar somente quando houver ganho

Nem toda tarefa precisa de múltiplos agentes. O padrão ARTEMIS deve escalar por necessidade:

- uma tarefa simples usa um executor;
- uma tarefa relevante usa executor + revisor;
- uma tarefa grande usa preparador + executor + revisor + auditor específico;
- uma tarefa crítica usa worktree isolado, revisão cruzada, guardrails e evidência formal.

A regra é:

> **Mais agentes só entram quando reduzem risco, ruído ou tempo total.**

### 3.2 Workflows antes de agentes autônomos

Quando o caminho é previsível, use workflow. Quando o caminho é incerto, use agente.

Exemplos:

- gerar changelog a partir de commits: workflow;
- revisar arquitetura de uma mudança ampla: agente crítico;
- migrar um módulo desconhecido: agente executor com subagentes de pesquisa;
- classificar tarefas por prioridade: workflow com roteamento;
- investigar bug intermitente: agente com ferramentas e checkpoints.

### 3.3 Todo agente deve ter contrato

Nenhum agente deve existir apenas como “um prompt solto”. Cada agente precisa de uma ficha operacional:

- nome;
- missão;
- quando usar;
- quando não usar;
- ferramentas permitidas;
- entradas esperadas;
- saídas obrigatórias;
- critérios de parada;
- riscos;
- handoffs permitidos.

### 3.4 Handoff é contrato, não conversa

Quando um agente passa trabalho para outro, deve entregar um pacote estruturado:

- objetivo;
- contexto mínimo;
- arquivos relevantes;
- decisões já tomadas;
- riscos;
- pendências;
- evidências;
- próxima ação esperada.

### 3.5 Ferramentas perigosas precisam de fronteiras explícitas

Ferramentas de shell, patch, escrita em arquivo, banco de dados, cloud, deploy, browser automation e MCPs com ações externas precisam de política de uso.

A IA deve saber:

- o que pode fazer sem perguntar;
- o que pode fazer com confirmação;
- o que nunca pode fazer;
- o que precisa de revisão humana.

### 3.6 Evidência é parte da entrega

O trabalho de um agente não termina quando o código compila. Termina quando há evidência suficiente para revisar.

A entrega mínima é:

- resumo;
- diff ou lista de arquivos;
- comandos executados;
- resultado de validação;
- riscos remanescentes;
- próximos passos;
- handoff final.

---

## 4. Arquitetura em camadas

## 4.1 Plano de Controle

Responsável por governar o sistema.

Inclui:

- humano arquiteto;
- backlog;
- prioridades;
- roadmap;
- decisões estruturais;
- critérios de aceite;
- zonas de risco;
- política de merge.

O Plano de Controle decide **o que deve ser feito e sob quais limites**.

Documentos principais:

```text
ARCHITECTURE.md
docs/decisions/
docs/invariants/
docs/exec-packs/
docs/agents/
```

## 4.2 Plano de Contexto

Responsável por transformar informação dispersa em contexto utilizável pela IA.

Inclui:

- `AGENTS.md`;
- `CLAUDE.md`;
- Context Packs;
- ADRs;
- runbooks;
- scorecards;
- histórico de decisões;
- resumos de sessão;
- registro de capacidades das ferramentas.

O Plano de Contexto decide **o que o agente precisa saber para agir sem excesso de ruído**.

## 4.3 Plano de Agentes

Responsável por distribuir o trabalho entre papéis especializados.

Inclui:

- preparador de contexto;
- planejador;
- executor;
- revisor;
- auditor de testes;
- guardião de arquitetura;
- guardião de documentação;
- segurança;
- release manager;
- toolsmith/harness engineer.

O Plano de Agentes decide **quem pensa, quem executa, quem critica e quem preserva a memória**.

## 4.4 Plano de Ferramentas

Responsável por fornecer capacidades operacionais.

Inclui:

- Claude Code;
- Codex CLI;
- OpenAI Agents SDK;
- Claude Managed Agents;
- MCP;
- skills;
- hooks;
- shell;
- apply patch;
- sandboxes;
- worktrees;
- CI;
- browser/computer use quando permitido;
- ferramentas internas do projeto.

O Plano de Ferramentas decide **como o agente atua no mundo**.

## 4.5 Plano de Evidência

Responsável por registrar o que aconteceu.

Inclui:

```text
artifacts/<ticket>/run-XX/STATUS.md
artifacts/<ticket>/run-XX/FILES_CHANGED.md
artifacts/<ticket>/run-XX/VALIDATION.md
artifacts/<ticket>/run-XX/RISKS.md
artifacts/<ticket>/run-XX/HANDOFF.md
reports/
traces/
logs/
```

O Plano de Evidência decide **como o humano confia no trabalho feito**.

## 4.6 Plano de Governança

Responsável por impedir que autonomia vire risco.

Inclui:

- sandbox;
- allowlist/denylist;
- políticas de permissão;
- hooks de bloqueio;
- validações obrigatórias;
- proteção de secrets;
- aprovações humanas;
- separação entre harness e compute;
- políticas para MCPs externos.

O Plano de Governança decide **o que o agente não pode violar**.

## 4.7 Plano de Evolução

Responsável por manter o ARTEMIS vivo conforme as ferramentas mudam.

Inclui:

- revisão periódica de changelogs;
- registro de capacidades;
- testes de novos recursos;
- depreciação de práticas antigas;
- atualização dos templates;
- criação de novas skills;
- ajuste de agentes.

O Plano de Evolução decide **como o processo melhora sem quebrar sua estabilidade**.

---

## 5. Topologia padrão de agentes

A arquitetura universal do ARTEMIS tem um núcleo fixo e agentes opcionais.

## 5.1 Núcleo fixo

### 1. Humano Arquiteto

**Tipo:** humano.  
**Função:** governo, julgamento, arquitetura, prioridade, aprovação.  
**Não faz:** microgerenciamento de implementação comum.

Responsável por:

- definir direção;
- aprovar decisões estruturais;
- estabelecer limites;
- priorizar backlog;
- decidir riscos;
- aprovar merge.

### 2. ARTEMIS Orchestrator

**Tipo:** IA ou automação.  
**Função:** coordenar o fluxo, não necessariamente implementar.  
**Ferramenta sugerida:** Codex, Claude Code ou um harness com OpenAI Agents SDK.

Responsável por:

- receber objetivo do humano;
- escolher modo de execução;
- acionar preparador, executor e revisor;
- garantir que artifacts sejam produzidos;
- apontar pontos de escalonamento;
- manter o ticket dentro do processo.

### 3. Context Curator

**Tipo:** IA preparadora.  
**Função:** montar o Context Pack.

Responsável por:

- ler a tarefa;
- localizar arquivos e documentos relevantes;
- reduzir ruído;
- listar hipóteses;
- identificar invariantes;
- gerar prompt do executor;
- gerar prompt do revisor.

### 4. Planner

**Tipo:** IA planejadora.  
**Função:** decompor execução em passos seguros.

Responsável por:

- dividir a tarefa;
- identificar dependências;
- estimar risco;
- propor ordem de implementação;
- separar investigação de alteração.

Em tarefas simples, o Planner pode ser incorporado ao Executor.

### 5. Implementer

**Tipo:** IA executora.  
**Função:** alterar código, testes e docs.

Ferramentas preferenciais:

- Claude Code para trabalho exploratório no terminal, refactors e implementação guiada;
- Codex CLI para implementação, revisão local, automações e tarefas scriptáveis;
- OpenAI Agents SDK quando a implementação fizer parte de um pipeline próprio de agentes.

Responsável por:

- implementar dentro do escopo;
- rodar validação;
- registrar evidência;
- parar quando encontrar risco fora do contrato.

### 6. Reviewer

**Tipo:** IA crítica.  
**Função:** revisar mudança contra o contrato.

Responsável por:

- comparar diff com Context Pack;
- encontrar drift de escopo;
- encontrar violação arquitetural;
- revisar testes;
- revisar risco;
- sugerir merge, retrabalho ou escalonamento.

### 7. Memory Keeper

**Tipo:** IA documental.  
**Função:** preservar aprendizado útil.

Responsável por:

- transformar descobertas em docs curtas;
- atualizar handoffs;
- registrar decisões;
- sugerir ADRs;
- detectar documentação vencida;
- evitar que `AGENTS.md` e `CLAUDE.md` virem enciclopédias.

---

## 5.2 Agentes opcionais especializados

Use somente quando o projeto justificar.

### Architecture Steward

Revisa fronteiras, dependências e decisões estruturais.

Usar quando:

- muda módulo central;
- toca contrato público;
- cria novo padrão;
- altera domínio principal;
- introduz nova dependência.

### Test & Eval Auditor

Revisa cobertura, testes, fixtures, regressões e critérios objetivos.

Usar quando:

- a mudança altera comportamento;
- há risco de regressão;
- testes são frágeis;
- existe lógica crítica.

### Security & Permissions Reviewer

Revisa secrets, auth, permissões, inputs externos, dados sensíveis e comandos perigosos.

Usar quando:

- toca autenticação;
- toca autorização;
- toca dados sensíveis;
- toca deploy;
- usa MCPs com ações externas;
- executa shell com efeitos relevantes.

### Data & Migration Reviewer

Revisa schema, migrações, rollback, compatibilidade e integridade de dados.

Usar quando:

- cria tabela;
- altera schema;
- muda contrato de dados;
- remove campo;
- altera pipeline.

### Docs Keeper

Atualiza documentação mínima e evita drift.

Usar quando:

- muda arquitetura;
- muda comando;
- muda fluxo operacional;
- muda comportamento público;
- termina tarefa longa.

### Release Manager

Prepara changelog, release notes, checklist, risco residual e plano de rollback.

Usar quando:

- a mudança será publicada;
- há deploy;
- há migração;
- há alteração de contrato;
- há impacto em usuário.

### Toolsmith / Harness Engineer

Cria ou ajusta tools, skills, MCPs, hooks, scripts e guardrails.

Usar quando:

- o agente repete tarefa manual;
- uma validação deveria ser automática;
- uma política precisa virar hook;
- um workflow deve virar skill;
- Codex/Claude precisam de ferramenta mais clara.

### Researcher

Pesquisa docs, changelogs, issues, padrões externos e referências.

Usar quando:

- a ferramenta mudou;
- a API é nova;
- a decisão depende de informação recente;
- há dúvida sobre recurso atual.

---

## 6. Níveis de maturidade da arquitetura de agentes

## Nível 0 — Execução simples

Um agente executa e entrega evidências.

Use para:

- correções pequenas;
- docs simples;
- scripts locais;
- tarefas de baixo risco.

## Nível 1 — Preparar, executar, revisar

Fluxo mínimo recomendado para projeto sério.

Agentes:

- Context Curator;
- Implementer;
- Reviewer.

Use para:

- features comuns;
- refactors localizados;
- bugs importantes;
- tarefas com testes.

## Nível 2 — Subagentes especializados

Um agente principal usa subagentes para tarefas ruidosas ou paralelizáveis.

Use para:

- exploração de código grande;
- investigação de regressão;
- análise de múltiplos módulos;
- revisão de segurança;
- documentação grande.

## Nível 3 — Multi-worktree coordenado

Vários worktrees isolados executam frentes independentes.

Use para:

- migração ampla;
- decomposição de épico;
- comparação de abordagens;
- protótipos concorrentes;
- investigação paralela.

Regra: cada worktree tem um escritor principal.

## Nível 4 — Harness programável

OpenAI Agents SDK, Claude Managed Agents ou outro runtime orquestram agentes como parte do produto ou pipeline.

Use para:

- agentes em produção;
- pipelines internos de engenharia;
- workflows determinísticos com tracing;
- revisão automática em CI;
- execução durável e auditável.

---

## 7. Padrões agentic recomendados

O ARTEMIS combina padrões simples e verificáveis.

## 7.1 Prompt chaining

Use quando a tarefa pode ser quebrada em etapas fixas.

Exemplo:

1. resumir diff;
2. classificar risco;
3. gerar checklist;
4. gerar revisão final.

## 7.2 Routing

Use quando há diferentes tipos de tarefa e cada uma pede agente/ferramenta diferente.

Exemplo:

- bug de backend → Implementer + Test Auditor;
- alteração de schema → Data Reviewer;
- atualização de docs → Docs Keeper;
- possível vulnerabilidade → Security Reviewer.

## 7.3 Parallelization

Use quando subtarefas independentes podem rodar juntas.

Exemplo:

- um subagente lê testes;
- outro lê implementação;
- outro lê docs;
- o orquestrador consolida.

## 7.4 Orchestrator-workers

Use quando o número de subtarefas não é conhecido antes da investigação.

Exemplo:

- migrar um módulo legado;
- investigar falha complexa;
- implementar feature que toca múltiplas camadas.

## 7.5 Evaluator-optimizer

Use quando melhoria iterativa traz ganho real.

Exemplo:

- melhorar arquitetura proposta;
- refinar testes;
- revisar prompt de um agente;
- lapidar documentação técnica;
- corrigir uma solução após feedback do revisor.

## 7.6 Autonomous agent com checkpoints

Use somente quando:

- há sandbox;
- há critérios claros;
- há limite de iterações;
- há logs/evidências;
- há ponto de parada;
- há revisão humana para ações de alto impacto.

---

## 8. Matriz de escolha de ferramenta

## 8.1 Claude Code

Use preferencialmente quando:

- o trabalho é exploratório;
- o agente precisa entender o repositório pelo terminal;
- há muito ajuste incremental;
- subagentes, hooks e skills ajudam no fluxo;
- você quer interação contínua no terminal;
- há necessidade de refactor com feedback humano próximo.

Recursos a explorar:

- `CLAUDE.md` curto;
- `/init` para bootstrap;
- subagentes em `.claude/agents/`;
- hooks para ações determinísticas;
- skills para workflows repetíveis;
- permissões por projeto;
- compactação e retomada de sessão;
- MCPs para sistemas externos.

## 8.2 Codex CLI

Use preferencialmente quando:

- o trabalho precisa ser automatizado;
- a tarefa cabe em `codex exec`;
- há necessidade de revisão local;
- há subagentes paralelos;
- a tarefa deve entrar em CI ou script;
- o projeto usa `AGENTS.md`, skills, MCP e config por projeto.

Recursos a explorar:

- `AGENTS.md` e instruções por escopo;
- `.codex/config.toml`;
- approval modes;
- sandbox;
- MCP;
- skills;
- subagents;
- `/review`;
- `codex exec`;
- web search quando permitido.

## 8.3 OpenAI Agents SDK

Use preferencialmente quando:

- você quer criar um harness programável;
- precisa de agentes com tools, guardrails, sessões, tracing e handoffs;
- deseja orquestrar Codex CLI como MCP;
- precisa de sandbox, Manifest, memória, compaction e execução durável;
- quer transformar o processo ARTEMIS em pipeline interno de engenharia.

## 8.4 Claude Managed Agents / Claude Platform

Use preferencialmente quando:

- o agente vai virar recurso de produto ou operação gerenciada;
- você quer usar ferramentas da plataforma Claude;
- precisa combinar files, skills, MCP, prompt caching, context management, evaluations e guardrails;
- o caso envolve colaboração, uso empresarial ou agente com interface fora do terminal.

## 8.5 MCP

Use quando a IA precisa acessar sistemas externos ao repositório.

Exemplos:

- GitHub;
- Linear/Jira;
- Figma;
- docs internas;
- bancos somente leitura;
- observabilidade;
- browser;
- sistemas internos.

Regra:

> MCP com leitura é contexto. MCP com escrita é capacidade operacional e precisa de política de risco.

## 8.6 Skills

Use quando um procedimento se repete.

Exemplos:

- revisar arquitetura;
- gerar release notes;
- validar Context Pack;
- migrar módulo;
- revisar segurança;
- preparar handoff;
- atualizar documentação.

Regra:

> Se você colou o mesmo prompt três vezes, transforme em skill.

## 8.7 Hooks

Use quando uma regra deve acontecer sempre.

Exemplos:

- formatar após edição;
- bloquear comando destrutivo;
- registrar tool calls;
- impedir alteração em arquivos protegidos;
- exigir artifact;
- rodar validação alvo;
- notificar quando o agente espera input.

Regra:

> O que é determinístico deve virar hook, não pedido educado no prompt.

---

## 9. Estrutura de arquivos recomendada

Dentro do repositório:

```text
repo/
├── AGENTS.md
├── CLAUDE.md
├── ARCHITECTURE.md
├── AI_PROCESS.md
├── docs/
│   ├── agents/
│   │   ├── ARTEMIS_AGENT_ARCHITECTURE.md
│   │   ├── AGENT_REGISTRY.md
│   │   ├── CAPABILITY_REGISTRY.md
│   │   ├── TOOL_POLICY.md
│   │   ├── HANDOFF_PROTOCOL.md
│   │   └── cards/
│   │       ├── context-curator.md
│   │       ├── implementer.md
│   │       ├── reviewer.md
│   │       ├── architecture-steward.md
│   │       ├── test-auditor.md
│   │       ├── security-reviewer.md
│   │       └── memory-keeper.md
│   ├── decisions/
│   ├── invariants/
│   ├── exec-packs/
│   ├── quality/
│   └── runbooks/
├── .claude/
│   ├── agents/
│   ├── skills/
│   ├── hooks/
│   └── settings.json
├── .codex/
│   ├── config.toml
│   ├── agents/
│   └── skills/
├── ops/
│   ├── hooks/
│   ├── scripts/
│   ├── policies/
│   └── state/
└── artifacts/
```

Fora do repositório, na VPS:

```text
/srv/ai-factory/
├── control/
│   ├── templates/
│   ├── policies/
│   ├── prompts/
│   ├── scripts/
│   └── state/
├── projects/
├── logs/
├── backups/
└── sandboxes/
```

---

## 10. Ficha padrão de agente

Cada agente deve ser documentado com este modelo.

```md
# Agent Card — <nome-do-agente>

## Missão
O que este agente faz.

## Quando usar
Situações em que deve ser acionado.

## Quando não usar
Situações em que o agente tende a gerar ruído ou risco.

## Ferramenta preferencial
Claude Code, Codex, OpenAI Agents SDK, Claude Managed Agents ou outro runtime.

## Modelo preferencial
Modelo recomendado, se aplicável.

## Permissões
- leitura:
- escrita:
- shell:
- rede:
- MCP:
- aprovação humana:

## Entradas obrigatórias
- Context Pack:
- arquivos:
- comandos:
- critérios de aceite:

## Saídas obrigatórias
- resumo:
- arquivos analisados/alterados:
- validação:
- riscos:
- handoff:

## Ferramentas permitidas
Lista de tools, MCPs, scripts ou comandos.

## Ferramentas proibidas
Lista de ações bloqueadas.

## Handoffs permitidos
Para quais agentes pode transferir trabalho.

## Critérios de parada
Quando deve encerrar ou escalar.

## Falhas comuns
O que este agente costuma errar.

## Checklist final
- [ ] respeitou escopo
- [ ] respeitou invariantes
- [ ] produziu evidência
- [ ] sinalizou risco
```

---

## 11. Registro de capacidades das ferramentas

Como Claude Code, Codex e SDKs mudam rapidamente, o ARTEMIS deve manter um registro de capacidades.

Arquivo sugerido:

```text
docs/agents/CAPABILITY_REGISTRY.md
```

Modelo:

```md
# Capability Registry

## Claude Code

| Capacidade | Status | Onde usar | Risco | Última verificação |
|---|---|---|---|---|
| Subagentes | ativo | pesquisa, revisão, tarefas isoladas | custo/contexto | 2026-04-24 |
| Hooks | ativo | bloqueios, logs, validação | falso positivo | 2026-04-24 |
| Skills | ativo | workflows repetíveis | skill desatualizada | 2026-04-24 |
| MCP | ativo | ferramentas externas | exfiltração/escrita | 2026-04-24 |

## Codex

| Capacidade | Status | Onde usar | Risco | Última verificação |
|---|---|---|---|---|
| CLI | ativo | VPS Linux, terminal | permissões | 2026-04-24 |
| `codex exec` | ativo | automações e CI | execução não supervisionada | 2026-04-24 |
| Subagents | ativo | paralelismo explícito | custo/coordenação | 2026-04-24 |
| MCP | ativo | ferramentas externas | escopo de permissão | 2026-04-24 |
| Skills | ativo | workflows repetíveis | drift | 2026-04-24 |

## OpenAI Agents SDK

| Capacidade | Status | Onde usar | Risco | Última verificação |
|---|---|---|---|---|
| Agents | ativo | harness programável | abstração excessiva | 2026-04-24 |
| Handoffs | ativo | especialização de agentes | handoff ruim | 2026-04-24 |
| Guardrails | ativo | bloqueios e validações | cobertura incompleta | 2026-04-24 |
| Sessions | ativo | memória multi-turn | contexto velho | 2026-04-24 |
| Tracing | ativo | observabilidade | dados sensíveis | 2026-04-24 |
| Sandbox/Manifest | ativo | execução controlada | má configuração | 2026-04-24 |

## Claude Platform / Managed Agents

| Capacidade | Status | Onde usar | Risco | Última verificação |
|---|---|---|---|---|
| Managed agents | ativo | agentes de produto/operação | acoplamento | 2026-04-24 |
| Files | ativo | contexto documental | docs obsoletos | 2026-04-24 |
| Skills | ativo | workflows | drift | 2026-04-24 |
| MCP | ativo | sistemas externos | permissões | 2026-04-24 |
| Evals/guardrails | ativo | qualidade e segurança | métrica ruim | 2026-04-24 |
```

Regra:

> Sempre que um changelog alterar capacidades relevantes, atualize o registry antes de alterar o processo.

---

## 12. Política de atualização contínua

## 12.1 Cadência

- **Semanal:** verificar changelogs se o projeto está em fase intensa.
- **Mensal:** revisar Capability Registry.
- **Por release importante:** atualizar agentes, skills, hooks e templates afetados.
- **Por incidente:** transformar falha em invariant, hook, skill ou teste.

## 12.2 Ordem correta de adoção de novo recurso

1. Ler documentação oficial.
2. Registrar no Capability Registry.
3. Testar em tarefa pequena.
4. Documentar ganho e risco.
5. Criar ou atualizar skill/hook/agente.
6. Usar em projeto real.
7. Revisar após 3 execuções.

## 12.3 Critérios para incorporar recurso ao núcleo

Um recurso só entra no núcleo ARTEMIS se:

- reduziu risco;
- reduziu ruído;
- aumentou rastreabilidade;
- acelerou sem perda de controle;
- funciona em mais de um projeto;
- pode ser documentado e auditado.

---

## 13. Padrão de handoff entre agentes

```md
# Agent Handoff — <ticket>

## De
Agente remetente.

## Para
Agente destinatário.

## Objetivo do handoff
Por que este trabalho está sendo transferido.

## Estado atual
O que já foi feito.

## Contexto mínimo
Arquivos, decisões e restrições relevantes.

## Evidências produzidas
Links ou caminhos de artifacts.

## Riscos conhecidos
Lista objetiva.

## Próxima ação esperada
O que o próximo agente deve fazer.

## Critérios de parada
Quando parar e escalar.
```

---

## 14. Prompt mestre para criar a arquitetura de agentes de um projeto

Use este prompt com Claude Code ou Codex no início de cada novo projeto.

```text
Você está operando dentro do processo ARTEMIS.

Sua tarefa é criar a arquitetura de agentes deste projeto, seguindo o documento docs/agents/ARTEMIS_AGENT_ARCHITECTURE.md.

Não implemente features do produto.
Não crie uma arquitetura multiagente exagerada.
Comece simples e escale apenas onde houver ganho claro.

Leia primeiro:
- AGENTS.md, se existir
- CLAUDE.md, se existir
- ARCHITECTURE.md, se existir
- AI_PROCESS.md ou fluxo ARTEMIS
- docs/agents/ARTEMIS_AGENT_ARCHITECTURE.md
- docs/invariants/, se existir

Entregue:
1. docs/agents/AGENT_REGISTRY.md
2. docs/agents/CAPABILITY_REGISTRY.md
3. docs/agents/TOOL_POLICY.md
4. docs/agents/HANDOFF_PROTOCOL.md
5. cards dos agentes mínimos em docs/agents/cards/
6. recomendações para .claude/agents/, .claude/skills/, .codex/agents/ e .codex/skills/
7. lista do que NÃO deve ser automatizado ainda
8. checklist de implantação em 7 dias

Critérios:
- priorize núcleo mínimo: Context Curator, Implementer, Reviewer e Memory Keeper;
- proponha agentes opcionais apenas se o projeto justificar;
- mapeie quais papéis devem rodar em Claude Code, Codex, SDK ou Managed Agents;
- defina permissões e zonas protegidas;
- defina artifacts obrigatórios;
- inclua política de atualização contínua das ferramentas;
- produza arquivos claros, curtos e fáceis de manter.

No final, entregue um resumo executivo e os próximos comandos sugeridos.
```

---

## 15. Política de segurança e risco

## 15.1 Zonas protegidas

Por padrão, exigem aprovação humana:

- produção;
- banco real;
- secrets;
- deploy;
- billing;
- auth;
- permissões;
- migrações destrutivas;
- contratos públicos;
- infraestrutura compartilhada;
- integrações externas com escrita.

## 15.2 Permissões por estágio

### Planejamento

Permitido:

- leitura;
- busca;
- análise;
- criação de plano.

Proibido:

- escrita em código;
- shell destrutivo;
- deploy;
- alteração de dependências.

### Execução local

Permitido:

- editar arquivos no escopo;
- rodar testes locais;
- criar docs e artifacts;
- usar shell seguro.

Requer aprovação:

- nova dependência;
- mudança em infra;
- migração;
- comando destrutivo.

### Revisão

Preferencialmente read-only.

Permitido:

- ler diff;
- rodar testes;
- gerar relatório;
- sugerir patch.

Proibido:

- alterar implementação sem novo ciclo.

### Produção

Ações de produção devem ser humanas ou automatizadas por pipeline confiável com aprovação.

---

## 16. Como aplicar em qualquer projeto

## 16.1 Projeto pequeno

Use apenas:

- Implementer;
- Reviewer;
- Memory Keeper leve.

Sem subagentes complexos.

## 16.2 Produto web/API

Adicionar:

- Architecture Steward;
- Test Auditor;
- Security Reviewer;
- Release Manager.

## 16.3 Projeto com dados ou ETL

Adicionar:

- Data & Migration Reviewer;
- Observability Reviewer;
- Regression Hunter.

## 16.4 Projeto enterprise/interno

Adicionar:

- Security Reviewer;
- Compliance Reviewer;
- Toolsmith;
- Docs Keeper;
- Release Manager.

## 16.5 Projeto com agentes em produção

Adicionar:

- Harness Engineer;
- Eval Designer;
- Guardrail Engineer;
- Trace Analyst;
- Incident Reviewer.

---

## 17. Critérios de saúde da arquitetura

Uma arquitetura de agentes saudável tem:

- poucos agentes obrigatórios;
- papéis claros;
- handoffs curtos;
- ferramentas bem documentadas;
- permissões explícitas;
- artifacts consistentes;
- baixa repetição de prompts;
- hooks para regras determinísticas;
- skills para workflows recorrentes;
- métricas de qualidade;
- atualização periódica.

Sinais de deterioração:

- muitos agentes sem função clara;
- handoffs longos demais;
- prompts enormes;
- agentes alterando escopo;
- `AGENTS.md` ou `CLAUDE.md` virando depósito;
- ausência de evidência;
- revisores que só “elogiam”; 
- falhas repetidas que não viram teste, hook ou invariant;
- subagentes usados para tudo.

---

## 18. Métricas mínimas

Registre por ticket:

- tempo de ciclo;
- número de arquivos alterados;
- número de execuções/retries;
- comandos de validação;
- falhas encontradas pelo revisor;
- falhas encontradas pelo humano;
- violações de escopo;
- documentação atualizada ou não;
- rollback necessário ou não.

Registre por mês:

- tarefas concluídas;
- tarefas retrabalhadas;
- causas de retrabalho;
- agentes/skills mais úteis;
- hooks que bloquearam risco real;
- prompts repetidos que devem virar skill;
- docs que ficaram obsoletas.

---

## 19. Referências oficiais usadas como base

- OpenAI — The next evolution of the Agents SDK: https://openai.com/pt-BR/index/the-next-evolution-of-the-agents-sdk/
- OpenAI Agents SDK: https://openai.github.io/openai-agents-python/
- OpenAI Developers: https://developers.openai.com/
- OpenAI Cookbook: https://developers.openai.com/cookbook
- OpenAI — Speeding up agentic workflows with WebSockets: https://openai.com/index/speeding-up-agentic-workflows-with-websockets/
- Codex CLI: https://developers.openai.com/codex/cli
- Codex Subagents: https://developers.openai.com/codex/subagents
- Codex Customization: https://developers.openai.com/codex/concepts/customization
- Codex with Agents SDK: https://developers.openai.com/codex/guides/agents-sdk
- Claude Managed Agents overview: https://platform.claude.com/docs/en/managed-agents/overview
- Claude Code Subagents: https://code.claude.com/docs/en/sub-agents
- Claude Code Hooks: https://code.claude.com/docs/en/hooks-guide
- Anthropic — Building Effective Agents: https://www.anthropic.com/engineering/building-effective-agents
- Claude use cases / agents: https://claude.com/solutions/agents

---

## 20. Resumo final

A arquitetura universal do ARTEMIS pode ser resumida assim:

> **O humano governa. O contexto prepara. O agente executa. O crítico revisa. As ferramentas ampliam. As evidências sustentam. A governança limita. A evolução atualiza.**

O ARTEMIS deve ser simples no início, rigoroso na estrutura e adaptável nas ferramentas.
