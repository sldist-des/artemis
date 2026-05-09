# HANDOFF

## Estado

Promocao local do intake esta `remote_promotion_human_gate`. A fonte local promovida fica em `promoted-source.json` e ainda nao executa nada sozinha.

## Proximo corte

- Implementar `TKT-061 - Agent Runtime Decision Intake do ARTEMIS Symphony`.
- Manter comentarios, labels, branches e PRs atras de decisao humana exata.

## Nao fazer

- Nao chamar Queue, Bridge ou Runner a partir da promocao.
- Nao escrever em GitHub.
- Nao aceitar decisao generica sem ticket, Exec Pack, evidencia, owner, risco e comando exatos.
