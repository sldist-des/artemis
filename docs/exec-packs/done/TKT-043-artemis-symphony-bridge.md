# TKT-043 - Ponte supervisionada do ARTEMIS Symphony

## Objetivo

Conectar o plano read-only do ARTEMIS Symphony Kernel ao runner local supervisionado.

## Resultado esperado

Um comando local roda o kernel, seleciona um ticket elegivel em `dispatch_plan` e cria uma tentativa supervisionada do runner em modo plan-only por padrao.

## Nivel ARTEMIS da execucao

Nivel 2 - ponte supervisionada sem daemon.

## Agentes envolvidos

- Architect: define fronteira entre kernel, ponte e daemon futuro.
- Implementer: cria comando de ponte e artifacts.
- Reviewer: valida que execucao real exige `--execute`.
- Memory Keeper: registra evidencia e handoff.

## Contexto minimo

- `docs/symphony/ARTEMIS_SYMPHONY_SPEC.md`
- `docs/symphony/ARTEMIS_SYMPHONY_KERNEL.md`
- `scripts/artemis-symphony-kernel.sh`
- `scripts/artemis-runner.sh`

## Escopo

- Criar `scripts/artemis-symphony-bridge.sh`.
- Criar documentacao da ponte.
- Rodar kernel antes do runner.
- Selecionar ticket apenas se estiver em `dispatch_plan`.
- Chamar runner supervisionado em modo plan-only por padrao.
- Registrar JSON, eventos, status, validacao e handoff.
- Integrar ao Validation Gate.

## Fora de escopo

- Daemon local longo.
- Execucao automatica de agentes.
- Push, PR, merge ou cleanup.
- Control Plane visual para evidencias da ponte.
- Copiar codigo do OpenAI Symphony.

## Invariantes

- Ponte nao e daemon.
- Ponte deve rodar o kernel antes do runner.
- Ticket fora de `dispatch_plan` nao pode chegar ao runner.
- Sem `--execute`, `commands_executed` deve ser `0`.
- Comandos remotos, destrutivos e deploy continuam bloqueados pelo runner.
- Human Gates continuam intransponiveis.

## Validacao prevista

```bash
scripts/artemis-symphony-bridge.sh --input /tmp/artemis-symphony-bridge-source.json --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-bridge-source.json" --artifact-root artifacts/artemis-symphony-bridge/run-01 --max-concurrency 2 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
```

## Evidencias obrigatorias

- `artifacts/artemis-symphony-bridge/run-01/STATUS.md`
- `artifacts/artemis-symphony-bridge/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-bridge/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-bridge/run-01/symphony-bridge.json`
