# TKT-020 - Emitir eventos canonicos de tentativa do runner

## Objetivo

Fazer o runner supervisionado registrar o ciclo de tentativa como eventos canonicos ARTEMIS.

## Resultado esperado

Cada tentativa local deve produzir eventos compativeis com `docs/schemas/artemis-event.schema.json`, vinculando ticket, workspace, dry-run, comando, resultado e artifact root sem alterar estado canonico.

## Nivel ARTEMIS da execucao

Nivel 2 - instrumentacao local sem daemon.

## Agentes envolvidos

- Architect: define eventos minimos da tentativa.
- Implementer: atualiza runner e artifacts.
- Reviewer: valida schema, falhas e Human Gate.
- Memory Keeper: registra handoff.

## Contexto minimo

- `scripts/artemis-runner.sh`
- `scripts/artemis-workspace.sh`
- `scripts/artemis_event_common.py`
- `docs/schemas/artemis-event.schema.json`
- `artifacts/artemis-local-runner/run-01/`

## Escopo

- Emitir `runner.attempt_planned`.
- Emitir `runner.attempt_started` quando `--execute` for usado.
- Emitir `runner.attempt_completed` com exit code e evidencia.
- Registrar eventos junto da tentativa.
- Validar eventos no Validation Gate se couber no corte.

## Fora de escopo

- Criar daemon.
- Iniciar Codex ou Claude automaticamente.
- Fazer push, merge ou PR.
- Criar worktree automaticamente.
- Alterar schema canonico salvo se houver falha real de compatibilidade.

## Invariantes

- Runner continua terminal-first.
- Workspace readiness continua pre-condicao.
- Eventos sao observacionais, nao fonte de verdade.
- Falha de comando nao pode virar Done.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-runner.sh --ticket TKT-020 --command "scripts/artemis-dry-run.sh"
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-runner-attempt-events/run-01/STATUS.md`
- `artifacts/artemis-runner-attempt-events/run-01/VALIDATION.md`
- `artifacts/artemis-runner-attempt-events/run-01/HANDOFF.md`
