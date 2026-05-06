# TKT-042 - Kernel local do ARTEMIS Symphony

## Objetivo

Criar o primeiro kernel local read-only do ARTEMIS Symphony.

## Resultado esperado

Um comando local le o task source, reutiliza o dry-run ARTEMIS, aplica concorrencia maxima configuravel e grava um plano de dispatch sem executar agentes.

## Nivel ARTEMIS da execucao

Nivel 1 - simulacao local sem runner.

## Agentes envolvidos

- Architect: define fronteira entre kernel read-only, runner supervisionado e daemon futuro.
- Implementer: cria comando de kernel e artifacts.
- Reviewer: valida que nenhuma execucao real ocorre.
- Memory Keeper: registra evidencia e handoff.

## Contexto minimo

- `docs/symphony/ARTEMIS_SYMPHONY_SPEC.md`
- `scripts/artemis-dry-run.sh`
- `scripts/artemis-runner.sh`
- `control-plane/tasks.json`

## Escopo

- Criar `scripts/artemis-symphony-kernel.sh`.
- Criar documentacao do kernel.
- Planejar dispatch com bounded concurrency.
- Registrar JSON, eventos, status, validacao e handoff.
- Integrar ao Validation Gate.

## Fora de escopo

- Daemon local longo.
- Execucao de agentes.
- Criar worktree.
- Chamar runner supervisionado.
- Push, PR, merge ou cleanup.
- Copiar codigo do OpenAI Symphony.

## Invariantes

- Kernel e read-only.
- `commands_executed` deve ser `0`.
- `runner_execution_allowed` deve ser `false`.
- Human Gates nao podem ser reclassificados como elegiveis.
- Dry-run continua sendo a fonte de elegibilidade.
- Control Plane continua observacional.

## Validacao prevista

```bash
scripts/artemis-symphony-kernel.sh --artifact-root artifacts/artemis-symphony-kernel/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
```

## Evidencias obrigatorias

- `artifacts/artemis-symphony-kernel/run-01/STATUS.md`
- `artifacts/artemis-symphony-kernel/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-kernel/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-kernel/run-01/symphony-kernel.json`
