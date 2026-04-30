# TKT-006 - Planejar ARTEMIS Orchestrator

## Objetivo

Definir o plano arquitetural do ARTEMIS Orchestrator, usando Symphony como inspiracao e Codex app-server / Claude Code Agent SDK como superficies de execucao, sem perder o controle terminal-first.

## Resultado esperado

Um plano versionado deve deixar claro:

- o que ARTEMIS adota de Symphony;
- o que ARTEMIS muda;
- quais sao as fases de implementacao;
- quais gates de teste, validacao e evidencia tornam a orquestracao confiavel;
- onde Codex, Codex app-server, Claude Code e humano entram no fluxo.

## Nivel ARTEMIS da execucao

Nivel 1 - planejamento arquitetural com evidencia.

## Agentes envolvidos

- Context Curator: consolidar referencias e contexto local.
- Planner: desenhar fases e criterios de aceite.
- Architecture Steward: preservar fronteiras ARTEMIS.
- Memory Keeper: registrar artifacts.

## Contexto minimo

- `docs/principles/artemis-principles.md`
- `docs/control-plane/artemis-control-plane.md`
- `docs/agents/TOOL_POLICY.md`
- `AI_PROCESS.md`
- `ARCHITECTURE.md`
- Referencias:
  - https://openai.com/index/open-source-codex-orchestration-symphony/
  - https://developers.openai.com/codex/app-server
  - Claude Code headless / Agent SDK / hooks / subagents docs

## Escopo

- Criar plano de orquestracao ARTEMIS.
- Definir nomes corretos: Control Plane como conceito principal.
- Definir fases antes de implementar daemon.
- Definir matriz Codex/Claude.
- Definir gates de confiabilidade.

## Fora de escopo

- Implementar daemon.
- Integrar Codex app-server.
- Integrar Claude Code SDK.
- Sincronizar GitHub Issues.
- Renomear arquivos existentes nesta rodada.

## Invariantes

- Terminal-first continua sendo o modo de controle soberano.
- Orquestrador nunca substitui revisao humana em risco medio/alto.
- Toda execucao automatizada deve produzir evidencia.
- Nenhum runner roda sem sandbox/worktree/validacao definida.
- ARTEMIS nao copia Symphony; usa Symphony como especificacao inspiradora.

## Ferramentas autorizadas

- Leitura local.
- Documentacao oficial.
- Edicao de docs.
- Validacao local.

## Ferramentas proibidas

- Deploy.
- Daemon persistente.
- Escrita remota.
- Instalacao de dependencias.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `artifacts/artemis-orchestration-plan/run-01/STATUS.md`
- `artifacts/artemis-orchestration-plan/run-01/VALIDATION.md`
- `artifacts/artemis-orchestration-plan/run-01/HANDOFF.md`

## Escalonar para humano se

- For necessario escolher entre GitHub Issues e Exec Packs locais como primeira fonte de tarefas.
- For necessario autorizar daemon persistente.
- For necessario instalar dependencias ou criar servico systemd.

## Entregaveis

- Plano ARTEMIS Orchestrator.
- Artifacts.
- Commit local.
