# HANDOFF

## Entrega

O metodo ARTEMIS agora tem um Workspace Manager local, read-only, para explicar readiness de worktree/branch/lock/artifact antes de qualquer runner.

O dry-run passa a mostrar workspace readiness para tarefas elegiveis. O runner supervisionado passa a exigir workspace `ready` e grava `workspace.json` em cada tentativa.

## Como usar

```bash
scripts/artemis-workspace.sh --ticket TKT-020
scripts/artemis-dry-run.sh
scripts/artemis-runner.sh --ticket TKT-020 --command "scripts/validate-artemis.sh"
```

## Proximo corte

TKT-020 deve fazer o runner supervisionado emitir eventos canonicos de tentativa: planejada, iniciada e concluida.
