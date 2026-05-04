# HANDOFF

## Estado

TKT-035 esta concluido como checkpoint local read-only do pacote de decisao humana.

## Usar este pacote para

- Revisar as evidencias antes de preencher `real-cleanup-decision.json`.
- Confirmar que runbook, consistencia, Control Plane e Validation Gate estao alinhados.
- Decidir, manualmente, se cada workspace deve ser `approved`, `deferred` ou `rejected` em etapa futura.

## Nao usar este pacote para

- Autorizar cleanup.
- Rodar `--execute`.
- Remover worktrees, branches ou locks.
- Fazer push ou configurar GitHub remoto.

## Proximo corte

TKT-036 deve criar o intake supervisionado da decisao humana preenchida, ainda read-only, antes de qualquer executor de cleanup.
