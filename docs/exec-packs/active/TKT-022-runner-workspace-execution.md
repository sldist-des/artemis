# TKT-022 - Executar runner no workspace materializado

## Objetivo

Fazer o runner supervisionado executar comandos dentro do worktree materializado quando isso for solicitado explicitamente.

## Resultado esperado

Uma tentativa local deve poder usar o workspace materializado como diretorio de execucao, preservando dry-run, readiness, eventos canonicos, logs e handoff.

## Nivel ARTEMIS da execucao

Nivel 3 - execucao local controlada em worktree isolado.

## Agentes envolvidos

- Architect: define limites de execucao em worktree.
- Implementer: adiciona selecao explicita de workspace no runner.
- Reviewer: valida cwd, locks, comandos bloqueados e evidencias.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `scripts/artemis-runner.sh`
- `scripts/artemis-workspace.sh`
- `scripts/artemis_workspace_common.py`
- `artifacts/artemis-workspace-materialization/run-01/`
- `artifacts/artemis-runner-attempt-events/run-01/`

## Escopo

- Adicionar modo explicito para executar dentro do worktree materializado.
- Verificar lock/worktree antes de executar.
- Registrar cwd real em artifacts e eventos.
- Bloquear execucao se o lock nao pertence ao ticket.
- Manter comandos remotos, destrutivos e deploy como Human Gate.

## Fora de escopo

- Iniciar Codex/Claude automaticamente.
- Push, merge, PR ou deploy.
- Resolver conflitos automaticamente.
- Cleanup automatico do worktree.
- Execucao paralela multiagente.

## Invariantes

- Um agente escritor por worktree.
- Runner continua terminal-first.
- Eventos continuam observacionais.
- Workspace materializado nao implica Done.
- Main worktree nao deve ser usado para escrita quando houver workspace materializado explicito.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-runner.sh --ticket TKT-022 --command "pwd" --execute
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-runner-workspace-execution/run-01/STATUS.md`
- `artifacts/artemis-runner-workspace-execution/run-01/VALIDATION.md`
- `artifacts/artemis-runner-workspace-execution/run-01/HANDOFF.md`
