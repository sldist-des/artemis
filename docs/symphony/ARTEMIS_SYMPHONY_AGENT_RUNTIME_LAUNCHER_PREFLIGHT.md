# ARTEMIS Symphony Agent Runtime Launcher Preflight

O Agent Runtime Launcher Preflight le o `runtime-decision-intake.json` e decide
se existe uma decisao humana `approved_ready` coerente para virar pacote de
planejamento de launcher.

Ele nao inicia Codex app-server, Claude Code, SDK, CLI, subagentes, fila,
daemon, comando, tokens pagos, escrita remota, secrets, deploy ou producao.

## Contrato

- Consome `artifacts/artemis-agent-runtime-decision-intake/run-01/runtime-decision-intake.json`.
- Fica em `human_gate` enquanto o Decision Intake nao estiver `approved_ready`.
- Revalida identidade, timestamp, runtime, perfil, comandos, budget, auth,
  workspace, branch, dirty state, rollback e evidencias de validacao.
- Produz `launcher_preflight_ready` apenas quando a decisao humana aprovada
  continua coerente no estado atual do repositorio.
- Produz um `launcher_package` para o proximo corte, mas nao executa o pacote.

## Artefatos

O script `scripts/artemis-agent-runtime-launcher-preflight.sh` gera:

- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/PREFLIGHT.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/events.json`

## Proximo corte

`TKT-068 - Agent Runtime Completion Handoff do ARTEMIS Symphony`
