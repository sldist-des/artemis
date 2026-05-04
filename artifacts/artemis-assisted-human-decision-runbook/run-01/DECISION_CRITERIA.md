# DECISION CRITERIA

## TKT-021

Titulo: Materializar workspace ARTEMIS controlado

Evidencias a revisar:

- `artifacts/artemis-workspace-materialization/run-01/STATUS.md`
- `artifacts/artemis-workspace-materialization/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-materialization/run-01/HANDOFF.md`
- `.artemis/locks/tkt-021.lock`
- `../veri-artemis-worktrees/tkt-021`
- `artemis/tkt-021-materializar-workspace-artemis-contr`

Comandos que devem ser copiados exatamente se a decisao humana for `approved`:

```json
[
  "git worktree remove ../veri-artemis-worktrees/tkt-021",
  "rm .artemis/locks/tkt-021.lock",
  "git branch -d artemis/tkt-021-materializar-workspace-artemis-contr"
]
```

## TKT-022

Titulo: Executar runner no workspace materializado

Evidencias a revisar:

- `artifacts/artemis-runner-workspace-execution/run-01/STATUS.md`
- `artifacts/artemis-runner-workspace-execution/run-01/VALIDATION.md`
- `artifacts/artemis-runner-workspace-execution/run-01/HANDOFF.md`
- `.artemis/locks/tkt-022.lock`
- `../veri-artemis-worktrees/tkt-022`
- `artemis/tkt-022-executar-runner-no-workspace-materia`

Comandos que devem ser copiados exatamente se a decisao humana for `approved`:

```json
[
  "git worktree remove ../veri-artemis-worktrees/tkt-022",
  "rm .artemis/locks/tkt-022.lock",
  "git branch -d artemis/tkt-022-executar-runner-no-workspace-materia"
]
```

## TKT-023

Titulo: Loop de validacao e fix em workspace isolado

Evidencias a revisar:

- `artifacts/artemis-validation-fix-loop/run-01/STATUS.md`
- `artifacts/artemis-validation-fix-loop/run-01/VALIDATION.md`
- `artifacts/artemis-validation-fix-loop/run-01/HANDOFF.md`
- `.artemis/locks/tkt-023.lock`
- `../veri-artemis-worktrees/tkt-023`
- `artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`

Comandos que devem ser copiados exatamente se a decisao humana for `approved`:

```json
[
  "git worktree remove ../veri-artemis-worktrees/tkt-023",
  "rm .artemis/locks/tkt-023.lock",
  "git branch -d artemis/tkt-023-loop-de-validacao-e-fix-em-workspace"
]
```

## Criterio de falha

Nao use `approved` se:

- qualquer comando for removido, editado ou reordenado;
- qualquer evidencia obrigatoria nao tiver sido revisada;
- houver duvida sobre branch, worktree ou lock;
- a decisao for parcial.

Nesses casos, use `deferred` com uma razao clara.
