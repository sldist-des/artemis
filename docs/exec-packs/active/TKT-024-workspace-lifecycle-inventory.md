# TKT-024 - Inventario e lifecycle de workspaces ARTEMIS

## Objetivo

Criar um inventario local dos workspaces ARTEMIS materializados e do seu estado de lifecycle.

## Resultado esperado

Um comando local deve listar worktrees, branches, locks e artifact roots ARTEMIS, mostrando quais estao ativos, quais estao prontos para revisao humana e quais precisam de decisao antes de limpeza.

## Nivel ARTEMIS da execucao

Nivel 2 - diagnostico local read-only.

## Agentes envolvidos

- Architect: define estados de lifecycle.
- Implementer: cria comando de inventario.
- Reviewer: valida locks, worktrees e artifacts.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `scripts/artemis-workspace.sh`
- `scripts/artemis_workspace_common.py`
- `.artemis/locks/`
- `artifacts/artemis-workspace-materialization/run-01/`
- `artifacts/artemis-runner-workspace-execution/run-01/`
- `artifacts/artemis-validation-fix-loop/run-01/`

## Escopo

- Listar locks ARTEMIS locais.
- Relacionar lock com branch, worktree e artifact root.
- Mostrar existencia de worktree e branch local.
- Registrar artifact de inventario.
- Documentar criterios de revisao antes de limpeza.

## Fora de escopo

- Remover worktrees.
- Apagar locks.
- Fazer push, merge ou PR.
- Resolver conflitos automaticamente.
- Iniciar agentes.

## Invariantes

- Inventario e read-only.
- Cleanup automatico continua fora de escopo.
- Lock local nao e fonte canonica unica; artifacts e Git continuam memoria duravel.
- Decisao humana vence quando ha trabalho nao versionado, divergencia de branch ou escopo em aberto.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
git worktree list --porcelain
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-workspace-lifecycle/run-01/STATUS.md`
- `artifacts/artemis-workspace-lifecycle/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-lifecycle/run-01/HANDOFF.md`
