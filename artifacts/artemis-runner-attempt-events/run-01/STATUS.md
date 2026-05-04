# STATUS

## Resultado

TKT-020 instrumentou o runner supervisionado para emitir eventos canonicos de tentativa.

## Mudancas

- `scripts/artemis-runner.sh` grava `events.json` em cada tentativa.
- Tentativas plan-only emitem `runner.attempt_planned` e `runner.attempt_completed`.
- Tentativas com `--execute` tambem emitem `runner.attempt_started`.
- Eventos incluem ticket, Exec Pack, branch, worktree, comando, attempt id, workspace, logs e exit code.
- `scripts/artemis-event-log.sh` agrega eventos de tentativas a partir dos `artifact_root` declarados nas tarefas.
- Validation Gate passou a verificar eventos de tentativa do runner.

## Invariantes preservados

- Runner continua terminal-first.
- Workspace readiness continua pre-condicao.
- Eventos sao observacionais e nao editam estado canonico.
- Falha de comando gera evento com severidade `error` e estado `blocked`.
