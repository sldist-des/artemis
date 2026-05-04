# HANDOFF

## Estado

TKT-028 esta pronto para revisao.

## Entrega

O contrato de decisao humana agora e validavel antes do executor:

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-human-cleanup-approval-contract/run-01
```

## Regras operacionais

- `pending` mantem Human Gate aberto.
- `approved` so e executavel com metadata completa e comandos exatos.
- `deferred` registra uma decisao humana de adiar sem executar.
- `rejected` registra uma decisao humana de rejeitar cleanup sem executar.
- Aprovacao parcial nao executa.

## Proximo corte

TKT-029 deve refletir `deferred` e `rejected` no handoff de runtime e no Control Plane sem sugerir execucao automatica.
