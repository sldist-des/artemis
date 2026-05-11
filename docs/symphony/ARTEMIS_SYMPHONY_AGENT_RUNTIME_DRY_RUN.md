# ARTEMIS Symphony Agent Runtime Dry-Run

O Agent Runtime Dry-Run e o primeiro ensaio auditavel depois do Agent Launch
Contract. Ele transforma o contrato em um pedido de runtime estruturado, mas
nao inicia agente real.

## Contrato

- Consome `artifacts/artemis-agent-launch-contract/run-01/agent-launch-contract.json`.
- Seleciona um perfil de runtime conhecido.
- Registra tarefa, modelo, budget, auth, comando, workspace, rollback,
  evidencia e stop rule.
- Mantem `execute=false`, `runtime_started=false`, `agents_started=0`,
  `commands_executed=0`, `paid_tokens_authorized=0` e
  `remote_writes_allowed=false`.
- Trata auth e budget como Human Gates antes de qualquer runtime real.
- Nao executa Codex app-server, Claude Code, subagentes, daemon, queue bridge,
  dependencia, segredo, push, PR, issue mutation, deploy ou producao.

## Artefatos

O script `scripts/artemis-agent-runtime-dry-run.sh` gera:

- `artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json`
- `artifacts/artemis-agent-runtime-dry-run/run-01/REQUEST.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/PREFLIGHT.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/RUNTIME_LOG.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/events.json`

## Proximo corte

`TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony`
