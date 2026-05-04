# TKT-021 - Materializar workspace ARTEMIS controlado

## Objetivo

Permitir que ARTEMIS crie branch, worktree e lock local de forma explicita, auditavel e reversivel.

## Resultado esperado

Um comando local deve materializar o workspace planejado apenas quando readiness estiver `ready`, criando worktree e lock com evidencia, sem iniciar agentes automaticamente.

## Nivel ARTEMIS da execucao

Nivel 3 - side effect local controlado.

## Agentes envolvidos

- Architect: define limites de criacao e limpeza.
- Implementer: adiciona modo de materializacao.
- Reviewer: valida conflitos, locks e Human Gates.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `scripts/artemis-workspace.sh`
- `scripts/artemis_workspace_common.py`
- `scripts/artemis-runner.sh`
- `docs/workspaces/artemis-workspace-manager.md`
- `artifacts/artemis-workspace-manager/run-01/`

## Escopo

- Criar branch/worktree local apenas com flag explicita.
- Criar lock local em `.artemis/locks/`.
- Registrar artifact de workspace criado.
- Bloquear quando worktree, lock ou branch ocupada exigir decisao humana.
- Documentar limpeza/abandono sem automatizar destruicao.

## Fora de escopo

- Push, merge ou PR.
- Iniciar Codex/Claude automaticamente.
- Remover worktrees automaticamente.
- Resolver conflitos automaticamente.
- Alterar remoto ou branch protection.

## Invariantes

- Um agente escritor por worktree.
- Comando destrutivo continua Human Gate.
- Lock local nao e fonte canonica; Git/artifacts/handoff continuam canonicos.
- Workspace materializado nao implica Done.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-workspace.sh --ticket TKT-021 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-workspace-materialization/run-01/STATUS.md`
- `artifacts/artemis-workspace-materialization/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-materialization/run-01/HANDOFF.md`
