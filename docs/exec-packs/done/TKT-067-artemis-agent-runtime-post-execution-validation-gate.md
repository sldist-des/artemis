# TKT-067 - Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony

## Intent

Validar resultado de execucao real antes de permitir handoff de conclusao.

## Scope

- Criar o gate read-only de validacao pos-execucao.
- Consumir `execution-result-intake.json`.
- Bloquear validacao quando o intake estiver em plano, Human Gate ou falha.
- Registrar checks, pacote de validacao, handoff e evento canonico.
- Expor o novo gate no Project Graph, Event Log, Validation Gate e Control Plane.

## Out of scope

- Executar agentes.
- Validar dry-run como execucao real.
- Rodar comandos sem `--execute`.
- Escrever remoto, push, PR, deploy, producao ou secrets.

## Acceptance criteria

- `scripts/artemis-agent-runtime-post-execution-validation-gate.sh --json`
  gera `post-execution-validation-gate.json`.
- O estado atual permanece `human_gate` enquanto nao houver result intake pronto.
- `validations_executed=0` por padrao.
- O evento `validation.completed` entra no Event Log canonico.
- `scripts/validate-artemis.sh` valida o novo corte.
- O Control Plane mostra o Post-Execution Validation Gate na cadeia de runtime.

## Validation

Comandos esperados:

```bash
scripts/artemis-agent-runtime-post-execution-validation-gate.sh --json
scripts/artemis-validation-gate.sh --json
scripts/validate-artemis.sh
git diff --check
```

## Handoff

Proximo corte:

`TKT-068 - Agent Runtime Completion Handoff do ARTEMIS Symphony`

Esse proximo corte deve consumir `post-execution-validation-gate.json` e so
preparar conclusao quando existir validacao pos-execucao concluida.
