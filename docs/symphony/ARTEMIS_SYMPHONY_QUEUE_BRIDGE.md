# ARTEMIS Symphony Queue Bridge

Este documento define o corte TKT-047: execucao supervisionada a partir da fila
ARTEMIS Symphony.

## Objetivo

Consumir um item revisado da fila, exigir um comando explicito no terminal e
chamar o bridge supervisionado em modo plan-only por padrao.

A partir do TKT-048, o mesmo script aceita `--execute`, mas somente quando
recebe Validation Gate e decisao aprovada exata.

## Comando

```bash
scripts/artemis-symphony-queue-bridge.sh \
  --queue artifacts/artemis-symphony-queue/run-01/symphony-queue.json \
  --ticket TKT-000 \
  --command "scripts/artemis-dry-run.sh --input control-plane/tasks.json" \
  --artifact-root artifacts/artemis-symphony-queue-bridge/run-01
```

Saida JSON:

```bash
scripts/artemis-symphony-queue-bridge.sh --ticket TKT-000 --command "cmd" --json
```

## Contrato

- o item deve existir na fila;
- o item deve estar em `review_required`;
- o item deve exigir `terminal_override_required=true`;
- o comando deve ser fornecido explicitamente pelo terminal;
- por padrao, o bridge e chamado sem `--execute`;
- `execute_requested=false` em modo plan-only;
- `commands_executed=0` em modo plan-only;
- `runner_executed=false` em modo plan-only;
- `validation_gate_required_before_execute=true`;
- `--execute` exige `--validation-gate` e `--decision`;
- decisao aprovada deve bater exatamente com `ticket`, `queue_id`, `command` e
  `validation_gate`.

## Artefatos

- `queue-bridge.json`: decisao da fila ate o bridge.
- `events.json`: evento canonico do roteamento supervisionado.
- `STATUS.md`: resumo operacional.
- `VALIDATION.md`: evidencia de validacao do corte.
- `HANDOFF.md`: proximo passo para execucao real opt-in.
- `bridge/`: artefatos do `scripts/artemis-symphony-bridge.sh`.

## Invariantes

- A fila nao vira daemon executavel.
- O bridge continua supervisionado.
- Execucao real exige opt-in explicito.
- Human Gates continuam explicitos.
- Validation Gate e obrigatorio antes de qualquer execucao real.

## Proximo corte

`TKT-057 - Guided Human Collaboration Mode do ARTEMIS Symphony`
