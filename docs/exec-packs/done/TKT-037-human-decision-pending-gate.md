# TKT-037 - Human Gate da decisao humana pendente

## Objetivo

Registrar explicitamente que o pacote real de cleanup esta parado em Human Gate porque a decisao humana ainda nao foi preenchida.

## Resultado esperado

O repositorio deve ter um artifact de pausa operacional que diga o que o humano precisa preencher, quais comandos validar depois e por que nenhum executor pode seguir agora.

## Nivel ARTEMIS da execucao

Nivel 1 - registro read-only de Human Gate.

## Agentes envolvidos

- Reviewer: valida que o gate nao virou autorizacao.
- Memory Keeper: consolida o estado de pausa e evidencias.
- Architect: define reentrada segura apos preenchimento humano.

## Contexto minimo

- `artifacts/artemis-human-decision-intake/run-01/`
- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`
- `artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md`
- `artifacts/artemis-human-decision-release-checkpoint/run-01/`

## Escopo

- Registrar estado de pausa em Human Gate.
- Listar campos que o humano deve preencher.
- Apontar os comandos de validacao depois do preenchimento.
- Confirmar que nenhum cleanup pode ser executado enquanto houver `pending`.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push, PR, merge remoto ou configurar GitHub.

## Invariantes

- Human Gate nao e aprovacao.
- Agente nao decide pelo humano.
- Sem `--execute`.
- `real-cleanup-decision.json` continua canonico.
- Remote writes continuam Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-pending-gate/run-01/STATUS.md`
- `artifacts/artemis-human-decision-pending-gate/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-pending-gate/run-01/HANDOFF.md`
