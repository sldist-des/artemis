# TKT-033 - Runbook assistido de decisao humana

## Objetivo

Criar um runbook assistido para o humano preencher `real-cleanup-decision.json` com seguranca, sem executar cleanup.

## Resultado esperado

O repositorio deve explicar como escolher `approved`, `deferred` ou `rejected` por workspace, como copiar comandos exatos quando houver aprovacao e como validar o arquivo preenchido.

## Nivel ARTEMIS da execucao

Nivel 2 - decisao humana supervisionada.

## Agentes envolvidos

- Architect: define criterio de decisao e limites.
- Reviewer: garante que o runbook nao autoriza execucao automatica.
- Memory Keeper: registra evidencias e handoff.

## Contexto minimo

- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`
- `artifacts/artemis-control-plane-real-cleanup-human-gate/run-01/`
- `scripts/artemis-human-cleanup-approval-contract.sh`
- `scripts/artemis-approved-workspace-cleanup.sh`

## Escopo

- Documentar criterio para `approved`, `deferred` e `rejected`.
- Mostrar campos obrigatorios e formato de timestamp.
- Mostrar comandos de validacao do contrato e dry-run.
- Manter `--execute` fora de escopo.

## Fora de escopo

- Preencher decisao pelo agente.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push ou merge remoto.

## Invariantes

- Agente nao decide em nome do humano.
- Aprovacao exige comandos exatos.
- Decisao parcial deve ser `deferred`.
- Sem validacao, nada avanca para executor.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --json
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-assisted-human-decision-runbook/run-01/STATUS.md`
- `artifacts/artemis-assisted-human-decision-runbook/run-01/VALIDATION.md`
- `artifacts/artemis-assisted-human-decision-runbook/run-01/HANDOFF.md`
