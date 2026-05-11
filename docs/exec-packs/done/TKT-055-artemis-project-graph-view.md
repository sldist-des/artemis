# TKT-055 - Project Graph View do ARTEMIS Symphony

## Objetivo

Renderizar as relacoes do Project Operations Graph no Control Plane com leitura
operacional clara para humanos e agentes.

## Resultado esperado

O Control Plane deve mostrar metricas, nos, relacoes, perguntas operacionais e
limites do grafo sem instalar dependencia, iniciar runtime ou mudar a fonte de
verdade do ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 2 - mudanca visual e de contrato, sem runtime externo.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.

## Escopo

- Adicionar secao `Project Graph` ao `control-plane/index.html`.
- Ler `artifacts/artemis-project-graph/run-01/project-graph.json`.
- Criar `scripts/artemis-project-graph-view.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH_VIEW.md`.
- Gerar artifacts em `artifacts/artemis-project-graph-view/run-01/`.
- Registrar evento canonico `evt_tkt-055_project_graph_view`.
- Integrar a view ao Validation Gate, Event Log e validacao local.

## Fora de escopo

- Banco de grafo.
- Frontend framework.
- Canvas engine.
- Runtime persistente.
- Execucao automatica de agentes.
- Alterar fonte canonica de verdade do ARTEMIS.

## Evidencias obrigatorias

- `artifacts/artemis-project-graph-view/run-01/STATUS.md`
- `artifacts/artemis-project-graph-view/run-01/project-graph-view.json`
- `artifacts/artemis-project-graph-view/run-01/events.json`

## Validacao

```bash
scripts/artemis-project-graph-view.sh --artifact-root artifacts/artemis-project-graph-view/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Handoff

O proximo corte e `TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`,
explicando o estado do projeto em linguagem leiga e acionavel a partir do grafo.
