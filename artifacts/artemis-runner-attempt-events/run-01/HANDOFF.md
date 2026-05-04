# HANDOFF

## Entrega

O runner supervisionado agora registra eventos canonicos por tentativa.

O event log agregado tambem passa a consumir `attempts/*/events.json` a partir dos `artifact_root` declarados nas tarefas.

## Evidencia principal

```text
artifacts/artemis-runner-attempt-events/run-01/attempts/20260504T134153Z-2-tkt-020/events.json
artifacts/artemis-runner-attempt-events/run-01/attempts/20260504T134653Z-2-tkt-021/events.json
```

## Como usar

```bash
scripts/artemis-runner.sh --ticket <ticket-ready> --command "scripts/artemis-dry-run.sh"
scripts/artemis-runner.sh --ticket <ticket-ready> --command "scripts/artemis-dry-run.sh" --execute
```

Depois que um ticket vira `done`, o runner bloqueia novas tentativas para esse ticket pela readiness do workspace.

## Proximo corte

TKT-021 deve materializar workspaces de forma controlada: criar branch/worktree/lock somente com flag explicita e mantendo Human Gate para conflitos.
