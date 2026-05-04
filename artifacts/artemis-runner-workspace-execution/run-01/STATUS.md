# STATUS

## Resultado

TKT-022 fez o runner supervisionado executar uma tentativa dentro do worktree materializado.

## Mudancas

- `scripts/artemis-runner.sh` ganhou `--use-workspace`.
- `--use-workspace` exige `--execute`.
- O runner valida lock/worktree materializados antes de executar.
- O runner bloqueia quando o lock nao pertence ao ticket.
- `ENVIRONMENT.md`, `RESULT.md` e `events.json` registram o `execution_cwd`.
- Eventos de tentativa incluem `use_workspace=true` no payload.

## Evidencia executada

- Attempt: `artifacts/artemis-runner-workspace-execution/run-01/attempts/20260504T140934Z-2-tkt-022`
- Command: `pwd`
- Output: `/srv/veri-artemis-worktrees/tkt-022`

## Invariantes preservados

- Runner continua terminal-first.
- Nenhum agente e iniciado automaticamente.
- Comandos remotos, destrutivos e deploy continuam bloqueados.
- Workspace materializado nao implica Done.
- Cleanup automatico continua fora de escopo.
