# ARTEMIS Symphony Project Graph View

Project Graph View e a leitura visual do Project Operations Graph dentro do
Control Plane.

Ele nao cria uma nova fonte de verdade. O objetivo e tornar o grafo legivel para
humanos e agentes sem iniciar banco de grafo, framework frontend, canvas engine,
servidor persistente ou automacao remota.

## Fontes

- `artifacts/artemis-project-graph/run-01/project-graph.json`
- `control-plane/index.html`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md`

## O que a view mostra

- metricas do grafo: tasks, done, events, nodes, edges e validacao;
- nos operacionais: projeto, Exec Packs, owners, gates, validacao, memoria,
  evidence, Event Log, budget e Control Plane;
- relacoes do grafo em linguagem direta;
- perguntas operacionais que o grafo consegue responder;
- limites/invariantes que impedem bypass de Human Gate, Validation Gate, Exec
  Packs, Event Log, artifacts e git.

## Contrato

- Control Plane e consumidor observacional;
- Project Operations Graph continua sendo artifact local auditavel;
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos;
- a view nao executa agente, runner, bridge, fila ou comandos;
- a view nao instala dependencia;
- qualquer ampliacao para UI interativa real deve preservar terminal-first e
  passar por Human Gate quando envolver runtime, rede, auth ou custo.

## Validacao

```bash
scripts/artemis-project-graph-view.sh --artifact-root artifacts/artemis-project-graph-view/run-01 --json
scripts/validate-artemis.sh
```

## Handoff

O proximo corte recomendado e `TKT-056 - Human-readable Project Brief do ARTEMIS
Symphony`, transformando o mesmo grafo em explicacao leiga e acionavel para
pessoas que colaboram no projeto sem conhecer todos os artifacts.
