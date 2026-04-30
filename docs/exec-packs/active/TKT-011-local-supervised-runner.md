# TKT-011 - Criar runner local supervisionado

## Objetivo

Permitir iniciar uma tarefa local em modo supervisionado, preservando controle terminal-first, logs, artifacts e parada em Human Gate.

## Resultado esperado

Um comando local prepara o contexto de execucao para uma tarefa elegivel sem fazer merge, push ou alteracao remota. O runner deve ser explicito, auditavel e reversivel.

## Nivel ARTEMIS da execucao

Nivel 2 - automacao local com guardrails.

## Agentes envolvidos

- Architect: define fronteira entre dry-run e execucao real.
- Implementer: cria comando de runner local.
- Reviewer: valida que Human Gate e validation gates foram preservados.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `scripts/artemis-dry-run.sh`
- `scripts/artemis-tasks.sh`
- `docs/exec-packs/active/`
- `artifacts/`

## Escopo

- Criar comando local supervisionado.
- Exigir Exec Pack elegivel pelo dry-run.
- Criar diretorio de artifacts da tentativa.
- Registrar comando planejado, ambiente e logs.
- Parar antes de push, merge, remoto, secrets ou producao.

## Fora de escopo

- Daemon.
- Execucao remota.
- GitHub Issues.
- Codex app-server adapter.
- Claude Code adapter.
- Merge automatico.
- Push automatico.

## Invariantes

- Terminal continua soberano.
- Nenhuma alteracao remota.
- Runner deve ser auditavel.
- Human Gate bloqueia push, merge, secrets, producao e owners reais.
- Sem novas dependencias.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-tasks.sh --output control-plane/tasks.json
scripts/artemis-dry-run.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-local-runner/run-01/STATUS.md`
- `artifacts/artemis-local-runner/run-01/VALIDATION.md`
- `artifacts/artemis-local-runner/run-01/HANDOFF.md`
