# ARTEMIS Symphony Supervised Queue

A fila supervisionada do ARTEMIS Symphony transforma o dispatch observado pelo daemon dry-run em itens revisaveis, sem executar agentes.

## Decisao

A fila e derivada de evidencia. Ela le `symphony-daemon.json`, abre o kernel do ultimo tick e materializa cada item do `dispatch_plan` como `review_required`.

Ela nao escolhe comando, nao chama a ponte, nao chama o runner, nao cria worktree, nao faz push, nao abre PR, nao faz merge e nao executa cleanup.

## Comando

```bash
scripts/artemis-symphony-queue.sh \
  --daemon artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json \
  --artifact-root artifacts/artemis-symphony-queue/run-01
```

Para JSON:

```bash
scripts/artemis-symphony-queue.sh --json
```

## Entradas

- `--daemon`: artifact `symphony-daemon.json`.
- `--artifact-root`: diretorio de evidencia.
- `--json`: imprime o payload canonico no stdout.

## Saidas

- `symphony-queue.json`: fila supervisionada.
- `events.json`: eventos canonicos da fila.
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Contrato

- A fila e read-only.
- Itens entram como `review_required`.
- Cada item exige terminal override antes da ponte.
- `commands_executed` permanece `0`.
- `bridge_called` permanece `false`.
- `runner_called` permanece `false`.
- `runner_auto_execution_allowed` permanece `false`.
- Human Gates sao preservados e nao viram itens executaveis.

## Proximo Corte

`TKT-053 - Feedback remoto supervisionado do ARTEMIS Symphony`

Objetivo: consumir um item revisado da fila por comando explicito, chamando a ponte em modo plan-only por padrao.
