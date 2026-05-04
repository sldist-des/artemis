# TKT-025 - Revisao manual de cleanup de workspaces

## Objetivo

Definir o procedimento ARTEMIS para revisar e limpar worktrees, branches locais e locks depois do inventario de lifecycle.

## Resultado esperado

Um humano deve conseguir decidir se um workspace `review_ready` pode ser removido localmente, quais evidencias precisam existir antes da remocao e como registrar a decisao sem automatizar cleanup.

## Nivel ARTEMIS da execucao

Nivel 2 - procedimento local com decisao humana.

## Agentes envolvidos

- Architect: define estados e criterios de cleanup.
- Reviewer: valida riscos de remover worktree, branch local ou lock.
- Memory Keeper: registra decisao e evidencias.

## Contexto minimo

- `scripts/artemis-workspace-lifecycle.sh`
- `artifacts/artemis-workspace-lifecycle/run-01/`
- `.artemis/locks/`
- `git worktree list --porcelain`

## Escopo

- Documentar checklist de revisao antes de cleanup.
- Definir quando `review_ready` vira aprovado para remocao local.
- Definir artifact de decisao humana.
- Manter cleanup automatico fora de escopo.

## Fora de escopo

- Remover worktrees automaticamente.
- Apagar locks automaticamente.
- Apagar branches automaticamente.
- Fazer push, merge remoto ou PR.
- Resolver workspaces sujos automaticamente.

## Invariantes

- Nenhum cleanup sem decisao humana explicita.
- Workspace sujo exige parada.
- Branch nao integrada exige parada.
- Artifact de handoff vence inferencia local.
- Git continua memoria duravel.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-workspace-lifecycle.sh --artifact-root artifacts/artemis-workspace-lifecycle/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-workspace-cleanup-review/run-01/STATUS.md`
- `artifacts/artemis-workspace-cleanup-review/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-cleanup-review/run-01/HANDOFF.md`
