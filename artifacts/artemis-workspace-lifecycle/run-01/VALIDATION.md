# VALIDATION

## Validacoes

- `scripts/artemis-workspace-lifecycle.sh --artifact-root artifacts/artemis-workspace-lifecycle/run-01 --json`: passou.
- `sh -n scripts/artemis-workspace-lifecycle.sh`: passou.
- `git diff --check`: passou apos a implementacao inicial.
- Control Plane smoke em Chrome headless: `/tmp/artemis-tkt024-control-plane.png`.

## Resultado do inventario

- TKT-021: `review_ready`.
- TKT-022: `review_ready`.
- TKT-023: `review_ready`.

## Criterio aplicado

Um workspace so entra em `review_ready` quando:

- lock existe e e legivel;
- branch local existe;
- worktree existe e esta registrado no Git;
- artifact root existe e contem `STATUS.md`;
- worktree esta limpo;
- branch ja e ancestral do `HEAD` atual.

## Gaps

- Nenhum cleanup foi executado.
- Nenhum push, merge remoto ou PR foi executado.
- A decisao de remover worktrees/locks foi adiada para TKT-025.
