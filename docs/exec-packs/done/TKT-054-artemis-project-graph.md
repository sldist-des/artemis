# TKT-054 - Project Operations Graph do ARTEMIS Symphony

## Objetivo

Materializar o Project Operations Graph do ARTEMIS Symphony como contrato
read-only, conectando projeto, tarefas, agentes, dependencias, gates,
validacoes, custos, memoria e artifacts.

## Resultado esperado

O repositorio deve gerar um grafo operacional auditavel sem instalar banco de
grafo, embeddings, indexador, agentes ou runtime novo.

## Nivel ARTEMIS da execucao

Nivel 2 - mudanca arquitetural de contrato e validacao, sem runtime externo.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.

## Escopo

- Criar `scripts/artemis-project-graph.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md`.
- Gerar artifacts em `artifacts/artemis-project-graph/run-01/`.
- Registrar evento canonico `evt_tkt-054_project_graph`.
- Integrar o contrato ao Control Plane, validation gate, event log e spec do
  ARTEMIS Symphony.

## Fora de escopo

- Banco de grafo.
- Embeddings.
- Indexador incremental real.
- UI interativa de grafo.
- Execucao automatica de agentes.

## Evidencias obrigatorias

- `artifacts/artemis-project-graph/run-01/STATUS.md`
- `artifacts/artemis-project-graph/run-01/project-graph.json`
- `artifacts/artemis-project-graph/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-project-graph.sh
scripts/artemis-project-graph.sh --artifact-root artifacts/artemis-project-graph/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Handoff

O proximo corte e `TKT-057 - Guided Human Collaboration Mode do ARTEMIS Symphony`, renderizando
as relacoes do grafo no Control Plane com linguagem operacional e leiga.
