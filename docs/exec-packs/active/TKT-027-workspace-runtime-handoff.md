# TKT-027 - Handoff de runtime local de workspaces

## Objetivo

Definir como ARTEMIS registra que workspaces locais foram limpos, mantidos ou deixados pendentes depois de uma decisao humana.

## Resultado esperado

Um artifact deve mostrar o estado final local de cada workspace apos a revisao ou execucao de cleanup: `cleaned`, `kept`, `pending` ou `needs_decision`, sem depender de memoria implicita em `.artemis/`.

## Nivel ARTEMIS da execucao

Nivel 2 - handoff local e evidencia.

## Agentes envolvidos

- Architect: define estados finais.
- Reviewer: valida consistencia com locks, worktrees e branches.
- Memory Keeper: registra artifacts de handoff.

## Contexto minimo

- `scripts/artemis-approved-workspace-cleanup.sh`
- `scripts/artemis-workspace-lifecycle.sh`
- `artifacts/artemis-approved-workspace-cleanup/run-01/`
- `artifacts/artemis-workspace-lifecycle/run-01/`

## Escopo

- Definir estados finais de runtime local.
- Registrar artifact de handoff pos-revisao.
- Manter workspaces pendentes visiveis.
- Documentar como o Control Plane deve exibir cleanup local.

## Fora de escopo

- Executar cleanup.
- Fazer push.
- Fazer merge remoto.
- Apagar memoria local sem registro.

## Invariantes

- `.artemis/` e runtime local, nao fonte canonica unica.
- Artifacts continuam memoria duravel.
- Workspace mantido continua aparecendo no inventario.
- Workspace removido precisa aparecer em handoff.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-approved-workspace-cleanup/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-workspace-runtime-handoff/run-01/STATUS.md`
- `artifacts/artemis-workspace-runtime-handoff/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-runtime-handoff/run-01/HANDOFF.md`
