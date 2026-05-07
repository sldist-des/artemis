# ARTEMIS Symphony Daemon Dry-run

O daemon dry-run do ARTEMIS Symphony prova o loop de observacao sem criar um processo persistente nem executar agentes.

## Decisao

O primeiro daemon e finito por contrato. Ele roda por `--ticks`, chama o kernel read-only em cada tick, grava heartbeat e encerra.

Ele nao chama a ponte, nao chama o runner, nao cria worktree, nao abre PR, nao faz push, nao faz merge, nao executa cleanup e nao passa Human Gates automaticamente.

## Comando

```bash
scripts/artemis-symphony-daemon.sh \
  --input control-plane/tasks.json \
  --artifact-root artifacts/artemis-symphony-daemon/run-01 \
  --ticks 1 \
  --interval 0 \
  --max-concurrency 1
```

Para JSON:

```bash
scripts/artemis-symphony-daemon.sh --json
```

## Entradas

- `--input`: task source JSON.
- `--artifact-root`: diretorio de evidencia.
- `--max-concurrency`: limite enviado ao kernel.
- `--ticks`: numero finito de ciclos.
- `--interval`: segundos entre ticks.
- `--json`: imprime o payload canonico no stdout.

## Saidas

- `symphony-daemon.json`: resultado consolidado.
- `heartbeat.json`: ultimo heartbeat.
- `heartbeat.jsonl`: historico de heartbeats.
- `ticks/*/kernel/`: artifact completo do kernel por tick.
- `events.json`: eventos canonicos do daemon dry-run.
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Contrato

- O daemon dry-run so chama o kernel.
- `commands_executed` permanece `0`.
- `runner_auto_execution_allowed` permanece `false`.
- `bridge_called` permanece `false`.
- `long_running_process_started` permanece `false`.
- Human Gates sao observados e registrados, nunca resolvidos automaticamente.
- Exec Pack e artifacts continuam sendo a fonte canonica; Control Plane segue observacional.

## Proximo Corte

`TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony`

Objetivo: consumir item revisado da fila com comando explicito e ponte supervisionada plan-only por padrao.
