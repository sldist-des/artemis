# ARTEMIS Symphony Agent Runtime Approval Gate

O Agent Runtime Approval Gate transforma o `runtime-dry-run.json` em um pacote
de decisao humana antes de qualquer runtime real.

Ele nao inicia Codex app-server, Claude Code, subagentes, fila, daemon, comando,
tokens pagos, escrita remota, secrets, deploy ou producao.

## Contrato

- Consome `artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json`.
- Gera `runtime-approval-decision.json` como arquivo humano-preenchivel.
- A decisao inicial e sempre `pending`.
- Decisoes validas: `pending`, `approved`, `deferred`, `rejected`.
- `approved` exige metadata, comando exato, budget positivo, auth, workspace,
  rollback e validacao.
- `pending`, `deferred` e `rejected` mantem `runtime_execution_allowed=false`.
- Este gate nunca executa comando; um corte posterior deve ingerir a decisao e
  preparar launcher/preflight.

## Artefatos

O script `scripts/artemis-agent-runtime-approval-gate.sh` gera:

- `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-decision.json`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/APPROVAL_REQUEST.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/DECISION_TEMPLATE.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/CHECKLIST.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/events.json`

## Proximo corte

`TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`
