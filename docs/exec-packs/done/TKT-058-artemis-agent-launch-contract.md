# TKT-058 - Supervised Agent Launch Contract do ARTEMIS Symphony

## Nivel ARTEMIS da execucao

Nivel 3 - Alto impacto operacional, sem runtime real.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Objetivo

Criar o contrato supervisionado que deve existir antes de qualquer lancamento real de Codex app-server, Claude Code, Codex terminal-first ou agentes futuros pelo ARTEMIS Symphony.

## Resultado esperado

O ARTEMIS passa a ter um artifact canonico que explicita perfis de agente, gates, budget, auth, comando, workspace, rollback, evidencia e invariantes de seguranca antes de runtime.

## Escopo

- Criar `scripts/artemis-agent-launch-contract.sh`.
- Gerar artifact canonico em `artifacts/artemis-agent-launch-contract/run-01/`.
- Registrar evento canonico `evt_tkt-058_agent_launch_contract`.
- Renderizar o contrato no Control Plane.
- Integrar o contrato ao Event Log e Validation Gate.
- Atualizar docs do Symphony e handoff para o proximo corte.

## Fora de escopo

- Iniciar Codex app-server.
- Iniciar Claude Code.
- Chamar SDKs remotos.
- Executar agentes pagos.
- Fazer push, deploy, issue mutation ou qualquer escrita remota.
- Aprovar Human Gates.

## Evidencias obrigatorias

- `artifacts/artemis-agent-launch-contract/run-01/agent-launch-contract.json`
- `artifacts/artemis-agent-launch-contract/run-01/CONTRACT.md`
- `artifacts/artemis-agent-launch-contract/run-01/VALIDATION.md`
- `artifacts/artemis-validation-gate/run-01/validation-gate.json`
- `control-plane/index.html`

## Resultado

O contrato foi implementado como superficie read-only. Ele fixa `execute=false`, `agents_started=0`, `runtime_started=false`, `commands_executed=0` e `remote_writes_allowed=false`.

O proximo corte e `TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`.
