# TKT-072 - ARTEMIS Portal Auth Plan

## Objetivo

Definir como o futuro ARTEMIS Portal deve autenticar humanos, conectar
provedores de agente, gerenciar agents e preservar Human Gates antes de qualquer
execucao real com Codex app-server, Claude Code/Agent SDK, GitHub ou infra.

## Resultado esperado

Um contrato verificavel deve separar Portal Auth, Provider Auth e
Project/Runtime Auth, exigir Credential Vault antes de tokens reais e definir
roles, gates, custo, agent states e adapters.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal e seguranca operacional.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md`
- `scripts/artemis-portal-auth-plan.sh`
- `docs/control-plane/artemis-control-plane.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md`
- `ARTEMIS_INTEGRATIONS.md`

## Escopo

- Definir as tres camadas de auth.
- Definir roles do portal.
- Definir conexoes OpenAI/Codex, Anthropic/Claude e GitHub.
- Definir Credential Vault como requisito antes de auth real.
- Definir Agent Management, gates obrigatorios e Cost/Token Ledger.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Implementar login real.
- Armazenar tokens.
- Criar MCP/REST server.
- Iniciar Codex app-server.
- Iniciar Claude Code/Agent SDK.
- Criar GitHub App.
- Executar agentes pagos ou remotos.

## Invariantes

- `AGENTS.md` continua fonte canonica.
- Portal nao substitui Exec Packs, Git, artifacts ou Validation Gate.
- Agentes nunca recebem secrets longos diretamente.
- Provider auth e Project/runtime auth exigem Human Gate.
- Remote writes continuam bloqueados por padrao.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-auth-plan.sh
scripts/artemis-portal-auth-plan.sh --artifact-root artifacts/artemis-portal-auth-plan/run-01 --json
python3 -m json.tool artifacts/artemis-portal-auth-plan/run-01/portal-auth-plan.json
python3 -m json.tool artifacts/artemis-portal-auth-plan/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-auth-plan/run-01/portal-auth-plan.json`
- `artifacts/artemis-portal-auth-plan/run-01/PORTAL_AUTH_PLAN.md`
- `artifacts/artemis-portal-auth-plan/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de auth do portal estiver documentado,
artifactado, validado e sem execucao real de auth, secrets, agentes ou remoto.
