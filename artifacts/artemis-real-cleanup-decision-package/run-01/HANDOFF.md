# HANDOFF

## Estado

TKT-031 esta concluido e pronto para revisao.

## Entrega

Pacote real preenchivel:

```bash
artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json
```

Documentacao do pacote:

```bash
artifacts/artemis-real-cleanup-decision-package/run-01/REAL_CLEANUP_DECISION_PACKAGE.md
artifacts/artemis-real-cleanup-decision-package/run-01/REAL_CLEANUP_DECISION_TEMPLATE.md
artifacts/artemis-real-cleanup-decision-package/run-01/REAL_CLEANUP_DECISION_CHECKLIST.md
```

## Uso correto

- Humano preenche `decision_record` por workspace.
- `approved` exige `decided_by`, `decided_at`, `reason` e comandos exatos.
- `deferred` e `rejected` exigem metadata e deixam `approved_commands` vazio.
- Rode o contrato e o dry-run antes de considerar qualquer execucao.

## Proximo corte

TKT-032 deve expor o estado do pacote real de decisao no Control Plane, mantendo cleanup real atras de Human Gate.
