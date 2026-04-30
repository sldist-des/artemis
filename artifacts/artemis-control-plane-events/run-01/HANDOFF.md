# HANDOFF

## Entrega

O Control Plane agora mostra uma timeline read-only alimentada por `artifacts/artemis-event-log-schema/run-01/event-log.example.json` quando servido por HTTP.

O fallback local tambem foi atualizado para refletir TKT-018 como done e TKT-019 como ready.

## Como usar

```bash
scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json
python3 -m http.server 8123
```

Abrir `http://127.0.0.1:8123/control-plane/`.

## Proximo corte

TKT-019 deve definir o Workspace Manager ARTEMIS: contrato local para worktrees, branches, locks, artifacts e limpeza antes de automatizar execucao paralela.
