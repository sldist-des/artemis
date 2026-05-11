# ARTEMIS Symphony Kernel

O kernel local do ARTEMIS Symphony e o primeiro componente executavel do nosso Symphony proprio.

## Decisao

O kernel atual e read-only. Ele le uma fonte de tarefas, chama o dry-run ARTEMIS, aplica concorrencia maxima configuravel e grava um plano de dispatch em artifact.

Ele nao executa agente, nao cria worktree, nao cria branch, nao escreve lock, nao faz push, nao abre PR, nao faz merge e nao executa cleanup.

## Comando

```bash
scripts/artemis-symphony-kernel.sh \
  --input control-plane/tasks.json \
  --artifact-root artifacts/artemis-symphony-kernel/run-01 \
  --max-concurrency 1
```

Para JSON:

```bash
scripts/artemis-symphony-kernel.sh --json
```

## Entradas

- `--input`: task source JSON compativel com `scripts/artemis-tasks.sh`.
- `--artifact-root`: diretorio de evidencia.
- `--max-concurrency`: limite de slots planejados.
- `--json`: imprime o payload canonico no stdout.

## Saidas

- `symphony-kernel.json`: plano de dispatch read-only.
- `dry-run.json`: decisao de elegibilidade usada como fonte.
- `events.json`: eventos canonicos de readiness ou idle.
- `STATUS.md`: resumo operacional.
- `VALIDATION.md`: prova local.
- `HANDOFF.md`: continuidade do corte.

## Contrato

- O dry-run continua sendo a fonte de elegibilidade.
- Human Gates sao preservados em `non_dispatch`.
- Tarefas elegiveis entram em `dispatch_plan`.
- `commands_executed` deve permanecer `0`.
- `runner_execution_allowed` deve permanecer `false`.
- A concorrencia e apenas planejada; nao ha workers reais neste corte.

## Proximo Corte

`TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`

Objetivo: consumir item revisado da fila com comando explicito e ponte supervisionada plan-only por padrao.
