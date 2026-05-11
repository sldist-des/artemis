# TKT-063 - Agent Runtime Launcher Command Plan do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao supervisionada com gates humanos preservados.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.
- Humano: autoridade exclusiva sobre a decisao de runtime e execucao real.

## Objetivo

Consumir o `launcher-preflight.json` e produzir um plano de comandos read-only
para um futuro launcher supervisionado, sem executar comandos nem iniciar
runtime real.

## Escopo

- Criar `scripts/artemis-agent-runtime-launcher-command-plan.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/`.
- Registrar evento canonico `evt_tkt-063_agent_runtime_launcher_command_plan`.
- Atualizar Validation Gate, Event Log, Project Graph, Control Plane e spec do
  Symphony.

## Fora de escopo

- Iniciar Codex app-server, Claude Code, SDK, CLI, subagente, daemon, fila ou runner real.
- Executar comandos planejados.
- Autorizar custo, tokens pagos, push, PR, deploy, producao ou secrets.
- Transformar `human_gate` em pronto sem `launcher_preflight_ready`.

## Evidencias obrigatorias

- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/launcher-command-plan.json`
- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/COMMAND_PLAN.md`
- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-launcher-command-plan/run-01/events.json`

## Resultado esperado

Com o launcher preflight ainda em Human Gate, o command plan deve reportar
`human_gate`, `plan_state=waiting_for_launcher_preflight_ready`,
`command_plan_ready=false`, `launcher_execution_allowed=false`,
`runtime_execution_allowed=false`, `runtime_started=false`, `agents_started=0`,
`commands_executed=0`, `paid_tokens_authorized=0` e
`remote_writes_allowed=false`.

## Resultado

O plano de comandos foi implementado como camada read-only. Ele materializa
comandos apenas quando o preflight estiver `launcher_preflight_ready`; enquanto
isso, preserva o Human Gate e bloqueia qualquer execucao.

O proximo corte e `TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`.
