# TKT-049 - Servico supervisionado local do ARTEMIS Symphony

## Objetivo

Transformar os cortes locais do ARTEMIS Symphony em um ciclo de service finito,
supervisionado e auditavel, preservando terminal override, fila revisavel e
Human Gates.

## Nivel ARTEMIS da execucao

Nivel 2 - componente operacional local supervisionado.

## Agentes envolvidos

- Architect: definir a fronteira entre service finito e execucao real.
- Executor: implementar script, docs, artifacts e Control Plane.
- Reviewer: validar que o service nao executa comandos reais nem passa
  `--execute` automaticamente.

## Contexto

TKT-048 permitiu execucao opt-in pelo Queue Bridge com Validation Gate e decisao
exata. O TKT-049 cria uma superficie local unica para rodar daemon, fila e uma
ponte plan-only opcional sem ampliar permissao de execucao.

## Escopo

- Criar `scripts/artemis-symphony-service.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_SERVICE.md`.
- Atualizar spec, compatibilidade, Validation Gate e validacao local.
- Expor evidencia do service no Control Plane.
- Gerar artifacts em `artifacts/artemis-symphony-service/run-01/`.

## Fora de escopo

- Daemon persistente.
- `--execute` no service.
- Execucao automatica da fila.
- Push, PR, merge, deploy, secrets ou comandos remotos.
- Aprovacao de Human Gates por agente.

## Contrato

- O service roda um ciclo finito.
- O service chama daemon e fila.
- O service chama Queue Bridge apenas com `--ticket` ou `--queue-id` e
  `--command` explicitos.
- O service chama Queue Bridge somente em plan-only.
- O service mantem `commands_executed=0`.
- Execucao real continua restrita ao Queue Bridge com `--execute`,
  Validation Gate e decisao exata.

## Validacao

```bash
scripts/artemis-symphony-service.sh --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json --artifact-root artifacts/artemis-symphony-service/run-01 --ticks 1 --interval 0 --max-concurrency 1 --ticket TKT-949 --command "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-service/run-01/fixtures/task-source.json" --json
scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Resultado esperado

Service gera `service_bridge_plan_ready` quando o terminal fornece ticket e
comando explicitos, com `queue_bridge_plan_ready=true`,
`execute_supported_by_service=false` e `commands_executed=0`.

## Evidencias obrigatorias

- `artifacts/artemis-symphony-service/run-01/STATUS.md`
- `artifacts/artemis-symphony-service/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-service/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-service/run-01/symphony-service.json`
- `artifacts/artemis-symphony-service/run-01/events.json`
- `artifacts/artemis-symphony-service/run-01/queue-bridge/queue-bridge.json`
