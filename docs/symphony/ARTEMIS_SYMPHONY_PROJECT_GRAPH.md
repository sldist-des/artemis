# ARTEMIS Symphony Project Operations Graph

Project Operations Graph e o read model operacional do ARTEMIS Symphony. Ele
conecta projeto, tarefas, agentes, gates, validacao, memoria, custos e artifacts
para responder o que esta acontecendo sem transformar o painel ou um indice
derivado em fonte de verdade.

## Objetivo

- mostrar como o projeto esta;
- mostrar quem esta responsavel por qual parte;
- mostrar o que depende de decisao humana;
- mostrar o que foi validado;
- mostrar qual memoria alimenta agentes;
- mostrar qual custo ou runtime foi ativado;
- preparar uma visao leiga e operacional no Control Plane.

## Fontes

- `control-plane/tasks.json`
- `artifacts/artemis-event-log/run-01/event-log.example.json`
- `artifacts/artemis-memory-zone/run-01/memory-zone.json`
- `artifacts/artemis-validation-gate/run-01/validation-gate.json`
- Exec Packs, artifacts e Git como fonte canonica.

## Comando

```bash
scripts/artemis-project-graph.sh
scripts/artemis-project-graph.sh --json
```

## Contrato

- o grafo e read-only;
- o grafo e read model, nao autoridade de execucao;
- cada aresta deve ser explicavel por evidencia local;
- Exec Packs continuam definindo contrato de tarefa;
- Validation Gate continua definindo prova tecnica;
- Human Gate continua definindo decisao sensivel;
- Memory Zone fornece contexto, nao permissao;
- custos de token, embeddings, indexadores e agentes devem ser explicitos antes
  de runtime.

## Nao faz

- nao inicia banco de grafo;
- nao cria embeddings;
- nao instala dependencias;
- nao executa agentes;
- nao escreve remoto;
- nao aprova Human Gates;
- nao substitui artifacts, event log ou git.

## Artefatos

- `project-graph.json`
- `GRAPH.md`
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`
- `events.json`

## Perguntas que o grafo deve responder

- Como esta o projeto?
- O que mudou recentemente?
- Quem trabalhou em que?
- Qual agente depende de qual tarefa?
- O que bloqueia finalizar?
- Que evidencia prova o estado atual?
- Que contexto e seguro passar para Codex ou Claude Code?
- Qual custo ou runtime foi ativado?

## Proximo corte

`TKT-061 - Agent Runtime Decision Intake do ARTEMIS Symphony`
