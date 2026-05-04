# TKT-028 - Contrato de aprovacao humana para cleanup

## Objetivo

Formalizar o contrato minimo de aprovacao humana que permite um workspace sair de `pending` no fluxo de cleanup local.

## Resultado esperado

Um artifact ou schema deve deixar claro como registrar `approved`, `deferred` ou `rejected`, quais campos sao obrigatorios e como o executor valida que os comandos aprovados sao exatamente os esperados.

## Nivel ARTEMIS da execucao

Nivel 2 - contrato de decisao humana.

## Agentes envolvidos

- Architect: define contrato e invariantes.
- Reviewer: valida riscos de aprovacao parcial.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `artifacts/artemis-workspace-cleanup-review/run-01/DECISION_TEMPLATE.md`
- `scripts/artemis-approved-workspace-cleanup.sh`
- `artifacts/artemis-workspace-runtime-handoff/run-01/`

## Escopo

- Definir campos obrigatorios da aprovacao.
- Definir estados validos de decisao.
- Documentar como aprovar todos ou parte dos comandos.
- Manter execucao real fora de escopo.

## Fora de escopo

- Executar cleanup.
- Fazer push.
- Fazer merge remoto.
- Resolver decisoes humanas automaticamente.

## Invariantes

- Aprovacao exige identidade, timestamp e razao.
- Comandos aprovados devem ser exatos.
- Decisao parcial mantem o workspace pendente.
- Decisao sem comandos validos nao executa.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-approved-workspace-cleanup/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-cleanup-approval-contract/run-01/STATUS.md`
- `artifacts/artemis-human-cleanup-approval-contract/run-01/VALIDATION.md`
- `artifacts/artemis-human-cleanup-approval-contract/run-01/HANDOFF.md`
