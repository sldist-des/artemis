# TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao supervisionada com gates humanos preservados.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.
- Humano: autoridade exclusiva sobre a decisao de runtime.

## Objetivo

Consumir o `runtime-decision-intake.json` e produzir um preflight de launcher
que so fica pronto quando existir decisao humana `approved_ready`, sem executar
agente real.

## Escopo

- Criar `scripts/artemis-agent-runtime-launcher-preflight.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-runtime-launcher-preflight/run-01/`.
- Registrar evento canonico `evt_tkt-062_agent_runtime_launcher_preflight`.
- Atualizar Validation Gate, Event Log, Project Graph, Control Plane e spec do
  Symphony.

## Fora de escopo

- Iniciar Codex app-server, Claude Code, SDK, CLI, subagente, daemon, fila ou runner real.
- Executar comandos aprovados.
- Autorizar custo, tokens pagos, push, PR, deploy, producao ou secrets.
- Transformar `pending` em aprovado sem decisao humana.

## Evidencias obrigatorias

- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/PREFLIGHT.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/events.json`

## Resultado esperado

Com a decisao humana ainda pendente, o preflight deve reportar `human_gate`,
`preflight_state=waiting_for_approved_ready`, `launcher_preflight_allowed=false`,
`launcher_execution_allowed=false`, `runtime_execution_allowed=false`,
`runtime_started=false`, `agents_started=0`, `commands_executed=0`,
`paid_tokens_authorized=0` e `remote_writes_allowed=false`.

## Resultado

O preflight foi implementado como camada read-only. Ele revalida a decisao de
runtime antes de qualquer planejamento de launcher e produz um pacote futuro
somente quando o Decision Intake estiver `approved_ready`.

O proximo corte e `TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony`.
