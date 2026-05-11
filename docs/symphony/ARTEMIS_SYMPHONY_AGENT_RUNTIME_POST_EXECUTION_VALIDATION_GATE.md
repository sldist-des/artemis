# ARTEMIS Symphony - Agent Runtime Post-Execution Validation Gate

O Agent Runtime Post-Execution Validation Gate e a etapa que valida resultado
executado antes de qualquer handoff de conclusao.

Ele consome:

- `artifacts/artemis-agent-runtime-execution-result-intake/run-01/execution-result-intake.json`

Ele produz:

- `artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01/post-execution-validation-gate.json`
- `STATUS.md`
- `POST_EXECUTION_VALIDATION_GATE.md`
- `VALIDATION.md`
- `HANDOFF.md`
- `events.json`

## Contrato

Por padrao, este gate e read-only.

Ele so pode executar comandos de validacao quando:

- `execution-result-intake.json` esta pronto;
- `overall=execution_result_intake_ready`;
- `summary.attempt_executed=true`;
- `summary.commands_executed>0`;
- comandos de validacao foram declarados no `result_package`;
- o operador chamou explicitamente `--execute`.

## Estado atual esperado

Enquanto a execucao supervisionada permanecer bloqueada por Human Gate, o estado
esperado e:

- `overall=human_gate`;
- `post_validation_state=waiting_for_execution_result_intake_ready`;
- `summary.execution_result_intake_ready=false`;
- `summary.post_execution_validation_ready=false`;
- `summary.execute_requested=false`;
- `summary.validations_executed=0`;
- `summary.commands_executed=0`.

## Nao faz

- nao valida plan-only;
- nao valida dry-run;
- nao valida Human Gate como execucao real;
- nao inicia agentes;
- nao executa comandos sem `--execute`;
- nao escreve remoto;
- nao toca secrets;
- nao faz deploy;
- nao altera producao.

## Comando canonico

```bash
scripts/artemis-agent-runtime-post-execution-validation-gate.sh --json
```

Com paths explicitos:

```bash
scripts/artemis-agent-runtime-post-execution-validation-gate.sh \
  --result-intake artifacts/artemis-agent-runtime-execution-result-intake/run-01/execution-result-intake.json \
  --artifact-root artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01 \
  --json
```

## Evento canonico

O corte emite `validation.completed` com produtor
`agent_runtime_post_execution_validation_gate`.

No estado atual, esse evento permanece em `human_gate` porque ainda nao existe
execucao supervisionada real para validar.

## Proximo corte

`TKT-068 - Agent Runtime Completion Handoff do ARTEMIS Symphony` deve consumir
este gate e manter conclusao bloqueada ate existir
`post_execution_validation_completed`.
