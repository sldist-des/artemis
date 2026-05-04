# TKT-031 - Pacote de decisao humana real

## Objetivo

Preparar um pacote de decisao humana real para TKT-021, TKT-022 e TKT-023 sem executar cleanup automaticamente.

## Resultado esperado

O repositorio deve oferecer um artifact preenchivel que mostre as opcoes `approved`, `deferred` e `rejected` por workspace, com campos obrigatorios e comando de validacao claro.

## Nivel ARTEMIS da execucao

Nivel 2 - decisao humana supervisionada.

## Agentes envolvidos

- Architect: define o pacote e as opcoes.
- Reviewer: garante que execucao real permanece Human Gate.
- Memory Keeper: registra handoff e evidencias.

## Contexto minimo

- `artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json`
- `artifacts/artemis-human-decision-fixtures/run-01/`
- `scripts/artemis-human-cleanup-approval-contract.sh`
- `scripts/artemis-approved-workspace-cleanup.sh`

## Escopo

- Criar artifact preenchivel para decisoes reais.
- Documentar como validar antes de executar.
- Manter decisoes atuais como `pending`.
- Manter `--execute` fora de escopo.

## Fora de escopo

- Executar cleanup.
- Remover worktrees reais.
- Fazer push.
- Fazer merge remoto.

## Invariantes

- Decisao real exige humano, timestamp e razao.
- `approved_commands` deve ser exato.
- Sem decisao preenchida, nada executa.
- Agente nao aprova cleanup em nome do humano.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --json
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-real-cleanup-decision-package/run-01/STATUS.md`
- `artifacts/artemis-real-cleanup-decision-package/run-01/VALIDATION.md`
- `artifacts/artemis-real-cleanup-decision-package/run-01/HANDOFF.md`
