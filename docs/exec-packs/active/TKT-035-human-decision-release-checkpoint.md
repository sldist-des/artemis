# TKT-035 - Checkpoint local do pacote de decisao humana

## Objetivo

Consolidar o pacote de decisao humana de cleanup em um checkpoint local de release, reunindo runbook, consistencia, Control Plane e Validation Gate.

## Resultado esperado

O repositorio deve ter um artifact que mostre que a camada de decisao humana esta pronta para uso supervisionado, ainda sem executar cleanup.

## Nivel ARTEMIS da execucao

Nivel 1 - consolidacao read-only.

## Agentes envolvidos

- Reviewer: valida completude e riscos residuais.
- Memory Keeper: consolida evidencias.
- Architect: define proximos cortes.

## Contexto minimo

- `artifacts/artemis-real-cleanup-decision-package/run-01/`
- `artifacts/artemis-assisted-human-decision-runbook/run-01/`
- `artifacts/artemis-human-decision-runbook-consistency/run-01/`
- `artifacts/artemis-control-plane-real-cleanup-human-gate/run-01/`
- `artifacts/artemis-validation-gate/run-01/`

## Escopo

- Consolidar evidencias.
- Registrar riscos residuais.
- Confirmar que cleanup real continua Human Gate.
- Definir proximo corte depois do pacote de decisao humana.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push ou merge remoto.

## Invariantes

- Release local nao e autorizacao de cleanup.
- Decisao humana real continua pendente.
- Validacao precede qualquer executor.
- Remote writes continuam Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-release-checkpoint/run-01/STATUS.md`
- `artifacts/artemis-human-decision-release-checkpoint/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-release-checkpoint/run-01/HANDOFF.md`
