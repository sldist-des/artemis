# TKT-032 - Control Plane para decisao real de cleanup

## Objetivo

Expor no ARTEMIS Control Plane o estado do pacote real de decisao humana de cleanup sem sugerir execucao automatica.

## Resultado esperado

O Control Plane deve mostrar que TKT-021, TKT-022 e TKT-023 ainda estao em `pending`, com evidencia do pacote real e Human Gate explicito.

## Nivel ARTEMIS da execucao

Nivel 1 - melhoria visual e operacional read-only.

## Agentes envolvidos

- Designer: define como mostrar Human Gate sem parecer CTA de execucao.
- Implementer: atualiza fonte de tarefas/eventos/control plane.
- Reviewer: valida que nenhum fluxo sugere `--execute`.

## Contexto minimo

- `artifacts/artemis-real-cleanup-decision-package/run-01/`
- `control-plane/index.html`
- `control-plane/tasks.json`
- `scripts/artemis-tasks.sh`
- `scripts/validate-artemis.sh`

## Escopo

- Mostrar pacote real como evidencia de decisao pendente.
- Deixar claro que cleanup real depende de humano.
- Validar responsividade/smoke visual se a UI mudar.
- Manter execucao real fora de escopo.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push ou merge remoto.

## Invariantes

- Control Plane nao e fonte canonica.
- Human Gate nao vira botao de execucao.
- `real-cleanup-decision.json` continua pendente ate humano preencher.
- Validacao continua obrigatoria antes de qualquer executor.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-real-cleanup-decision-package.sh --source artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-real-cleanup-decision-package/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-real-cleanup-human-gate/run-01/STATUS.md`
- `artifacts/artemis-control-plane-real-cleanup-human-gate/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-real-cleanup-human-gate/run-01/HANDOFF.md`
