# HANDOFF

## Estado

Project Operations Graph esta `project_graph_ready` como read model operacional. Ele conecta tarefas, agentes, gates, validacao, memoria, custos e artifacts sem iniciar runtime.

## Proximo corte

- Nenhum TKT planejado no escopo atual da espinha de runtime.
- Abrir novo Exec Pack apenas para uma nova fase ou melhoria deliberada.

## Nao fazer

- Nao tratar grafo como fonte de verdade.
- Nao iniciar banco de grafo, embeddings, indexador ou agentes sem Human Gate.
- Nao bypassar Exec Pack, Validation Gate ou Human Gate por causa de arestas derivadas.
