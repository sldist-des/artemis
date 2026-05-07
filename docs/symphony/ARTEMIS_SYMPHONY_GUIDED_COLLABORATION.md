# ARTEMIS Symphony Guided Collaboration

Guided Collaboration e a entrada guiada do ARTEMIS Symphony para pessoas
escolherem projeto, tarefa, perfil de agente, gates e evidencia antes de
qualquer runtime real.

## Fontes

- `artifacts/artemis-project-brief/run-01/project-brief.json`
- `artifacts/artemis-project-graph/run-01/project-graph.json`
- `control-plane/tasks.json`
- `control-plane/index.html`

## O que o modo guiado mostra

- qual projeto esta em foco;
- quais etapas uma pessoa deve decidir antes de acionar agentes;
- quais perfis combinam com cada tipo de trabalho;
- quais Human Gates seguem bloqueando auth, custo, rede, escrita remota,
  producao e cleanup real;
- qual evidencia precisa existir antes de uma tarefa virar Done.

## Contrato

- Guided Collaboration e um contrato de orientacao, nao fonte de verdade;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- o Control Plane continua observacional;
- este modo nao inicia Codex, Claude Code, runner, bridge, fila, daemon,
  app-server, SDK, MCP, browser remoto ou servidor persistente;
- este modo nao autentica contas, nao cria issue, nao faz push, nao abre PR e
  nao altera configuracao remota;
- budget, modelo, tokens, agentes, comandos permitidos e evidencia esperada
  precisam estar explicitos antes de qualquer runtime real.

## Validacao

```bash
scripts/artemis-guided-collaboration.sh --artifact-root artifacts/artemis-guided-collaboration/run-01 --json
scripts/validate-artemis.sh
```

## Handoff

O proximo corte recomendado e `TKT-060 - Agent Runtime Approval Gate do ARTEMIS
Symphony`, usando o dry-run de runtime como entrada para aprovacao humana exata
antes de qualquer runtime real.
