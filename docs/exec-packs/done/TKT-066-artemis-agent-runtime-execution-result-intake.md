# TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony

## Intent

Classificar o resultado da execucao supervisionada antes de liberar qualquer
validacao pos-execucao.

## Scope

- Criar o intake read-only de resultado de execucao supervisionada.
- Diferenciar plano, Human Gate, execucao real, sucesso, falha e rollback.
- Registrar evidencias, checks, handoff e evento canonico.
- Expor o novo corte no Project Graph, Event Log, Validation Gate e Control Plane.

## Out of scope

- Executar agentes.
- Rodar comandos reais.
- Instalar dependencias.
- Escrever em remoto, push, PR, deploy ou producao.
- Consumir tokens pagos fora dos artefatos ja autorizados.

## Acceptance criteria

- `scripts/artemis-agent-runtime-execution-result-intake.sh --json` gera
  `execution-result-intake.json`.
- O estado atual permanece `human_gate` enquanto nao houver execucao
  supervisionada real.
- Plano ou Human Gate pendente nao sao classificados como sucesso.
- O evento `runner.result_blocked` entra no Event Log canonico.
- `scripts/validate-artemis.sh` valida o novo corte.
- O Control Plane mostra o Result Intake como parte da cadeia de runtime.

## Validation

Comandos esperados:

```bash
scripts/artemis-agent-runtime-execution-result-intake.sh --json
scripts/artemis-validation-gate.sh --json
scripts/validate-artemis.sh
git diff --check
```

## Handoff

Proximo corte:

`TKT-067 - Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony`

Esse proximo corte deve consumir `execution-result-intake.json` e so liberar
validacao pos-execucao quando existir resultado supervisionado real.
