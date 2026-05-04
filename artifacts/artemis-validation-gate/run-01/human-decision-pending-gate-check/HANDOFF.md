# HANDOFF

## Estado

TKT-037 esta em `human_gate` porque `3` decisoes humanas continuam pendentes.

## Reentrada segura

- Open artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md.
- Edit artifacts/artemis-validation-gate/run-01/real-cleanup-decision-package-check/real-cleanup-decision.json only as the human decision record.
- For approved decisions, copy every expected command exactly and in order.
- For partial or uncertain approval, choose deferred with a reason.
- Run the validation commands before any executor is considered.
- Only after a later intake reports approved_ready should an executor preflight be planned.

## Nao fazer

- Nao executar cleanup enquanto houver `pending`.
- Nao preencher decisao humana como agente.
- Nao rodar `--execute`.
- Nao remover worktrees, locks ou branches.
- Nao fazer push ou configurar GitHub remoto.

## Proximo corte

TKT-038 deve documentar a reentrada apos preenchimento humano ou permanecer bloqueado ate o humano fornecer a decisao real.
