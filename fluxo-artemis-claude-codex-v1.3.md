
# Fluxo ARTEMIS
## Documento-base para trabalho agentic com Claude Code e Codex
**Nome do processo:** **ARTEMIS** — **Arquitetura, Ritmo, Trabalho Estruturado, Memória, Implementação e Supervisão**

**Versão:** 1.3  
**Status:** revisado com Arquitetura Universal de Agentes e Modelo Operacional GitHub  
**Contexto alvo:** VPS Linux, terminal-first, projetos médios e grandes, múltiplas sessões de IA, necessidade de rastreabilidade, consistência e escala.

---

## 1. Propósito

Este documento define um padrão operacional para trabalhar com **Claude Code** e **Codex** em um ambiente onde a IA executa a maior parte da implementação, enquanto o humano lidera:

- arquitetura;
- fronteiras do sistema;
- decisões estruturais;
- priorização;
- critérios de aceite;
- revisão final.

A ideia central deste padrão é simples:

> **a IA não improvisa o sistema; ela executa contratos operacionais claros dentro de uma arquitetura governada.**

Esse padrão existe para resolver quatro problemas recorrentes em projetos grandes com IA:

1. **mudanças demais ao mesmo tempo**;
2. **baixa visibilidade do que foi alterado e por quê**;
3. **perda de contexto entre sessões**;
4. **drift de arquitetura, documentação e workflow com o tempo**.

---

## 2. Tese central do processo

## 2.1 GitHub como plano de coordenação

A partir da versão 1.3, o ARTEMIS passa a tratar o GitHub como o **plano de coordenação** do processo.

O terminal e a VPS continuam sendo o lugar principal da execução profunda. O GitHub passa a organizar:

- issues;
- branches;
- worktrees vinculadas a tarefas;
- pull requests;
- revisões humanas;
- revisões por Codex e Claude;
- CI/CD;
- rulesets;
- CODEOWNERS;
- segurança de secrets;
- rastreabilidade em equipe.

Documento complementar obrigatório para projetos em GitHub:

```text
artemis-github-operating-model.md
```

Regra operacional:

> **Issue define intenção. Exec Pack define contrato. Branch isola execução. PR concentra evidência. Rulesets protegem o sistema. Revisão humana preserva arquitetura.**


O processo ARTEMIS parte de cinco pilares:

### A. Arquitetura vem antes de execução
A IA não deve “descobrir a arquitetura no caminho”.
Ela pode sugerir melhorias, mas executa melhor quando recebe uma arquitetura já organizada.

### B. Contexto é empacotado, não despejado
Em vez de enviar um prompt gigante e caótico, outra IA prepara um **Context Pack** curto, objetivo e verificável.

### C. Cada execução tem escopo fechado
Toda execução relevante precisa nascer com:
- objetivo;
- escopo;
- fora de escopo;
- riscos;
- invariantes;
- entregáveis;
- validação obrigatória.

### D. Um worktree por frente de trabalho
Mudanças paralelas pedem isolamento real.
Não misturar investigação, implementação, revisão e refactor grande no mesmo espaço de trabalho.

### E. Sustentação é parte do sistema
O processo só funciona no longo prazo se o workspace, os arquivos de contexto e as rotinas de manutenção forem tratados como produto.

---

## 3. Papéis do processo

## 3.1 Humano Arquiteto
Responsável por:
- definir a arquitetura;
- aprovar decisões estruturais;
- decidir limites, padrões e exceções;
- priorizar backlog;
- aprovar merge final;
- revisar riscos sistêmicos.

O humano não deve gastar energia com microimplementação que o agente pode executar com segurança.

## 3.2 IA Preparadora de Contexto
Responsável por:
- ler a solicitação do humano;
- identificar contexto relevante;
- reduzir ruído;
- montar um **Context Pack** consistente;
- gerar o prompt certo para o executor;
- gerar também o prompt do revisor.

Esse papel é crítico.  
A IA preparadora **não deve implementar** a tarefa principal.  
Ela deve **estruturar a execução**.

## 3.3 IA Executora
Responsável por:
- implementar a mudança;
- editar código, testes e docs no escopo definido;
- registrar evidências;
- parar e escalar quando o contrato exigir;
- não expandir escopo por iniciativa própria.

## 3.4 IA Revisora
Responsável por:
- revisar o diff;
- procurar violações de arquitetura;
- procurar regressões;
- apontar lacunas de validação;
- validar aderência ao pacote de execução.

## 3.5 Repositório
O repositório é a fonte de verdade.
Nada importante deve depender apenas de memória, chat antigo ou prompt informal.

---

## 4. Regras operacionais obrigatórias

1. **Uma mudança importante = um pacote formal de execução.**
2. **Um worktree = um fluxo principal de alteração.**
3. **Um agente escritor por worktree.**
4. **Toda mudança precisa de evidência.**
5. **Toda sessão longa precisa de resumo de handoff.**
6. **Arquitetura é protegida por arquivo, script, regra, hook e revisão.**
7. **Prompt nunca substitui política operacional.**
8. **Mudanças fora de escopo exigem novo pacote ou escalonamento.**
9. **Não misturar feature, refactor estrutural e higiene ampla no mesmo ticket sem justificativa explícita.**
10. **O workspace deve permanecer sustentável mesmo após dezenas de execuções.**

---

## 5. Estrutura recomendada de workspace

## 5.1 Na VPS

```text
/srv/ai-factory/
├── control/
│   ├── templates/
│   ├── policies/
│   ├── prompts/
│   ├── scripts/
│   └── state/
├── projects/
│   └── nome-do-projeto/
├── logs/
├── backups/
└── sandboxes/
```

## 5.2 Por projeto

```text
nome-do-projeto/
├── repo/
├── worktrees/
├── artifacts/
├── sessions/
├── cache/
├── tmp/
└── reports/
```

## 5.3 Dentro do repositório

```text
repo/
├── README.md
├── ARCHITECTURE.md
├── AGENTS.md
├── CLAUDE.md
├── AI_PROCESS.md
├── docs/
│   ├── decisions/
│   ├── invariants/
│   ├── exec-packs/
│   │   ├── backlog/
│   │   ├── active/
│   │   └── done/
│   ├── runbooks/
│   ├── quality/
│   └── product/
├── artifacts/
├── scripts/
├── .claude/
│   ├── settings.json
│   ├── skills/
│   ├── agents/
│   └── hooks/
├── .codex/
│   └── config.toml
├── codex/
│   └── rules/
└── src/
```

---

## 6. O que vai em cada arquivo principal

## 6.1 `AGENTS.md`
Arquivo curto.
Serve como mapa rápido do projeto para qualquer agente.

Deve conter:
- objetivo do projeto;
- mapa dos principais módulos;
- comandos canônicos;
- padrões de branch/worktree;
- arquivos que devem ser lidos antes de mudar código;
- critérios de escalonamento;
- caminho dos exec packs e artifacts.

## 6.2 `CLAUDE.md`
Arquivo persistente de instruções gerais do Claude Code.
Deve ser curto, estável e prático.

Coloque aqui:
- regras de workflow;
- comandos importantes;
- convenções que Claude não deduz sozinho;
- gotchas reais;
- padrões arquiteturais que causam erro quando ignorados.

Não use `CLAUDE.md` como enciclopédia.

## 6.3 `ARCHITECTURE.md`
Mapa de domínios, dependências, fronteiras, eventos, contratos e decisões estáveis.

## 6.4 `docs/invariants/`
Regras duras, por exemplo:
- dependências proibidas entre camadas;
- regras de schema;
- padrões de logging;
- restrições de acesso a dados;
- contratos públicos;
- convenções de teste.

## 6.5 `docs/decisions/`
ADRs curtas e frequentes.

## 6.6 `docs/exec-packs/`
Pacotes de execução por ticket.

## 6.7 `artifacts/`
Evidências produzidas por sessão:
- status;
- arquivos alterados;
- resumo de validação;
- riscos;
- handoff;
- links de revisão.

---

## 7. Como usar Claude Code e Codex dentro do processo

## 7.1 Claude Code no ARTEMIS
Use Claude Code como executor altamente adaptável dentro do repositório.

Padrão recomendado:
- `CLAUDE.md` curto e disciplinado;
- `.claude/skills/` para procedimentos recorrentes;
- `.claude/agents/` para subagentes especializados;
- hooks para garantir validações e bloqueios determinísticos;
- permissões configuradas por projeto;
- worktree isolado para tarefas relevantes.

Papéis ideais para Claude Code:
- implementação principal;
- exploração técnica;
- refactors localizados;
- geração e atualização de documentação operacional;
- manutenção guiada por hooks e regras.

## 7.2 Codex no ARTEMIS
Use Codex como executor, revisor técnico ou operador de automações programáveis.

Padrão recomendado:
- `.codex/config.toml` com política de sandbox, aprovação e confiança;
- `codex/rules/` para comandos fora do sandbox;
- skills reutilizáveis para workflows;
- subagentes para tarefas altamente paralelizáveis;
- `codex exec` para pipelines, jobs repetíveis e revisões não interativas.

Papéis ideais para Codex:
- revisão local antes de commit;
- execução em scripts/CI;
- automações repetitivas;
- exploração paralela com subagentes;
- tarefas longas e claramente empacotadas.

## 7.3 Regra de convivência Claude + Codex
- Não deixe ambos editarem o mesmo worktree ao mesmo tempo.
- Pode usar Claude para implementar e Codex para revisar.
- Pode usar Codex para preparar patches automatizados e Claude para consolidar.
- Pode usar Claude para exploração e Codex para execução em pipeline.
- Em tickets críticos, use um como executor e o outro como crítico.

---

## 8. Melhorias de processo com recursos atuais

## 8.1 Melhorias a adotar já no Claude Code
1. **`/init` no início do projeto** para gerar uma primeira base do `CLAUDE.md`.
2. **Subagentes em `.claude/agents/`** para:
   - revisor de arquitetura;
   - auditor de testes;
   - guardião de documentação;
   - verificador de segurança;
   - compilador de handoff.
3. **Hooks obrigatórios** para:
   - rodar lint/teste alvo;
   - bloquear escrita em diretórios protegidos;
   - exigir atualização de artifact;
   - registrar resumo quando subagente encerrar.
4. **Modo de permissões adequado por estágio**:
   - planejamento;
   - edição com confirmação;
   - maior autonomia apenas em ambiente isolado.
5. **Sessões em worktree** para reduzir colisão entre tarefas.
6. **Remote Control** como camada opcional de observação e continuidade sem mover a execução para fora da VPS.
7. **Channels** como extensão futura para empurrar CI, alertas e eventos para uma sessão viva.

## 8.2 Melhorias a adotar já no Codex
1. **CLI como base na VPS Linux**.
2. **`codex exec`** para jobs repetíveis:
   - triagem;
   - release notes;
   - revisão automatizada;
   - checagens pré-merge;
   - relatórios.
3. **Subagentes** para exploração e divisão de tarefas paralelas.
4. **Skills** para checklists e playbooks reutilizáveis.
5. **MCP** para documentação, issue tracker, design tools e conhecimento externo ao repo.
6. **`/review`** antes de commit/push em mudanças sensíveis.
7. **Regras em `codex/rules/`** para controlar comandos fora do sandbox.
8. **Configuração por projeto em `.codex/config.toml`** para confiar, limitar e padronizar o ambiente.
9. **App/Cloud como camada opcional de supervisão**:
   - worktrees visuais;
   - automations;
   - browser/computer use;
   - revisão mais rica;
   - handoff entre local e worktree.

## 8.3 O que não entra na versão 1
- multiagente amplo sem isolamento;
- autonomia total sem políticas;
- prompts gigantes substituindo arquivos;
- paralelismo agressivo sem naming, worktree e artifacts;
- agent teams experimentais como núcleo do processo.

---

## 9. O pacote formal de execução: Context Pack

A IA preparadora deve sempre gerar um **Context Pack** antes da execução.

## 9.1 Estrutura mínima do Context Pack

**Arquivo sugerido:** `docs/exec-packs/active/TKT-###-slug.md`

```md
# TKT-142 - Nome da tarefa

## Objetivo
O que precisa ser entregue.

## Resultado esperado
Como deve ficar quando estiver pronto.

## Contexto mínimo
Quais documentos e arquivos precisam ser lidos primeiro.

## Escopo
Arquivos, módulos e fronteiras que podem ser alterados.

## Fora de escopo
O que não deve ser tocado nesta execução.

## Invariantes
Regras que não podem ser violadas.

## Restrições operacionais
Ex.: sem novas dependências; sem mudar contrato público; sem migração destrutiva.

## Comandos de validação
Quais comandos precisam rodar ao final.

## Evidências obrigatórias
Lista do que precisa ser entregue junto.

## Escalonar para humano se
Situações que obrigam parar e perguntar.

## Entregáveis
Código, testes, docs, migration note, changelog etc.
```

## 9.2 Contexto anexado
A IA preparadora também deve apontar:

- arquivos-fonte prioritários;
- ADRs relevantes;
- invariantes aplicáveis;
- comandos úteis;
- branches relacionadas;
- tickets dependentes;
- riscos já conhecidos.

---

## 10. Prompt da IA Preparadora de Contexto

**Uso:** enviar para a IA que vai montar o pacote antes do executor principal.

```text
Você é a IA Preparadora de Contexto do processo ARTEMIS.

Seu trabalho não é implementar a tarefa principal.
Seu trabalho é preparar um pacote de execução claro, curto, verificável e seguro para Claude Code ou Codex executar depois.

Objetivo:
1. entender a solicitação do humano;
2. identificar o contexto mínimo necessário;
3. reduzir ruído e ambiguidade;
4. montar um Context Pack completo;
5. produzir um prompt do executor;
6. produzir um prompt do revisor;
7. listar riscos, invariantes e critérios de aceite;
8. delimitar estritamente o que está dentro e fora do escopo.

Regras:
- não implemente a solução principal;
- não expanda o escopo sem justificativa explícita;
- não despeje documentação demais;
- priorize arquivos e referências realmente úteis;
- se algo for incerto, sinalize como hipótese;
- sempre separar: contexto, escopo, fora de escopo, invariantes, validação e evidências;
- a saída deve ser pronta para uso em terminal-first workflow.

Entregue no seguinte formato:
A. Resumo executivo da tarefa
B. Context Pack completo
C. Prompt do executor
D. Prompt do revisor
E. Riscos e pontos de escalonamento
F. Checklist final do humano antes de rodar
```

---

## 11. Prompt do Executor (Claude Code ou Codex)

**Uso:** prompt principal enviado ao executor dentro do worktree correto.

```text
Você está operando dentro do processo ARTEMIS.

Leia primeiro:
- AGENTS.md
- ARCHITECTURE.md
- o Context Pack desta tarefa
- quaisquer invariantes e ADRs citados no pacote

Seu papel nesta sessão:
- implementar somente o que está no escopo;
- preservar arquitetura e invariantes;
- evitar mudanças laterais não pedidas;
- registrar evidências;
- parar e escalar se encontrar critérios de parada.

Modo de trabalho:
1. confirme o entendimento da tarefa em até 10 linhas;
2. apresente um plano curto de execução;
3. execute por etapas pequenas e rastreáveis;
4. mantenha a mudança concentrada;
5. rode apenas a validação necessária para esta tarefa;
6. entregue evidências no final.

Você NÃO deve:
- reescrever áreas amplas fora do escopo;
- introduzir dependências novas sem necessidade clara;
- alterar contratos públicos sem sinalizar;
- tocar diretórios protegidos sem justificativa;
- misturar refactor estrutural com feature sem registrar isso.

No final, entregue:
A. resumo do que foi feito
B. arquivos alterados
C. testes/comandos executados
D. riscos remanescentes
E. pontos para revisão humana
F. sugestão de próximos passos estritamente relacionada à tarefa
```

---

## 12. Prompt do Revisor

```text
Você é o revisor técnico do processo ARTEMIS.

Revise esta mudança com base em:
- Context Pack
- arquitetura
- invariantes
- diff/resultados
- evidências entregues pelo executor

Seu objetivo é identificar:
1. violações arquiteturais;
2. drift de escopo;
3. regressões prováveis;
4. lacunas de teste/validação;
5. documentação faltante;
6. riscos operacionais não tratados.

Entregue:
A. veredito geral
B. problemas críticos
C. problemas moderados
D. observações menores
E. recomendações para merge ou retrabalho
F. se a tarefa pode seguir ou se deve voltar ao executor
```

---

## 13. Ciclo oficial do processo

## Etapa 1 — Definição humana
O humano define:
- objetivo;
- prioridade;
- arquitetura aplicável;
- risco;
- critério de pronto.

## Etapa 2 — Preparação
A IA preparadora:
- cria o Context Pack;
- cria o prompt do executor;
- cria o prompt do revisor.

## Etapa 3 — Setup operacional
Criar:
- branch;
- worktree;
- artifact da rodada;
- registro da sessão.

Convenção sugerida:
- branch: `ai/<agente>/<ticket>-<slug>`
- worktree: `worktrees/<ticket>--<agente>`

## Etapa 4 — Execução
O executor trabalha apenas com o pacote ativo e os arquivos referenciados.

## Etapa 5 — Evidência
Salvar em `artifacts/<ticket>/run-01/`:
- `STATUS.md`
- `FILES_CHANGED.md`
- `VALIDATION.md`
- `RISKS.md`
- `HANDOFF.md`

## Etapa 6 — Revisão
Rodar um segundo agente ou sessão para crítica.

## Etapa 7 — Revisão humana
O humano avalia:
- escopo;
- aderência à arquitetura;
- evidência;
- impacto;
- risco residual.

## Etapa 8 — Consolidação
Após merge:
- mover o exec pack para `done/`;
- registrar decisão;
- atualizar documentação se necessário;
- destruir o worktree encerrado.

---

## 14. Guardrails práticos

1. **Diretórios protegidos**
   - migrations destrutivas;
   - infra compartilhada;
   - configs globais;
   - credenciais e secrets;
   - contratos públicos.

2. **Sem escopo implícito**
   - se o agente precisar tocar mais coisa do que o pacote previa, deve registrar e escalar.

3. **Sem branch longa demais**
   - tickets grandes devem ser quebrados em pacotes menores.

4. **Sem sessão eterna**
   - toda sessão longa termina com compactação e handoff.

5. **Sem contexto monolítico**
   - procedimento vira skill;
   - regra vira invariant;
   - política vira config/hook;
   - memória útil vira documento curto.

---

## 15. Skills e agentes recomendados

## Claude Code
### Skills
- `fix-issue`
- `update-docs`
- `release-notes`
- `check-architecture`
- `handoff-writer`

### Subagentes
- `arch-reviewer`
- `test-auditor`
- `security-reviewer`
- `docs-keeper`
- `log-researcher`

## Codex
### Skills
- `triage-task`
- `run-local-review`
- `prepare-changelog`
- `validate-context-pack`
- `summarize-diff`

### Agentes/Subagentes
- `planner`
- `implementer`
- `reviewer`
- `researcher`
- `regression-hunter`

---

## 16. Arquivos mínimos para implantar amanhã

1. `AGENTS.md`
2. `CLAUDE.md`
3. `ARCHITECTURE.md`
4. `AI_PROCESS.md` ou este documento
5. `docs/invariants/core.md`
6. `docs/exec-packs/active/`
7. `.claude/settings.json`
8. `.claude/skills/`
9. `.claude/agents/`
10. `.codex/config.toml`
11. `codex/rules/default.rules`
12. `artifacts/`

---

## 17. Padrão mínimo de adoção em 7 dias

### Dia 1
- criar estrutura do repositório;
- gerar `CLAUDE.md` inicial;
- escrever `AGENTS.md`.

### Dia 2
- definir invariantes essenciais;
- definir branch/worktree padrão;
- criar template de Context Pack.

### Dia 3
- criar 2 ou 3 skills principais;
- criar um subagente revisor;
- criar uma rotina simples de artifact.

### Dia 4
- adicionar hooks e bloqueios básicos;
- definir política de permissões.

### Dia 5
- configurar `.codex/config.toml`;
- criar regras básicas em `codex/rules/`;
- testar `codex exec` para uma tarefa segura.

### Dia 6
- testar fluxo completo em um ticket pequeno;
- medir ruído, excesso de contexto e falhas de handoff.

### Dia 7
- ajustar pacote, naming, evidências e checklist;
- oficializar o padrão como processo do projeto.

---

## 18. Decisão estratégica do processo

**ARTEMIS não é “deixar a IA solta”.**  
É criar uma operação em que a IA tem autonomia suficiente para gerar velocidade, mas dentro de trilhos que mantêm:

- coerência arquitetural;
- rastreabilidade;
- segurança operacional;
- qualidade de revisão;
- sustentabilidade do workspace.

Em termos práticos:

> **O humano define o sistema.  
> A IA prepara o contexto.  
> O agente executa o pacote.  
> Outro agente critica.  
> O repositório preserva a memória.**

---

## 19. Resumo executivo para colar no topo do repositório

```text
Este projeto usa o processo ARTEMIS:
Arquitetura, Regras, Contexto, Operação e Sustentação.

Regras centrais:
- a IA executa, o humano governa;
- toda tarefa relevante nasce de um Context Pack;
- um worktree por fluxo principal;
- um agente escritor por worktree;
- toda mudança precisa de evidência;
- arquitetura é protegida por arquivos, hooks, regras e revisão;
- sessões longas terminam com handoff;
- o repositório é a fonte de verdade.
```

---

# Addendum v1.2 — Arquitetura Universal de Agentes ARTEMIS

Este addendum atualiza o Fluxo ARTEMIS para incorporar uma arquitetura universal de agentes, aplicável a qualquer projeto que use Claude Code, Codex, OpenAI Agents SDK, Claude Managed Agents, MCP, skills, hooks, sandboxes e worktrees.

Documento complementar obrigatório:

```text
docs/agents/ARTEMIS_AGENT_ARCHITECTURE.md
```

Arquivo entregue neste pacote:

```text
artemis-arquitetura-agentes.md
```

A partir da v1.2, o ARTEMIS deixa de tratar agentes apenas como papéis informais e passa a tratá-los como componentes arquiteturais com contrato explícito.

Regra nova:

> Nenhum projeto ARTEMIS deve criar agentes soltos. Todo agente precisa de missão, permissões, ferramentas, entradas, saídas, critérios de parada e protocolo de handoff.

---

## 20. Arquitetura de agentes no ARTEMIS

O ARTEMIS passa a usar uma arquitetura em camadas:

1. **Plano de Controle** — humano, prioridade, arquitetura, risco e aprovação.
2. **Plano de Contexto** — AGENTS.md, CLAUDE.md, Context Packs, ADRs, invariants e memória útil.
3. **Plano de Agentes** — preparador, planejador, executor, revisor, auditor e guardião de memória.
4. **Plano de Ferramentas** — Claude Code, Codex, SDKs, MCP, shell, hooks, skills, sandboxes e CI.
5. **Plano de Evidência** — artifacts, traces, logs, validações, diffs e handoffs.
6. **Plano de Governança** — permissões, guardrails, policies, zonas protegidas e aprovações.
7. **Plano de Evolução** — changelogs, Capability Registry, testes de novos recursos e atualização contínua.

O objetivo é evitar dois extremos:

- agente genérico demais, que improvisa tudo;
- arquitetura multiagente complexa demais, que cria ruído e custo.

O ARTEMIS deve começar simples e escalar somente quando houver ganho real de qualidade, rastreabilidade, velocidade ou redução de risco.

---

## 21. Núcleo mínimo de agentes

Todo projeto ARTEMIS deve começar com o núcleo abaixo.

### 21.1 Context Curator

Prepara o Context Pack antes da execução.

Responsável por:

- entender o pedido do humano;
- localizar documentos relevantes;
- selecionar arquivos prioritários;
- identificar invariantes;
- reduzir ruído;
- montar o prompt do executor;
- montar o prompt do revisor.

Não deve implementar a tarefa principal.

### 21.2 Implementer

Executa a mudança no worktree correto.

Responsável por:

- alterar código, testes e documentação dentro do escopo;
- usar Claude Code, Codex ou outro runtime autorizado;
- registrar evidências;
- parar se o escopo ou risco mudar.

### 21.3 Reviewer

Revisa a mudança contra o Context Pack, os invariantes e a arquitetura.

Responsável por:

- analisar diff;
- procurar drift de escopo;
- verificar testes;
- procurar violação de arquitetura;
- apontar riscos;
- recomendar merge, retrabalho ou escalonamento.

### 21.4 Memory Keeper

Preserva aprendizado útil.

Responsável por:

- atualizar handoffs;
- sugerir ADRs;
- atualizar docs curtas;
- manter AGENTS.md e CLAUDE.md pequenos;
- transformar repetição em skill, hook, invariant ou runbook.

---

## 22. Agentes opcionais

Adicionar somente quando o projeto justificar.

- **Architecture Steward:** fronteiras, dependências e decisões estruturais.
- **Test & Eval Auditor:** cobertura, regressão, fixtures e critérios objetivos.
- **Security Reviewer:** secrets, auth, permissões, inputs externos e comandos perigosos.
- **Data & Migration Reviewer:** schema, rollback, compatibilidade e integridade de dados.
- **Docs Keeper:** documentação operacional e pública.
- **Release Manager:** changelog, release notes, checklist e rollback.
- **Toolsmith / Harness Engineer:** skills, hooks, MCPs, scripts, guardrails e harness.
- **Researcher:** changelogs, docs oficiais, issues e padrões externos.

Regra:

> Agente opcional entra por necessidade observável, não por entusiasmo arquitetural.

---

## 23. Níveis de maturidade do ARTEMIS

Cada Context Pack deve indicar o nível ARTEMIS da execução.

### Nível 0 — Execução simples

Um agente executor resolve tarefa pequena e entrega evidência.

Usar para:

- docs simples;
- correções pequenas;
- scripts de baixo risco;
- ajustes locais.

### Nível 1 — Preparar, executar, revisar

Fluxo mínimo recomendado para projetos reais.

Agentes:

- Context Curator;
- Implementer;
- Reviewer.

### Nível 2 — Subagentes especializados

Usar quando há pesquisa, revisão ou tarefas paralelizáveis.

Exemplos:

- subagente de testes;
- subagente de segurança;
- subagente de documentação;
- subagente de exploração de código.

### Nível 3 — Multi-worktree coordenado

Usar para épicos, migrações e abordagens concorrentes.

Regra obrigatória:

> Um escritor por worktree. Nunca dois agentes editando o mesmo worktree ao mesmo tempo.

### Nível 4 — Harness programável

Usar quando o ARTEMIS precisa virar pipeline, produto ou operação agentic durável.

Ferramentas típicas:

- OpenAI Agents SDK;
- Claude Managed Agents;
- Codex CLI como MCP;
- tracing;
- sessions;
- guardrails;
- sandboxes;
- evals.

---

## 24. Novos campos obrigatórios no Context Pack

Adicionar ao template de Context Pack:

```md
## Nível ARTEMIS da execução
Nível 0, 1, 2, 3 ou 4.

## Agentes envolvidos
Lista dos papéis usados nesta tarefa.

## Ferramentas autorizadas
Claude Code, Codex, SDK, MCP, shell, browser, hooks, skills etc.

## Ferramentas proibidas
Ações, comandos ou integrações que não podem ser usados.

## Política de permissão
O que pode ser feito sem confirmação, com confirmação e nunca.

## Handoff esperado
Formato e destino do handoff final.

## Evidência mínima
Artifacts obrigatórios para considerar a tarefa pronta.
```

---

## 25. Estrutura nova recomendada no repositório

Adicionar:

```text
repo/
├── docs/
│   └── agents/
│       ├── ARTEMIS_AGENT_ARCHITECTURE.md
│       ├── AGENT_REGISTRY.md
│       ├── CAPABILITY_REGISTRY.md
│       ├── TOOL_POLICY.md
│       ├── HANDOFF_PROTOCOL.md
│       └── cards/
│           ├── context-curator.md
│           ├── implementer.md
│           ├── reviewer.md
│           ├── memory-keeper.md
│           ├── architecture-steward.md
│           ├── test-auditor.md
│           ├── security-reviewer.md
│           └── toolsmith.md
├── .claude/
│   ├── agents/
│   ├── skills/
│   └── hooks/
└── .codex/
    ├── config.toml
    ├── agents/
    └── skills/
```

---

## 26. Capability Registry

Como Claude Code, Codex, OpenAI Agents SDK e Claude Platform mudam continuamente, o ARTEMIS passa a exigir um registro de capacidades.

Arquivo:

```text
docs/agents/CAPABILITY_REGISTRY.md
```

Modelo mínimo:

```md
# Capability Registry

| Plataforma | Capacidade | Status | Onde usar | Risco | Última verificação | Fonte |
|---|---|---|---|---|---|---|
| Claude Code | Subagents | ativo | pesquisa, revisão, tarefas isoladas | custo/contexto | 2026-04-24 | docs |
| Claude Code | Hooks | ativo | bloqueios, logs, validação | falso positivo | 2026-04-24 | docs |
| Codex | Subagents | ativo | paralelismo explícito | tokens/coordenação | 2026-04-24 | docs |
| Codex | codex exec | ativo | automações e CI | execução não supervisionada | 2026-04-24 | docs |
| OpenAI Agents SDK | Guardrails | ativo | segurança e validação | cobertura incompleta | 2026-04-24 | docs |
| OpenAI Agents SDK | Tracing | ativo | observabilidade | dados sensíveis | 2026-04-24 | docs |
| Claude Platform | Managed Agents | ativo | agentes de produto/operação | acoplamento | 2026-04-24 | docs |
```

Regra:

> Recurso novo entra primeiro no Capability Registry, depois em teste pequeno, depois vira skill, hook, agente ou política.

---

## 27. Tool Policy

Todo projeto ARTEMIS deve separar ferramentas por risco.

Arquivo:

```text
docs/agents/TOOL_POLICY.md
```

Categorias:

1. **Leitura segura:** grep, cat, rg, git diff, docs, busca local.
2. **Escrita local controlada:** edição no worktree, apply patch, geração de docs.
3. **Execução local:** testes, linters, build, scripts não destrutivos.
4. **Rede e MCP externo:** GitHub, Linear, Figma, docs internas, observabilidade.
5. **Ações sensíveis:** deploy, banco, produção, secrets, billing, auth, migrações destrutivas.

Regra:

> Quanto mais poderosa a tool, mais explícita deve ser sua permissão.

---

## 28. Handoff Protocol

Todo handoff entre agentes deve seguir formato padronizado.

Arquivo:

```text
docs/agents/HANDOFF_PROTOCOL.md
```

Modelo:

```md
# Agent Handoff — <ticket>

## De
Agente remetente.

## Para
Agente destinatário.

## Objetivo
Por que o trabalho está sendo transferido.

## Estado atual
O que já foi feito.

## Contexto mínimo
Arquivos, decisões e restrições relevantes.

## Evidências
Artifacts, comandos e resultados.

## Riscos
Riscos conhecidos.

## Próxima ação
O que o próximo agente deve fazer.

## Critérios de parada
Quando escalar para o humano.
```

---

## 29. Uso atualizado das ferramentas

### 29.1 Claude Code

Usar para:

- implementação exploratória;
- refactors localizados;
- entendimento profundo do repositório;
- subagentes em `.claude/agents/`;
- skills em `.claude/skills/`;
- hooks determinísticos;
- fluxos com humano próximo no terminal.

Boas práticas:

- manter `CLAUDE.md` curto;
- criar subagentes com frontmatter, ferramentas e permissões;
- usar hooks para regras determinísticas;
- transformar procedimentos repetíveis em skills;
- revisar changelog regularmente.

### 29.2 Codex

Usar para:

- execução no terminal Linux/VPS;
- automações com `codex exec`;
- revisão local antes de commit;
- subagentes paralelos quando explicitamente solicitados;
- MCP para ferramentas externas;
- workflows com AGENTS.md, skills, approvals e sandbox.

Boas práticas:

- começar por `AGENTS.md` e linters;
- criar skills antes de criar muitos agentes;
- conectar MCP somente quando necessário;
- usar subagentes para ruído, pesquisa e paralelismo real;
- usar Codex como MCP dentro do OpenAI Agents SDK quando o fluxo precisar ser programável e auditável.

### 29.3 OpenAI Agents SDK

Usar quando:

- for necessário harness programável;
- houver handoffs entre agentes;
- forem necessários guardrails;
- sessions, tracing e compaction agregarem valor;
- o fluxo precisar de sandbox/Manifest;
- Codex precisar ser orquestrado como parte de pipeline.

### 29.4 Claude Managed Agents

Usar quando:

- o agente virar produto, operação interna ou fluxo gerenciado;
- for necessário combinar files, skills, MCP, avaliações, guardrails e contexto gerenciado;
- a execução ultrapassar o terminal e entrar em experiência empresarial.

---

## 30. Política de atualização contínua

Cadência recomendada:

- **semanal** em projetos ativos;
- **mensal** em projetos estáveis;
- **imediata** quando changelog alterar subagentes, hooks, sandbox, MCP, skills, guardrails, sessions, tracing, WebSockets ou permissões.

Ordem de adoção:

1. Ler documentação oficial.
2. Atualizar Capability Registry.
3. Testar em tarefa pequena.
4. Registrar ganho e risco.
5. Promover para skill, hook, agente ou policy.
6. Revisar depois de três usos reais.

Regra final:

> O ARTEMIS deve ser estável nos princípios e flexível nas ferramentas.


---

# Addendum v1.3 — Modelo Operacional GitHub

A versão 1.3 conecta o ARTEMIS ao GitHub como camada oficial de coordenação entre humano, equipe, Claude Code, Codex, CI/CD e rastreabilidade.

Documento complementar:

```text
artemis-github-operating-model.md
```

## G1. Regra de coordenação

O ARTEMIS passa a usar esta cadeia operacional:

```text
Issue ou Exec Pack
    ↓
Branch de trabalho
    ↓
Worktree local/VPS
    ↓
Commits rastreáveis
    ↓
Pull Request
    ↓
CI + revisão por IA
    ↓
Revisão humana
    ↓
Merge controlado
    ↓
Registro de handoff
```

## G2. GitHub não substitui a VPS

A VPS continua sendo o ambiente preferencial para execução profunda, sessões longas e trabalho terminal-first. O GitHub registra, protege e coordena.

## G3. Regras mínimas

- Todo trabalho relevante deve ter issue ou Exec Pack.
- Todo trabalho relevante deve ocorrer em branch isolada.
- Todo agente escritor deve operar em worktree própria.
- Todo merge deve passar por PR.
- Branch principal deve ter ruleset ou branch protection.
- Mudanças sensíveis devem usar CODEOWNERS.
- Codex e Claude podem revisar PRs, mas revisão humana continua obrigatória em risco médio/alto.
- Secrets não devem aparecer em issue, PR, commit, prompt ou Exec Pack.

## G4. Claude Code e Codex no GitHub

- Claude Code pode atuar via terminal ou GitHub Actions, quando configurado.
- Codex pode revisar PRs via GitHub e executar tarefas contextuais quando mencionado.
- `AGENTS.md` deve conter guidelines de revisão para Codex.
- `CLAUDE.md` deve conter guidelines operacionais para Claude Code.

## G5. Ordem recomendada de adoção

1. Criar PR template.
2. Criar issue template ARTEMIS.
3. Criar labels ARTEMIS.
4. Ativar branch protection ou ruleset em `main`.
5. Criar CODEOWNERS para áreas sensíveis.
6. Criar workflow básico de CI.
7. Adicionar guidelines de revisão no `AGENTS.md`.
8. Configurar Codex review.
9. Configurar Claude Code GitHub Actions somente depois que o fluxo base estiver estável.
