# HANDOFF

## Estado

TKT-034 esta concluido e pronto para revisao.

## Entrega

Script de consistencia:

```bash
scripts/artemis-human-decision-runbook-consistency.sh
```

Artifact da checagem:

```bash
artifacts/artemis-human-decision-runbook-consistency/run-01/RUNBOOK_CONSISTENCY.md
artifacts/artemis-human-decision-runbook-consistency/run-01/runbook-consistency.json
```

## Uso correto

- Rode a checagem depois de alterar `real-cleanup-decision.json` ou o runbook.
- Trate qualquer blocker como falha de documentacao/contrato.
- Nao use exemplos como autorizacao.
- Cleanup real continua fora deste TKT.

## Proximo corte

TKT-035 deve consolidar o pacote de decisao humana em um checkpoint de release local, reunindo runbook, consistencia, Control Plane e Validation Gate.
