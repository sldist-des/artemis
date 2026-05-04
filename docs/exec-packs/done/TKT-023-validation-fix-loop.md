# TKT-023 - Loop de validacao e fix em workspace isolado

## Objetivo

Formalizar o ciclo de validacao, correcao e nova tentativa usando o workspace isolado.

## Resultado esperado

Uma tarefa deve poder falhar em validacao, registrar parada tecnica, executar uma tentativa de fix no workspace materializado e produzir nova evidencia antes de handoff.

## Nivel ARTEMIS da execucao

Nivel 3 - execucao local controlada com retry auditavel.

## Agentes envolvidos

- Architect: define limites do loop.
- Implementer: adiciona contrato de retry/fix.
- Reviewer: valida estados, logs e riscos.
- Memory Keeper: registra artifacts e handoff.

## Contexto minimo

- `scripts/artemis-runner.sh`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh`
- `artifacts/artemis-runner-workspace-execution/run-01/`
- `docs/workspaces/artemis-workspace-manager.md`

## Escopo

- Registrar tentativa falha como parada tecnica auditavel.
- Registrar nova tentativa de fix/retry no mesmo artifact root.
- Preservar `execution_cwd` e workspace lock nas evidencias.
- Definir quando o loop para em Human Gate.
- Documentar handoff depois de retry bem-sucedido.

## Fora de escopo

- Push, merge, PR ou deploy.
- Cleanup automatico.
- Resolver conflitos automaticamente.
- Orquestracao paralela multiagente.

## Invariantes

- Um agente escritor por worktree.
- Cada tentativa tem eventos canonicos.
- Falha tecnica nao vira Done.
- Retry nao pode apagar evidencia anterior.
- Human Gate vence automacao em caso de escopo, risco ou conflito.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-runner.sh --ticket TKT-023 --command "false" --execute
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-validation-fix-loop/run-01/STATUS.md`
- `artifacts/artemis-validation-fix-loop/run-01/VALIDATION.md`
- `artifacts/artemis-validation-fix-loop/run-01/HANDOFF.md`
