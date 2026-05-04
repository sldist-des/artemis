# TKT-029 - Estados de decisao no handoff de runtime

## Objetivo

Refletir decisoes humanas `deferred` e `rejected` no handoff local de runtime sem executar cleanup.

## Resultado esperado

O handoff de runtime deve diferenciar decisao aberta, decisao deferida e decisao rejeitada, preservando evidencia e evitando qualquer sugestao de cleanup automatico.

## Nivel ARTEMIS da execucao

Nivel 2 - memoria operacional e estado local.

## Agentes envolvidos

- Architect: define semantica dos estados.
- Implementer: ajusta handoff e Control Plane.
- Reviewer: valida que nao ha execucao automatica.

## Contexto minimo

- `scripts/artemis-human-cleanup-approval-contract.sh`
- `scripts/artemis-workspace-runtime-handoff.sh`
- `artifacts/artemis-human-cleanup-approval-contract/run-01/`

## Escopo

- Mapear `pending`, `deferred`, `rejected` e `approved_ready` no handoff.
- Registrar decisao humana no artifact de runtime.
- Atualizar documentacao e Control Plane se necessario.
- Manter cleanup real fora de escopo.

## Fora de escopo

- Executar cleanup.
- Fazer push.
- Fazer merge remoto.
- Resolver decisoes humanas automaticamente.

## Invariantes

- `deferred` e `rejected` nunca executam cleanup.
- Workspace rejeitado permanece no historico.
- Workspace deferido preserva proximo passo humano.
- Estado visual nao deve parecer automacao aprovada.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-workspace-runtime-handoff.sh --artifact-root artifacts/artemis-workspace-runtime-handoff/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-runtime-handoff-decision-states/run-01/STATUS.md`
- `artifacts/artemis-runtime-handoff-decision-states/run-01/VALIDATION.md`
- `artifacts/artemis-runtime-handoff-decision-states/run-01/HANDOFF.md`
