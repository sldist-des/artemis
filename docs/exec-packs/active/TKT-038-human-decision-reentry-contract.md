# TKT-038 - Contrato de reentrada apos decisao humana

## Objetivo

Definir o caminho seguro de reentrada depois que o humano preencher `real-cleanup-decision.json`, sem executar cleanup automaticamente.

## Resultado esperado

O repositorio deve ter um artifact que diga quais validacoes rodar, quais estados liberam preflight futuro e quais estados permanecem sem executor.

## Nivel ARTEMIS da execucao

Nivel 1 - contrato read-only.

## Agentes envolvidos

- Reviewer: valida que reentrada nao pula Human Gate.
- Memory Keeper: consolida comandos e evidencias de retorno.
- Architect: separa reentrada, preflight e executor.

## Contexto minimo

- `artifacts/artemis-human-decision-pending-gate/run-01/`
- `artifacts/artemis-human-decision-intake/run-01/`
- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`
- `artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md`

## Escopo

- Registrar o fluxo de reentrada depois do preenchimento humano.
- Definir estados aceitos para seguir para preflight.
- Definir estados que permanecem em Human Gate.
- Confirmar que executor continua fora deste corte.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push, PR, merge remoto ou configurar GitHub.

## Invariantes

- Reentrada nao e executor.
- `approved_ready` nao executa cleanup sozinho.
- `pending`, `deferred`, `rejected` e `invalid` nao seguem para executor.
- Sem `--execute`.
- Remote writes continuam Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-reentry-contract/run-01/STATUS.md`
- `artifacts/artemis-human-decision-reentry-contract/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-reentry-contract/run-01/HANDOFF.md`
