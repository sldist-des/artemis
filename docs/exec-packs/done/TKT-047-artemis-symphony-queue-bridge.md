# TKT-047 - Queue Bridge plan-only do ARTEMIS Symphony

## Objetivo

Consumir um item revisado da fila ARTEMIS Symphony e chamar o bridge
supervisionado em modo plan-only, exigindo comando explicito e preservando
`commands_executed=0`.

## Nivel ARTEMIS da execucao

Nivel 2 - componente operacional local supervisionado.

## Agentes envolvidos

- Architect: definir fronteira entre fila revisavel, terminal override e bridge.
- Executor: implementar script, docs, artifacts e Control Plane.
- Reviewer: validar que o corte nao passa `--execute` e nao executa runner real.

## Contexto

TKT-046 materializou a fila read-only a partir do daemon. O proximo passo
seguro e transformar um item revisado em uma chamada supervisionada ao bridge,
sem ainda habilitar execucao real.

## Escopo

- Criar `scripts/artemis-symphony-queue-bridge.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md`.
- Atualizar `docs/symphony/ARTEMIS_SYMPHONY_SPEC.md`.
- Atualizar compatibilidade, Validation Gate e validação local.
- Expor evidencia de Queue Bridge no Control Plane.
- Gerar artifacts em `artifacts/artemis-symphony-queue-bridge/run-01/`.

## Fora de escopo

- Passar `--execute` ao bridge.
- Executar comandos reais.
- Inferir comando automaticamente.
- Criar daemon persistente.
- Push, PR, merge, deploy ou cleanup.

## Contrato

- O item deve existir na fila.
- O item deve estar em `review_required`.
- `terminal_override_required` deve ser `true`.
- `--command` e obrigatorio.
- O bridge e chamado sem `--execute`.
- `execute_requested=false`.
- `commands_executed=0`.
- `runner_executed=false`.
- `validation_gate_required_before_execute=true`.

## Validacao

```bash
scripts/artemis-symphony-queue-bridge.sh --queue artifacts/artemis-symphony-queue-bridge/run-01/queue/symphony-queue.json --ticket TKT-947 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-bridge/run-01/fixtures/task-source.json" --artifact-root artifacts/artemis-symphony-queue-bridge/run-01 --json
scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Resultado esperado

Queue Bridge gera `bridge_plan_ready` para um item revisado sintetico e falha
com evidencia `not_in_queue` quando o ticket nao esta na fila, sempre sem
execucao real.

## Evidencias obrigatorias

- `artifacts/artemis-symphony-queue-bridge/run-01/STATUS.md`
- `artifacts/artemis-symphony-queue-bridge/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-queue-bridge/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-queue-bridge/run-01/queue-bridge.json`
- `artifacts/artemis-symphony-queue-bridge/run-01/events.json`
- `artifacts/artemis-symphony-queue-bridge/run-01/bridge/symphony-bridge.json`
