# HANDOFF

## Estado

TKT-030 esta concluido e pronto para revisao.

## Entrega

Fixtures canonicas de decisao humana foram geradas em:

```bash
artifacts/artemis-human-decision-fixtures/run-01/fixtures/
```

O comando gerador e:

```bash
scripts/artemis-human-decision-fixtures.sh --artifact-root artifacts/artemis-human-decision-fixtures/run-01
```

## Uso correto

- Use as fixtures para testar contrato e dry-run.
- Nao use fixtures com `--execute`.
- Nao trate `approved-exact` como aprovacao humana real.
- Casos invalidos devem falhar no contrato antes do executor.

## Proximo corte

TKT-031 deve definir o pacote de decisao humana real para os workspaces pendentes, ainda sem executar cleanup.
