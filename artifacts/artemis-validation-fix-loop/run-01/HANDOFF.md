# HANDOFF

## Entrega

O ARTEMIS agora tem um loop auditavel de tentativa falha e retry/fix no workspace isolado.

## Evidencia principal

```text
artifacts/artemis-validation-fix-loop/run-01/attempts/20260504T141956Z-2-tkt-023/events.json
artifacts/artemis-validation-fix-loop/run-01/attempts/20260504T142001Z-2-tkt-023/events.json
```

## Como usar

```bash
scripts/artemis-runner.sh --ticket <ticket> --command "<validation>" --execute --use-workspace --attempt-purpose validation --artifact-root <artifact-root>
scripts/artemis-runner.sh --ticket <ticket> --command "<fix-or-retry>" --execute --use-workspace --attempt-purpose retry --retry-of <attempt-id> --artifact-root <artifact-root>
```

## Proximo corte

TKT-024 deve registrar inventario e lifecycle dos workspaces locais, incluindo quais estao ativos, quais podem ser revisados e quais exigem decisao humana antes de limpeza.
