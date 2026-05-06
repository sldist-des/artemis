# TKT-046 - Fila supervisionada do ARTEMIS Symphony

## Objetivo

Transformar o dispatch observado pelo daemon dry-run em uma fila local revisavel, sem executar bridge, runner ou comandos automaticamente.

## Nivel ARTEMIS da execucao

Nivel 2 - componente operacional local read-only.

## Agentes envolvidos

- Architect: definir contrato entre daemon, fila e ponte supervisionada.
- Executor: implementar script, docs, artifacts e Control Plane.
- Reviewer: validar que fila nao escolhe comando, nao chama runner e exige terminal override.

## Contexto

TKT-045 provou o daemon dry-run finito. O proximo passo e materializar uma fila que o humano ou agente possa revisar antes de qualquer ponte supervisionada.

## Escopo

- Criar `scripts/artemis-symphony-queue.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md`.
- Atualizar `docs/symphony/ARTEMIS_SYMPHONY_SPEC.md`.
- Atualizar compatibilidade, Validation Gate e validação local.
- Expor evidencia de fila no Control Plane.
- Gerar artifacts em `artifacts/artemis-symphony-queue/run-01/`.

## Fora de escopo

- Executar item da fila.
- Inferir comando de execucao.
- Chamar bridge automaticamente.
- Chamar runner automaticamente.
- Criar processo persistente.
- Push, PR, merge, deploy ou cleanup.

## Contrato

- A fila le `symphony-daemon.json`.
- A fila abre o kernel do ultimo tick.
- Cada item de `dispatch_plan` vira `review_required`.
- `terminal_override_required` permanece `true`.
- `commands_executed` permanece `0`.
- `bridge_called` permanece `false`.
- `runner_called` permanece `false`.
- `runner_auto_execution_allowed` permanece `false`.

## Validacao

```bash
scripts/artemis-symphony-queue.sh --daemon artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json --artifact-root artifacts/artemis-symphony-queue/run-01 --json
scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Resultado esperado

Fila supervisionada local gera itens revisaveis quando ha dispatch elegivel e `queue_empty` quando nao ha trabalho elegivel, sempre sem execucao automatica.

## Evidencias obrigatorias

- `artifacts/artemis-symphony-queue/run-01/STATUS.md`
- `artifacts/artemis-symphony-queue/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-queue/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-queue/run-01/symphony-queue.json`
- `artifacts/artemis-symphony-queue/run-01/events.json`
