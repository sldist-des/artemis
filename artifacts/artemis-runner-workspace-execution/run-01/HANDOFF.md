# HANDOFF

## Entrega

O runner supervisionado agora pode executar comandos dentro do worktree materializado quando `--use-workspace` e usado junto com `--execute`.

## Evidencia principal

```text
artifacts/artemis-runner-workspace-execution/run-01/attempts/20260504T140934Z-2-tkt-022/COMMAND.txt
artifacts/artemis-runner-workspace-execution/run-01/attempts/20260504T140934Z-2-tkt-022/ENVIRONMENT.md
artifacts/artemis-runner-workspace-execution/run-01/attempts/20260504T140934Z-2-tkt-022/events.json
```

## Como usar

```bash
scripts/artemis-workspace.sh --ticket <ticket-ready> --artifact-root <artifact-root> --materialize
scripts/artemis-runner.sh --ticket <ticket> --command "<cmd>" --execute --use-workspace --artifact-root <artifact-root>
```

## Proximo corte

TKT-023 deve formalizar o loop validacao/fix/retry em workspace isolado, incluindo falhas bloqueadas, nova tentativa e handoff final.
