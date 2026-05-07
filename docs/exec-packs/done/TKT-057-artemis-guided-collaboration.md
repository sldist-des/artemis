# TKT-057 - Guided Human Collaboration Mode do ARTEMIS Symphony

## Objetivo

Criar uma entrada guiada para humanos escolherem projeto, tarefa, perfil de
agente, gates, custo/risco e evidencia esperada antes de qualquer execucao real.

## Escopo

- Criar `scripts/artemis-guided-collaboration.sh`.
- Gerar artifact read-only em `artifacts/artemis-guided-collaboration/run-01/`.
- Expor o modo guiado no Control Plane.
- Registrar evento canonico `evt_tkt-057_guided_collaboration`.
- Conectar o modo guiado ao Validation Gate e ao Event Log.

## Fora de escopo

- iniciar agentes Codex ou Claude Code;
- chamar app-server, SDK, MCP, browser remoto ou daemon persistente;
- autenticar contas;
- criar issues, PRs, pushes ou configuracoes remotas;
- executar tarefas reais;
- aprovar Human Gates automaticamente.

## Validacao esperada

- `scripts/artemis-guided-collaboration.sh --artifact-root artifacts/artemis-guided-collaboration/run-01 --json`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `scripts/validate-artemis.sh`
- `git diff --check`

## Handoff

O proximo corte e `TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony`,
materializando o contrato de lancamento como dry-run auditavel antes de qualquer
runtime real.
