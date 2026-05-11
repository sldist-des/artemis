# ARTEMIS Symphony - Agent Runtime Execution Result Intake

O Agent Runtime Execution Result Intake e o corte que interpreta o resultado
da execucao supervisionada antes de qualquer validacao pos-execucao.

Ele consome:

- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json`

Ele produz:

- `artifacts/artemis-agent-runtime-execution-result-intake/run-01/execution-result-intake.json`
- `STATUS.md`
- `RESULT_INTAKE.md`
- `VALIDATION.md`
- `HANDOFF.md`
- `events.json`

## Contrato

O intake e read-only.

Ele nao:

- inicia agentes;
- executa comandos;
- instala dependencias;
- escreve em remoto;
- abre PR;
- faz push;
- toca secrets;
- faz deploy;
- altera producao.

## Classificacao

O intake separa explicitamente:

- `blocked_pending_gate`: existe apenas plano ou Human Gate pendente;
- `plan_only_ready`: o launcher esta pronto, mas `--execute` nao rodou;
- `completed_success`: houve execucao supervisionada real e sem comandos falhos;
- `completed_with_failures`: houve execucao e algum comando falhou;
- `failed_before_execution`: o runner falhou antes de produzir resultado executado;
- `missing_input`: o artefato supervisionado nao existe ou nao e JSON valido.

## Regra principal

Plano nao e sucesso.

Um resultado so fica pronto para validacao pos-execucao quando:

- `overall=execution_result_intake_ready`;
- `summary.supervised_execution_result_ready=true`;
- `summary.attempt_executed=true`;
- `summary.commands_executed>0`;
- `result_package.ready_for_validation=true`.

Enquanto o estado atual do repositorio permanecer em Human Gate, o resultado
esperado e:

- `overall=human_gate`;
- `intake_state=waiting_for_supervised_execution_result`;
- `summary.supervised_execution_result_ready=false`;
- `summary.attempt_executed=false`;
- `summary.commands_executed=0`;
- `summary.rollback_required=false`.

## Comando canonico

```bash
scripts/artemis-agent-runtime-execution-result-intake.sh --json
```

Com paths explicitos:

```bash
scripts/artemis-agent-runtime-execution-result-intake.sh \
  --supervised-execution artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json \
  --artifact-root artifacts/artemis-agent-runtime-execution-result-intake/run-01 \
  --json
```

## Evento canonico

O corte emite um destes eventos:

- `runner.result_blocked` quando falta execucao supervisionada real;
- `runner.result_recorded` quando existe resultado pronto para validacao;
- `runner.result_failed` quando a classificacao encontrou falha.

## Proximo corte

`TKT-067 - Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony`
deve consumir `execution-result-intake.json` e manter a validacao bloqueada ate
existir resultado executado, logs preservados e comandos de validacao definidos.
