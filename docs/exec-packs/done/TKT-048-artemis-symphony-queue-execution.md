# TKT-048 - Execucao real opt-in com Validation Gate da fila ARTEMIS Symphony

## Objetivo

Permitir execucao real a partir de um item revisado da fila somente quando o
terminal passa `--execute`, a Validation Gate tem falhas tecnicas zero e uma
decisao aprovada bate exatamente com o ticket, queue id e comando.

## Nivel ARTEMIS da execucao

Nivel 2 - componente operacional local supervisionado com opt-in.

## Agentes envolvidos

- Architect: definir os gates minimos para permitir `--execute`.
- Executor: implementar contrato, docs, artifacts e Control Plane.
- Reviewer: validar que execucao real nao pode ocorrer sem Validation Gate e
  decisao exata.

## Contexto

TKT-047 criou o Queue Bridge plan-only. O TKT-048 habilita a mesma rota para
execucao real, mas apenas para comando local aprovado e validado.

## Escopo

- Estender `scripts/artemis-symphony-queue-bridge.sh` com `--execute`.
- Exigir `--validation-gate` e `--decision` para qualquer execucao.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md`.
- Atualizar spec, compatibilidade, Validation Gate e validacao local.
- Expor evidencia de execucao opt-in no Control Plane.
- Gerar artifacts em `artifacts/artemis-symphony-queue-execution/run-01/`.

## Fora de escopo

- Daemon persistente.
- Execucao automatica da fila.
- Push, PR, merge, deploy, secrets ou comandos remotos.
- Execucao sem decisao aprovada.

## Contrato

- Sem `--execute`, Queue Bridge continua plan-only.
- Com `--execute`, `--validation-gate` e `--decision` sao obrigatorios.
- Validation Gate deve ter `summary.failed=0`.
- Decisao deve ter `decision=approved`.
- Decisao deve incluir `decided_by` e `reason`.
- Decisao deve bater exatamente com `ticket`, `queue_id`, `command` e
  `validation_gate`.
- Se Validation Gate estiver em `human_gate`, decisao deve registrar
  `validation_human_gates_acknowledged=true`.

## Validacao

```bash
scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-queue-execution/run-01/queue/symphony-queue.json --ticket TKT-948 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json" --artifact-root artifacts/artemis-symphony-queue-execution/run-01 --execute --validation-gate artifacts/artemis-symphony-queue-execution/run-01/fixtures/validation-gate.json --decision artifacts/artemis-symphony-queue-execution/run-01/fixtures/decision.json --json
scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Resultado esperado

Queue Bridge gera `runner_executed` apenas para a decisao exata e mantem
`human_gate` quando falta decisao, Validation Gate ou correspondencia exata.

## Evidencias obrigatorias

- `artifacts/artemis-symphony-queue-execution/run-01/STATUS.md`
- `artifacts/artemis-symphony-queue-execution/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-queue-execution/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-queue-execution/run-01/queue-bridge.json`
- `artifacts/artemis-symphony-queue-execution/run-01/events.json`
- `artifacts/artemis-symphony-queue-execution/run-01/bridge/symphony-bridge.json`
