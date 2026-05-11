# ARTEMIS Symphony Agent Runtime Launcher Supervised Execution

O Launcher Supervised Execution e a primeira camada que pode representar a
execucao operacional de um launcher de agentes. Ela nao substitui terminal,
Git, Human Gate ou Validation Gate: ela transforma um
`launcher-execution-gate.json` aprovado em uma tentativa supervisionada,
auditavel e reproduzivel.

Por padrao, o script e plan-only. Mesmo quando o Execution Gate estiver pronto,
comandos so podem ser executados com `--execute`, comandos aprovados
exatamente, budget explicito, validacao registrada e bloqueios de remoto,
producao e secrets preservados.

## Comandos

```bash
scripts/artemis-agent-runtime-launcher-supervised-execution.sh
scripts/artemis-agent-runtime-launcher-supervised-execution.sh --json
scripts/artemis-agent-runtime-launcher-supervised-execution.sh --execute --json
```

## Contrato

- consome `launcher-execution-gate.json`;
- exige `overall=launcher_execution_gate_ready`;
- exige `gate_state=execution_gate_ready`;
- exige `execution_gate_ready=true`;
- exige `launcher_execution_allowed=true`;
- exige `runtime_execution_allowed=true`;
- exige `execution_package.eligible=true`;
- permanece em `human_gate` quando qualquer premissa anterior faltar;
- em modo padrao, nunca executa comandos;
- com `--execute`, executa somente os comandos aprovados exatamente pelo gate;
- registra stdout, stderr, exit code, budget, stop rule, rollback e evidencia;
- bloqueia push, PR, deploy, secrets, producao e comandos destrutivos sem gate
  separado.

## Artefatos

- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/SUPERVISED_EXECUTION.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/events.json`

## Estado atual esperado

Enquanto o Launcher Execution Gate estiver em Human Gate, o resultado correto
e:

- `overall=human_gate`;
- `execution_state=waiting_for_launcher_execution_gate_ready`;
- `supervised_execution_ready=false`;
- `execute_requested=false`;
- `commands_executed=0`;
- `runtime_started=false`;
- `remote_writes_allowed=false`;
- evento canonico `runner.attempt_planned`.

## Proximo corte

`TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony`
