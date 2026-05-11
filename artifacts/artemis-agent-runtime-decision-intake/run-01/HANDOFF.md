# ARTEMIS AGENT RUNTIME DECISION INTAKE HANDOFF

## Estado

TKT-061 classificou a decisao humana de runtime como `pending` com overall `human_gate`.

## Interpretacao

- `approved_ready`: pode seguir para launcher preflight, ainda sem executar agente.
- `pending`: humano ainda precisa preencher a decisao.
- `deferred`: pedido de runtime fica preservado para revisao futura.
- `rejected`: runtime foi recusado e a evidencia fica registrada.
- `invalid`: decisao precisa ser corrigida antes de qualquer preflight.

## Proximo corte

- Implementar `TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`, mantendo runtime bloqueado ate existir `approved_ready`.

## Nao fazer

- Nao iniciar Codex app-server, Claude Code, SDK, CLI, subagente, fila ou daemon neste intake.
- Nao executar `approved_commands` neste intake.
- Nao preencher decisao humana em nome do humano.
- Nao fazer push, PR, deploy, producao ou tocar secrets.
