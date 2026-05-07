# ARTEMIS Symphony Queue Execution

Este documento define o corte TKT-048: execucao real opt-in a partir da fila
ARTEMIS Symphony.

## Objetivo

Permitir que um item revisado da fila chegue a execucao real somente quando
existem tres sinais explicitos:

- `--execute` no terminal;
- Validation Gate com falhas tecnicas zero;
- decisao aprovada que bate exatamente com `ticket`, `queue_id` e `command`.

## Comando

```bash
scripts/artemis-symphony-queue-bridge.sh \
  --queue artifacts/artemis-symphony-queue-execution/run-01/queue/symphony-queue.json \
  --ticket TKT-948 \
  --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json" \
  --artifact-root artifacts/artemis-symphony-queue-execution/run-01 \
  --execute \
  --validation-gate artifacts/artemis-symphony-queue-execution/run-01/fixtures/validation-gate.json \
  --decision artifacts/artemis-symphony-queue-execution/run-01/fixtures/decision.json
```

## Decisao aprovada

A decisao deve seguir este formato minimo:

```json
{
  "schema_version": 1,
  "decision": "approved",
  "ticket": "TKT-948",
  "queue_id": "queue-001-tkt-948",
  "command": "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json",
  "validation_gate": "artifacts/artemis-symphony-queue-execution/run-01/fixtures/validation-gate.json",
  "validation_human_gates_acknowledged": true,
  "decided_by": "human-or-fixture-owner",
  "reason": "Exact command approved for this queue item."
}
```

## Contrato

- Sem `--execute`, o comportamento continua plan-only.
- Com `--execute`, `--validation-gate` e `--decision` sao obrigatorios.
- Validation Gate deve ter `summary.failed=0`.
- Validation Gate pode estar em `passed` ou `human_gate`; quando estiver em
  `human_gate`, a decisao deve registrar
  `validation_human_gates_acknowledged=true`.
- A decisao deve ter `decision=approved`.
- `ticket`, `queue_id`, `command` e `validation_gate` devem bater exatamente.
- O runner ainda bloqueia comandos remotos, destrutivos e de deploy.

## Evidencia esperada

- `queue-bridge.json` com `overall=runner_executed`.
- `summary.execute_requested=true`.
- `summary.commands_executed=1`.
- `summary.runner_executed=true`.
- `summary.validation_gate_passed=true`.
- `summary.approval_exact=true`.
- `bridge/symphony-bridge.json` com `overall=runner_executed`.
- `bridge/runner/attempts/*/COMMAND.txt` com o log do comando executado.

## Proximo corte

`TKT-056 - Human-readable Project Brief do ARTEMIS Symphony`
