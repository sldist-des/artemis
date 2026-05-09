# TKT-060 - Agent Runtime Approval Gate do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao supervisionada com gates humanos preservados.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.
- Humano: autoridade exclusiva para aprovar, deferir ou rejeitar runtime real.

## Objetivo

Transformar o Agent Runtime Dry-Run em um pacote de aprovacao humana exato antes
de qualquer Codex app-server, Claude Code, subagente, custo pago, comando,
escrita remota, segredo, deploy ou producao.

## Escopo

- Criar `scripts/artemis-agent-runtime-approval-gate.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-runtime-approval-gate/run-01/`.
- Registrar evento canonico `evt_tkt-060_agent_runtime_approval_gate`.
- Atualizar Validation Gate, Event Log, Project Graph, Control Plane e spec do
  Symphony.

## Fora de escopo

- Aprovar runtime no lugar do humano.
- Iniciar app-server, SDK headless, subagente, daemon, fila ou runner real.
- Autorizar custo, tokens pagos, push, PR, deploy, producao ou secrets.
- Executar comandos do pacote de decisao.

## Evidencias obrigatorias

- `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-decision.json`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/APPROVAL_REQUEST.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/DECISION_TEMPLATE.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/CHECKLIST.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-approval-gate/run-01/HANDOFF.md`

## Resultado esperado

O gate deve reportar `agent_runtime_approval_gate_ready`, com decisao `pending`,
`runtime_execution_allowed=false`, `execute=false`, `runtime_started=false`,
`agents_started=0`, `commands_executed=0`, `paid_tokens_authorized=0` e
`remote_writes_allowed=false`.

## Resultado

O gate foi implementado como pacote humano-preenchivel. Ele preserva o dry-run,
lista os itens de Human Gate, gera template/checklist e bloqueia execucao ate
uma decisao humana futura ser ingerida por um corte posterior.

O proximo corte e `TKT-061 - Agent Runtime Decision Intake do ARTEMIS Symphony`.
