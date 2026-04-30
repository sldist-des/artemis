# TKT-019 - Definir Workspace Manager ARTEMIS

## Objetivo

Definir o contrato local de workspace para execucao agentic confiavel: worktree, branch, lock, artifact root, dono escritor, limpeza e handoff.

## Resultado esperado

ARTEMIS deve ter uma especificacao e um primeiro check local que expliquem quando uma tarefa pode abrir um workspace isolado, quando deve parar em Human Gate e como registrar evidencias sem iniciar agentes automaticamente.

## Nivel ARTEMIS da execucao

Nivel 2 - contrato operacional local sem daemon.

## Agentes envolvidos

- Architect: define contrato de workspace e invariantes.
- Implementer: cria docs e checks locais minimos.
- Reviewer: valida riscos de concorrencia, escopo e limpeza.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `scripts/artemis-dry-run.sh`
- `scripts/artemis-runner.sh`
- `control-plane/tasks.json`

## Escopo

- Definir estrategia de branch/worktree por ticket.
- Definir lock de escritor unico por workspace.
- Definir artifact root por tentativa.
- Definir estados de limpeza, handoff e abandono.
- Atualizar dry-run ou runner para expor readiness de workspace se couber no corte.

## Fora de escopo

- Criar daemon.
- Iniciar Codex ou Claude automaticamente.
- Fazer push ou merge remoto.
- Resolver conflitos automaticamente.
- Introduzir dependencia nova.

## Invariantes

- Um agente escritor por worktree.
- Mudanca fora de escopo vira Human Gate.
- Remoto, owners e branch protection continuam Human Gate.
- Workspace e meio de execucao, nao fonte canonica de verdade.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-dry-run.sh
git status --branch --short --ignored
```

## Evidencias obrigatorias

- `artifacts/artemis-workspace-manager/run-01/STATUS.md`
- `artifacts/artemis-workspace-manager/run-01/VALIDATION.md`
- `artifacts/artemis-workspace-manager/run-01/HANDOFF.md`
