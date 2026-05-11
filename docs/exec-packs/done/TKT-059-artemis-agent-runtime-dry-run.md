# TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao supervisionada com gates humanos preservados.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.
- Humano: autoridade futura para auth, budget e runtime real.

## Objetivo

Materializar um pedido de runtime a partir do Agent Launch Contract sem iniciar
Codex app-server, Claude Code, subagentes pagos, comandos remotos ou qualquer
processo real de agente.

## Escopo

- Criar `scripts/artemis-agent-runtime-dry-run.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-runtime-dry-run/run-01/`.
- Registrar evento canonico `evt_tkt-059_agent_runtime_dry_run`.
- Atualizar Validation Gate, Event Log, Project Graph, Project Brief,
  Guided Collaboration, Control Plane e spec do Symphony.

## Fora de escopo

- Autenticar contas Codex, Claude Code ou GitHub.
- Iniciar app-server, SDK headless, subagente, daemon, fila ou runner real.
- Autorizar custo, tokens pagos, push, PR, deploy, producao ou secrets.
- Alterar branch protection, owners, rulesets ou configuracao remota.

## Evidencias obrigatorias

- `artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json`
- `artifacts/artemis-agent-runtime-dry-run/run-01/REQUEST.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/PREFLIGHT.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/RUNTIME_LOG.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-dry-run/run-01/HANDOFF.md`

## Resultado esperado

O runtime dry-run deve reportar `agent_runtime_dry_run_ready`, com
`execute=false`, `runtime_started=false`, `agents_started=0`,
`commands_executed=0`, `paid_tokens_authorized=0` e
`remote_writes_allowed=false`.

## Resultado

O dry-run foi implementado como superficie de ensaio auditavel. Ele registra
pedido, preflight, budget zero, Human Gates de auth/budget, workspace read-only,
rollback e handoff sem iniciar runtime.

O proximo corte e `TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`.
