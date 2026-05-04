# HANDOFF

## Estado

TKT-033 esta concluido e pronto para revisao.

## Entrega

Runbook principal:

```bash
artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md
```

Criterios por workspace:

```bash
artifacts/artemis-assisted-human-decision-runbook/run-01/DECISION_CRITERIA.md
```

Exemplos de preenchimento:

```bash
artifacts/artemis-assisted-human-decision-runbook/run-01/HUMAN_DECISION_EXAMPLES.md
```

## Uso correto

- Humano revisa evidencias e escolhe uma decisao por workspace.
- Agente pode validar formato, mas nao decidir.
- `approved` exige comandos exatos.
- `deferred` deve ser usado para aprovacao parcial ou duvida.
- `--execute` continua fora deste TKT.

## Proximo corte

TKT-034 deve criar uma checagem de consistencia do runbook contra `real-cleanup-decision.json`, garantindo que exemplos e comandos documentados nao divergem do pacote real.
