# ARTEMIS Symphony Service

O ARTEMIS Symphony Service e o ciclo local finito que compoe as pecas ja
existentes do Symphony sem transformar a fila em execucao automatica.

Ele roda:

1. `scripts/artemis-symphony-daemon.sh`
2. `scripts/artemis-symphony-queue.sh`
3. `scripts/artemis-symphony-queue-bridge.sh` apenas quando o terminal fornece
   `--ticket` ou `--queue-id` junto com `--command`

## Contrato

- O service e finito e encerra apos os ticks solicitados.
- O service nao aceita `--execute`.
- O service nunca passa `--execute` para o Queue Bridge.
- O service nunca infere comando a partir da fila.
- O service preserva terminal override e Human Gates.
- Execucao real continua pertencendo ao Queue Bridge com `--execute`,
  `--validation-gate` e `--decision`.

## Uso sem bridge

```bash
scripts/artemis-symphony-service.sh \
  --artifact-root artifacts/artemis-symphony-service/run-01 \
  --ticks 1 \
  --interval 0 \
  --max-concurrency 1 \
  --json
```

Esse modo gera daemon e fila. Se nao houver item elegivel, o resultado esperado
e `service_idle`; se houver item revisavel, o resultado esperado e
`service_queue_ready`.

## Uso com Queue Bridge plan-only

```bash
scripts/artemis-symphony-service.sh \
  --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json \
  --artifact-root artifacts/artemis-symphony-service/run-01 \
  --ticks 1 \
  --interval 0 \
  --max-concurrency 1 \
  --ticket TKT-949 \
  --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json" \
  --json
```

Esse modo chama o Queue Bridge sem `--execute`, produz
`service_bridge_plan_ready` e mantem `commands_executed=0`.

## Artifacts

- `symphony-service.json`
- `daemon/symphony-daemon.json`
- `queue/symphony-queue.json`
- `queue-bridge/queue-bridge.json`, quando solicitado
- `events.json`
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Invariantes

- Service nao e daemon persistente.
- Service nao substitui o terminal.
- Service nao aprova Human Gates.
- Service nao executa comandos reais.
- Service apenas encadeia evidencias locais auditaveis.

## Proximo corte

`TKT-060 - Agent Runtime Approval Gate do ARTEMIS Symphony`
