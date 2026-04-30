# TKT-010 - Criar orchestrator dry-run

## Objetivo

Simular decisoes de dispatch do ARTEMIS sem iniciar agentes, sem criar worktrees e sem alterar tarefas.

## Resultado esperado

Um comando local le o task source e mostra quais tarefas seriam elegiveis, bloqueadas ou aguardando humano, com razao explicita.

## Nivel ARTEMIS da execucao

Nivel 1 - simulacao local sem runner.

## Agentes envolvidos

- Architect: define regras de elegibilidade.
- Implementer: cria comando de dry-run.
- Reviewer: valida que nenhuma execucao real ocorre.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `scripts/artemis-tasks.sh`
- `control-plane/tasks.json`
- `docs/exec-packs/active/`

## Escopo

- Criar comando local de dry-run.
- Ler JSON de task source.
- Classificar tarefas como eligible, blocked, human_gate ou done.
- Registrar razao para cada decisao.
- Nao iniciar runners.

## Fora de escopo

- Daemon.
- Codex app-server adapter.
- Claude Code adapter.
- GitHub Issues.
- Criar worktree.
- Executar agentes.

## Invariantes

- Dry-run nao executa tarefas.
- Dry-run nao altera Exec Packs.
- Human Gate continua obrigatorio para push, remoto, secrets, producao e owners reais.
- Sem novas dependencias.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-tasks.sh --output control-plane/tasks.json
```

## Evidencias obrigatorias

- `artifacts/artemis-dry-run/run-01/STATUS.md`
- `artifacts/artemis-dry-run/run-01/VALIDATION.md`
- `artifacts/artemis-dry-run/run-01/HANDOFF.md`
