# HANDOFF

## Estado

TKT-029 esta pronto para revisao.

## Entrega

O handoff de runtime agora carrega a decisao humana e o estado do contrato:

```bash
scripts/artemis-workspace-runtime-handoff.sh --artifact-root artifacts/artemis-workspace-runtime-handoff/run-01
```

## Estados

- `pending`: decisao humana aberta.
- `approved_ready`: decisao valida, ainda sem execucao registrada.
- `deferred`: decisao humana adiou cleanup.
- `rejected`: decisao humana rejeitou cleanup.
- `cleaned`: executor registrou cleanup executado.
- `kept`: workspace permanece revisavel sem decisao de cleanup.
- `needs_decision`: evidencia invalida ou divergente.

## Proximo corte

TKT-030 deve criar fixtures documentadas para decisoes humanas sem tocar workspaces reais.
