# HANDOFF

## Entrega

O ARTEMIS agora consegue materializar um workspace local com comando explicito.

O workspace de TKT-021 foi criado e esta bloqueando reentradas por lock/worktree/branch ocupados, como esperado.

## Evidencia principal

```text
artifacts/artemis-workspace-materialization/run-01/materialization.json
artifacts/artemis-workspace-materialization/run-01/MATERIALIZATION.md
.artemis/locks/tkt-021.lock
../veri-artemis-worktrees/tkt-021
```

## Como usar

```bash
scripts/artemis-workspace.sh --ticket <ticket-ready> --artifact-root <artifact-root> --materialize
```

## Cleanup

Nao ha cleanup automatico neste corte. Antes de remover:

- revisar o worktree;
- garantir que nao ha trabalho util nao versionado;
- remover worktree e lock somente por decisao humana.

## Proximo corte

TKT-022 deve fazer o runner executar comandos dentro do workspace materializado, mantendo terminal-first, readiness, eventos de tentativa e validacao.
