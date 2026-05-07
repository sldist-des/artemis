# ARTEMIS Symphony Bridge

A ponte supervisionada conecta o plano read-only do ARTEMIS Symphony Kernel ao runner local supervisionado.

## Decisao

A ponte nao e daemon. Ela roda sob comando explicito no terminal, gera um novo plano do kernel, seleciona um ticket presente em `dispatch_plan` e cria uma tentativa do runner.

Por padrao, a tentativa do runner e plan-only. O comando passado para `--command` so executa quando `--execute` for fornecido explicitamente.

## Comando

```bash
scripts/artemis-symphony-bridge.sh \
  --input control-plane/tasks.json \
  --ticket TKT-000 \
  --command "scripts/validate-artemis.sh" \
  --artifact-root artifacts/artemis-symphony-bridge/run-01
```

Execucao real continua opt-in:

```bash
scripts/artemis-symphony-bridge.sh \
  --ticket TKT-000 \
  --command "scripts/validate-artemis.sh" \
  --execute
```

## Entradas

- `--input`: task source JSON.
- `--ticket`: ticket que deve estar presente no `dispatch_plan`.
- `--command`: comando supervisionado que sera entregue ao runner.
- `--artifact-root`: diretorio de evidencia da ponte.
- `--max-concurrency`: limite usado pelo kernel antes da selecao.
- `--execute`: permite execucao real pelo runner.
- `--use-workspace`: exige `--execute` e usa workspace materializado.
- `--json`: imprime o payload canonico no stdout.

## Saidas

- `symphony-bridge.json`: resultado da ponte.
- `events.json`: evento canonico da ponte.
- `kernel/`: artifact completo do kernel.
- `runner/`: tentativa supervisionada do runner, quando o ticket e dispatchable.
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Contrato

- A ponte sempre roda o kernel antes de chamar o runner.
- A ponte so aceita ticket presente em `dispatch_plan`.
- O modo padrao e plan-only.
- `commands_executed` permanece `0` sem `--execute`.
- `automatic_daemon` permanece `false`.
- Push, merge, comandos remotos, destrutivos ou deploy continuam bloqueados pelo runner e por Human Gate.

## Proximo Corte

`TKT-050 - Fonte remota supervisionada do ARTEMIS Symphony`

Objetivo: consumir item revisado da fila com comando explicito, mantendo a ponte como acao de terminal.
