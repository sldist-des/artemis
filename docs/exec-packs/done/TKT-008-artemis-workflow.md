# TKT-008 - Criar ARTEMIS_WORKFLOW.md

## Objetivo

Criar o contrato operacional do metodo ARTEMIS antes de implementar task source, dry-run ou runners.

## Resultado esperado

`ARTEMIS_WORKFLOW.md` deve permitir que humano, Codex e Claude entendam quando uma tarefa pode ser executada, quando deve parar, como validar e quando escalar.

## Nivel ARTEMIS da execucao

Nivel 0 - documentacao operacional e governanca local.

## Agentes envolvidos

- Context Curator: organiza estados, gates e runners.
- Implementer: cria o documento e ajusta referencias.
- Reviewer: valida que o contrato cobre dispatch, parada, evidencia e escalonamento.
- Memory Keeper: registra artifacts e handoff.

## Contexto minimo

- `AGENTS.md`
- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `docs/principles/artemis-principles.md`
- `control-plane/index.html`

## Escopo

- Criar `ARTEMIS_WORKFLOW.md`.
- Registrar estados oficiais.
- Definir elegibilidade, dispatch, parada, validacao, evidencia e escalonamento humano.
- Atualizar validacao local para exigir o workflow.
- Atualizar Control Plane estatico para refletir TKT-008 e proximo TKT-009.
- Registrar artifacts.

## Fora de escopo

- Implementar daemon.
- Implementar task source JSON.
- Iniciar agentes automaticamente.
- Integrar GitHub Issues.
- Integrar Codex app-server ou Claude Code headless.

## Invariantes

- Terminal continua soberano.
- Control Plane nao e fonte de verdade.
- Exec Packs e artifacts continuam canonicos.
- Push e configuracoes remotas continuam Human Gate.
- Nao introduzir dependencias.

## Ferramentas autorizadas

- Edicao local.
- `scripts/validate-artemis.sh`.
- `git diff --check`.
- Git local.

## Ferramentas proibidas

- Deploy.
- Push.
- Dependencias npm.
- Escrita remota.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
git diff --check
rg -n "ARTEMIS Workflow|Validation Gate|Matriz de runners|Human Gate" ARTEMIS_WORKFLOW.md
```

## Evidencias obrigatorias

- `artifacts/artemis-workflow/run-01/STATUS.md`
- `artifacts/artemis-workflow/run-01/VALIDATION.md`
- `artifacts/artemis-workflow/run-01/HANDOFF.md`

## Escalonar para humano se

- For desejado mudar estados oficiais.
- For desejado permitir push automatico.
- For desejado acoplar diretamente ao Symphony antes do dry-run.

## Entregaveis

- `ARTEMIS_WORKFLOW.md`
- Validacao atualizada.
- Control Plane atualizado.
- Commit local.
