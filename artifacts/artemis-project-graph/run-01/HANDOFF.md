# HANDOFF

## Estado

Project Operations Graph esta `project_graph_ready` como read model operacional. Ele conecta tarefas, agentes, gates, validacao, memoria, custos e artifacts sem iniciar runtime.

## Proximo corte

- Implementar `TKT-056 - Human-readable Project Brief do ARTEMIS Symphony`.
- Renderizar relacoes do grafo no Control Plane com linguagem operacional e leiga.

## Nao fazer

- Nao tratar grafo como fonte de verdade.
- Nao iniciar banco de grafo, embeddings, indexador ou agentes sem Human Gate.
- Nao bypassar Exec Pack, Validation Gate ou Human Gate por causa de arestas derivadas.
