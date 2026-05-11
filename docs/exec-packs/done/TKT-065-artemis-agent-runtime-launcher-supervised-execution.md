# TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony

## Objetivo

Criar a camada de execucao supervisionada que consome o
`launcher-execution-gate.json` e materializa uma tentativa auditavel de runtime
sem perder o controle humano, Git, logs, budget, rollback e Validation Gate.

## Escopo

- Criar `scripts/artemis-agent-runtime-launcher-supervised-execution.sh`.
- Gerar artifact canonico em
  `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/`.
- Registrar evento canonico
  `evt_tkt-065_agent_runtime_launcher_supervised_execution`.
- Integrar o novo artefato no Event Log, Project Operations Graph, Project
  Brief, Compatibility, Validation Gate e Control Plane.
- Manter execucao real bloqueada enquanto o Launcher Execution Gate estiver em
  `human_gate`.

## Fora de escopo

- Iniciar Codex app-server, Claude Code, SDK, CLI, subagentes ou daemons reais.
- Fazer push, PR, deploy, alteracao de producao ou acesso a secrets.
- Gastar tokens pagos automaticamente.
- Copiar codigo do OpenAI Symphony.

## Evidencias esperadas

- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/launcher-supervised-execution.json`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/SUPERVISED_EXECUTION.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-launcher-supervised-execution/run-01/events.json`

## Validacao

- `scripts/artemis-agent-runtime-launcher-supervised-execution.sh --json`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `scripts/validate-artemis.sh`
- `git diff --check`

## Handoff

O proximo corte e
`TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony`, consumindo
`launcher-supervised-execution.json` para separar tentativa planejada, tentativa
executada, sucesso, falha, rollback pendente e evidencia de validacao.
