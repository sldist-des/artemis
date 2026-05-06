# TKT-045 - Daemon dry-run do ARTEMIS Symphony

## Objetivo

Implementar um daemon dry-run finito para o ARTEMIS Symphony, capaz de observar a task source, chamar o kernel read-only, registrar heartbeat e encerrar sem executar bridge, runner ou comandos.

## Nivel ARTEMIS da execucao

Nivel 2 - componente operacional local read-only.

## Agentes envolvidos

- Architect: definir fronteira entre daemon dry-run, kernel e futura fila supervisionada.
- Executor: implementar script, docs, artifacts e Control Plane.
- Reviewer: validar que nao ha processo persistente, runner automatico ou bypass de Human Gate.

## Contexto

TKT-042 criou o kernel read-only. TKT-043 criou a ponte supervisionada plan-only. TKT-044 expos evidencias no Control Plane.

O proximo passo seguro e provar o loop de observacao sem iniciar um servico persistente nem automatizar execucao.

## Escopo

- Criar `scripts/artemis-symphony-daemon.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md`.
- Atualizar `docs/symphony/ARTEMIS_SYMPHONY_SPEC.md`.
- Atualizar compatibilidade e Validation Gate.
- Expor evidencia de daemon dry-run no Control Plane.
- Gerar artifacts em `artifacts/artemis-symphony-daemon/run-01/`.

## Fora de escopo

- Processo long-running real.
- systemd, cron, tmux ou supervisor externo.
- Chamar bridge ou runner automaticamente.
- Executar agentes.
- Criar fila real de dispatch.
- Push, PR, merge, deploy ou cleanup.

## Contrato

- `--ticks` torna a execucao finita.
- Cada tick chama apenas `scripts/artemis-symphony-kernel.sh`.
- `commands_executed` permanece `0`.
- `runner_auto_execution_allowed` permanece `false`.
- `bridge_called` permanece `false`.
- `long_running_process_started` permanece `false`.
- Human Gates sao observados e registrados.

## Validacao

```bash
scripts/artemis-symphony-daemon.sh --artifact-root artifacts/artemis-symphony-daemon/run-01 --ticks 2 --interval 0 --max-concurrency 1 --json
scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Resultado esperado

Daemon dry-run local produz heartbeat, eventos e handoff sem iniciar runner automatico.

## Evidencias obrigatorias

- `artifacts/artemis-symphony-daemon/run-01/STATUS.md`
- `artifacts/artemis-symphony-daemon/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-daemon/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json`
- `artifacts/artemis-symphony-daemon/run-01/heartbeat.json`
- `artifacts/artemis-symphony-daemon/run-01/events.json`
