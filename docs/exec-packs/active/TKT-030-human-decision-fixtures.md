# TKT-030 - Fixtures de decisao humana

## Objetivo

Criar fixtures documentadas para decisoes humanas de cleanup sem tocar workspaces reais.

## Resultado esperado

O repositorio deve ter exemplos validaveis de `approved`, `deferred`, `rejected` e casos invalidos para orientar humanos e agentes.

## Nivel ARTEMIS da execucao

Nivel 2 - contrato, teste e memoria operacional.

## Agentes envolvidos

- Architect: define casos canonicos.
- Implementer: cria fixtures e validacao.
- Reviewer: garante que fixtures nao executam cleanup real.

## Contexto minimo

- `scripts/artemis-human-cleanup-approval-contract.sh`
- `scripts/artemis-approved-workspace-cleanup.sh`
- `scripts/artemis-workspace-runtime-handoff.sh`
- `artifacts/artemis-runtime-handoff-decision-states/run-01/`

## Escopo

- Criar fixtures para decisao aprovada exata.
- Criar fixtures para decisao deferida e rejeitada.
- Criar fixtures invalidas para aprovacao parcial ou metadata ausente.
- Documentar que fixtures sao read-only e nao devem ser usadas com `--execute`.

## Fora de escopo

- Executar cleanup.
- Remover worktrees reais.
- Fazer push.
- Fazer merge remoto.

## Invariantes

- Fixtures nao podem depender de efeitos locais destrutivos.
- Executor continua dry-run por padrao.
- Fixture aprovada prova contrato, nao autoriza cleanup real.
- Fixture invalida deve falhar no contrato antes do executor.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-human-cleanup-approval-contract.sh
scripts/artemis-approved-workspace-cleanup.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-fixtures/run-01/STATUS.md`
- `artifacts/artemis-human-decision-fixtures/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-fixtures/run-01/HANDOFF.md`
