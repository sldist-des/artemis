# ARTEMIS Symphony Agent Runtime Decision Intake

O Agent Runtime Decision Intake le o `runtime-approval-decision.json`
preenchido por humano e classifica a decisao antes de qualquer launcher real.

Ele nao inicia Codex app-server, Claude Code, subagentes, fila, daemon, comando,
tokens pagos, escrita remota, secrets, deploy ou producao.

## Contrato

- Consome `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json`.
- Consome `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-decision.json`.
- Classifica a decisao como `pending`, `approved_ready`, `deferred`, `rejected` ou `invalid`.
- `approved_ready` permite apenas o proximo launcher preflight; nao executa agente.
- `pending`, `deferred`, `rejected` e `invalid` mantem runtime bloqueado.
- Comandos remotos, producao, deploy, secrets e push continuam exigindo Human Gate separado.

## Artefatos

O script `scripts/artemis-agent-runtime-decision-intake.sh` gera:

- `artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/events.json`

## Proximo corte

`TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony`
