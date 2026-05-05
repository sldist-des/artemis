# TKT-039 - Preflight supervisionado pos-aprovacao humana

## Objetivo

Definir uma checagem read-only que consome o contrato de reentrada e prepara o caminho de preflight somente quando houver `preflight_allowed=true`.

## Resultado esperado

O repositorio deve ter um artifact que confirme se a decisao preenchida pode seguir para um preflight supervisionado futuro, sem executar cleanup.

## Nivel ARTEMIS da execucao

Nivel 1 - contrato read-only.

## Agentes envolvidos

- Reviewer: valida que preflight nao vira executor.
- Architect: separa preflight, executor e handoff.
- Memory Keeper: registra evidencias e comandos de retorno.

## Contexto minimo

- `artifacts/artemis-human-decision-reentry-contract/run-01/`
- `artifacts/artemis-human-decision-intake/run-01/`
- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`

## Escopo

- Consumir o contrato de reentrada.
- Definir criterios de entrada para preflight futuro.
- Confirmar parada quando houver `pending`, `deferred`, `rejected` ou `invalid`.
- Manter executor fora deste corte.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push, PR, merge ou configurar servicos externos.

## Invariantes

- Preflight nao e executor.
- `preflight_allowed=true` exige decisao humana previamente validada.
- Qualquer estado diferente de `approved_ready` permanece sem executor.
- Sem `--execute`.
- Escritas externas continuam Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-post-human-approval-preflight/run-01/STATUS.md`
- `artifacts/artemis-post-human-approval-preflight/run-01/VALIDATION.md`
- `artifacts/artemis-post-human-approval-preflight/run-01/HANDOFF.md`
