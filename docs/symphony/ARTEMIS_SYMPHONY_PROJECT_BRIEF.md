# ARTEMIS Symphony Project Brief

Project Brief e a camada de explicacao humana do ARTEMIS Symphony.

Ele transforma o Project Operations Graph em uma leitura simples para pessoas
que colaboram no projeto sem precisar conhecer todos os artifacts, scripts,
gates e eventos internos.

## Fontes

- `artifacts/artemis-project-graph/run-01/project-graph.json`
- `artifacts/artemis-project-graph-view/run-01/project-graph-view.json`
- `control-plane/index.html`

## O que o briefing mostra

- o estado geral do projeto em linguagem direta;
- o que esta pronto;
- o que ainda depende de decisao humana;
- quais proximas acoes fazem sentido;
- como uma pessoa pode colaborar sem perder controle;
- quais limites impedem execucao automatica sem gate.

## Contrato

- Project Brief e explicacao, nao fonte de verdade;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- Control Plane continua sendo consumidor observacional;
- o briefing nao executa agente, runner, bridge, fila, servidor ou comando;
- o briefing nao instala dependencia;
- qualquer modo guiado futuro precisa manter terminal-first e explicitar budget,
  auth, rede, escrita remota, cleanup real e Human Gates.

## Validacao

```bash
scripts/artemis-project-brief.sh --artifact-root artifacts/artemis-project-brief/run-01 --json
scripts/validate-artemis.sh
```

## Handoff

O proximo corte recomendado e `TKT-057 - Guided Human Collaboration Mode do
ARTEMIS Symphony`, usando este briefing como porta de entrada para pessoas
escolherem projeto, tarefa, agente e acao com linguagem clara e limites
visiveis.
