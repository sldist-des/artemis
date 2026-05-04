# HANDOFF

## Estado

TKT-025 esta pronto para revisao.

## Entrega

O repositorio agora tem um protocolo e um comando para preparar a decisao humana antes de cleanup local:

```bash
scripts/artemis-workspace-cleanup-review.sh --artifact-root artifacts/artemis-workspace-cleanup-review/run-01
```

## Decisao pendente

`DECISION_TEMPLATE.md` permanece com decisao `pending` para TKT-021, TKT-022 e TKT-023. Isso bloqueia qualquer cleanup ate que um humano aprove explicitamente comandos locais.

## Proximo corte

TKT-026 deve decidir se havera um executor local que rode apenas comandos ja aprovados no artifact de decisao humana.
