# TKT-036 - Intake supervisionado da decisao humana preenchida

## Objetivo

Criar uma etapa read-only para receber uma versao preenchida de `real-cleanup-decision.json`, validar o contrato humano e gerar evidencias antes de qualquer executor de cleanup.

## Resultado esperado

O repositorio deve ter um artifact que diga se uma decisao humana preenchida esta pronta, deferida, rejeitada ou bloqueada, sem executar comandos de cleanup.

## Nivel ARTEMIS da execucao

Nivel 1 - validacao read-only.

## Agentes envolvidos

- Reviewer: valida contrato, riscos e blockers.
- Memory Keeper: consolida evidencias de intake.
- Architect: define o corte seguinte para executor ou novo Human Gate.

## Contexto minimo

- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`
- `artifacts/artemis-human-decision-release-checkpoint/run-01/`
- `scripts/artemis-human-cleanup-approval-contract.sh`
- `scripts/artemis-approved-workspace-cleanup.sh`

## Escopo

- Validar uma decisao humana preenchida em modo read-only.
- Registrar status por workspace.
- Confirmar se ha `approved_ready`, `deferred`, `rejected`, `pending` ou `invalid`.
- Produzir handoff claro antes de qualquer executor.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push, PR, merge remoto ou configurar GitHub.

## Invariantes

- Intake nao e executor.
- Sem `--execute`.
- Aprovacao parcial continua invalida.
- Decisao humana real continua canonica.
- Remote writes continuam Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-intake/run-01/STATUS.md`
- `artifacts/artemis-human-decision-intake/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-intake/run-01/HANDOFF.md`
