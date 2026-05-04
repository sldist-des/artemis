# STATUS

## Resultado

TKT-028 formalizou o contrato de aprovacao humana para cleanup local de workspaces ARTEMIS.

## Mudancas

- `scripts/artemis-human-cleanup-approval-contract.sh` valida `cleanup-review.json` em modo read-only.
- Decisoes validas: `pending`, `approved`, `deferred` e `rejected`.
- `approved` exige `decided_by`, `decided_at`, `reason` e comandos exatamente iguais a `commands_after_approval`.
- `deferred` e `rejected` exigem metadata humana, mas nao executam cleanup.
- Aprovacao parcial nao e executavel; deve permanecer `deferred`.

## Evidencia executada

- Comando: `scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-human-cleanup-approval-contract/run-01 --json`
- Workspaces avaliados: 3.
- `pending`: 3.
- `approved_ready`: 0.
- `deferred`: 0.
- `rejected`: 0.
- `invalid`: 0.
- `execution_allowed`: 0.

## Invariantes preservados

- Nenhum cleanup foi executado.
- Nenhum push, merge ou write remoto foi feito.
- Comandos aprovados precisam ser exatos.
- Decisoes abertas continuam Human Gate.
