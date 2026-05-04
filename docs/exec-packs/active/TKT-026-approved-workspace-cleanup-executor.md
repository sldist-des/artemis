# TKT-026 - Executor local de cleanup aprovado

## Objetivo

Definir se ARTEMIS deve ter um executor local de cleanup que rode apenas comandos aprovados explicitamente em artifact de decisao humana.

## Resultado esperado

Um comando deve conseguir validar uma decisao humana preenchida e, somente quando aprovado, executar cleanup local de worktree, lock e branch com dry-run e evidencia. O padrao deve continuar read-only.

## Nivel ARTEMIS da execucao

Nivel 3 - operacao local destrutiva com Human Gate explicito.

## Agentes envolvidos

- Architect: define limites do executor.
- Reviewer: valida seguranca dos comandos permitidos.
- Implementer: cria ou recusa executor conforme risco.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `scripts/artemis-workspace-cleanup-review.sh`
- `artifacts/artemis-workspace-cleanup-review/run-01/`
- `docs/workspaces/artemis-workspace-cleanup-review.md`
- `.artemis/locks/`
- `git worktree list --porcelain`

## Escopo

- Validar formato de decisao humana.
- Definir dry-run obrigatorio.
- Permitir somente comandos locais e esperados.
- Registrar resultado em artifact.

## Fora de escopo

- Push.
- Merge remoto.
- PR.
- Cleanup sem decisao humana.
- Forcar remocao de worktree sujo.

## Invariantes

- `pending` nunca executa.
- `deferred` nunca executa.
- Comando fora da allowlist nunca executa.
- Execucao real exige flag explicita.
- GitHub remoto continua Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-workspace-cleanup-review.sh --artifact-root artifacts/artemis-workspace-cleanup-review/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-approved-workspace-cleanup/run-01/STATUS.md`
- `artifacts/artemis-approved-workspace-cleanup/run-01/VALIDATION.md`
- `artifacts/artemis-approved-workspace-cleanup/run-01/HANDOFF.md`
