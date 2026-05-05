# HANDOFF

## Estado

TKT-038 terminou em `human_gate` com `next_lane=human_must_fill_decision_record`.

## Reentrada segura

- Rerode o intake depois que o humano alterar `real-cleanup-decision.json`.
- Rerode este contrato para materializar o estado de reentrada.
- Siga para preflight futuro somente se `preflight_allowed=true`.
- Trate qualquer `pending`, `deferred`, `rejected` ou `invalid` como sem executor.

## Nao fazer

- Nao transformar este contrato em executor.
- Nao inferir aprovacao a partir de `approved_ready` sem preflight futuro.
- Nao rodar `--execute` neste corte.
- Nao remover worktrees, locks ou branches.
- Nao fazer push ou configurar remoto.

## Proximo corte

TKT-039 deve definir um preflight supervisionado pos-aprovacao que so rode quando este contrato declarar `preflight_allowed=true`.
