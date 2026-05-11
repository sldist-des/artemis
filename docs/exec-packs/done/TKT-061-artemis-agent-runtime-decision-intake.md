# TKT-061 - Agent Runtime Decision Intake do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao supervisionada com gates humanos preservados.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.
- Humano: autoridade exclusiva sobre a decisao de runtime.

## Objetivo

Ingerir `runtime-approval-decision.json` preenchido por humano e classificar o
estado de runtime como `pending`, `approved_ready`, `deferred`, `rejected` ou
`invalid`, sem executar agente real.

## Escopo

- Criar `scripts/artemis-agent-runtime-decision-intake.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-runtime-decision-intake/run-01/`.
- Registrar evento canonico `evt_tkt-061_agent_runtime_decision_intake`.
- Atualizar Validation Gate, Event Log, Project Graph, Control Plane e spec do
  Symphony.

## Fora de escopo

- Preencher decisao humana no lugar do humano.
- Iniciar Codex app-server, Claude Code, SDK, CLI, subagente, daemon, fila ou runner real.
- Executar comandos aprovados.
- Autorizar custo, tokens pagos, push, PR, deploy, producao ou secrets.

## Evidencias obrigatorias

- `artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-decision-intake/run-01/events.json`

## Resultado esperado

O intake deve reportar a decisao atual como `pending`, com
`runtime_execution_allowed=false`, `launcher_preflight_allowed=false`,
`runtime_started=false`, `agents_started=0`, `commands_executed=0`,
`paid_tokens_authorized=0` e `remote_writes_allowed=false`.

## Resultado

O intake foi implementado como camada read-only. Ele preserva a decisao humana,
classifica estados de runtime, rejeita aprovacao parcial ou insegura, e libera
apenas o futuro launcher preflight quando houver `approved_ready` coerente.

O proximo corte e `TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony`.
