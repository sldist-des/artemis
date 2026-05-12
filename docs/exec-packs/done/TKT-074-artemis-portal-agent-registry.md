# TKT-074 - ARTEMIS Portal Agent Registry Contract

## Objetivo

Definir o contrato do Agent Registry do ARTEMIS Portal para escolher agentes
supervisionados por perfil, capability, budget, workspace, vault lease e
validacao.

## Resultado esperado

Um contrato verificavel deve registrar perfis iniciais de agente, campos
obrigatorios, campos proibidos, capabilities, limites, estados e regras de
assignment antes de qualquer runtime real com Codex, Claude Code ou outros
providers.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md`
- `docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md`
- `docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md`
- `scripts/artemis-portal-agent-registry.sh`
- `artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json`

## Escopo

- Definir Agent Registry como catalogo de perfis, nao como runtime livre.
- Definir perfis iniciais para Codex, Claude Code e verificador ARTEMIS.
- Definir campos obrigatorios e campos proibidos.
- Definir capability catalog e capabilities perigosas.
- Definir state model de disponibilidade e execucao.
- Definir regras de assignment, budget, vault lease, workspace e validacao.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Autenticar providers.
- Emitir vault lease real.
- Iniciar agente real.
- Gastar tokens.
- Criar scheduler real.
- Criar banco real de registry.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Perfil de agente nao recebe segredo longo.
- Modelo concreto vem de policy; seguranca nao depende de nome fixo de modelo.
- Capability perigosa e deny-by-default.
- Budget policy precede gasto.
- Vault lease precede runtime provider-backed.
- Um escritor por worktree.
- Verificador nao valida sua propria execucao sem separacao de review.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-agent-registry.sh
scripts/artemis-portal-agent-registry.sh --artifact-root artifacts/artemis-portal-agent-registry/run-01 --json
python3 -m json.tool artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json
python3 -m json.tool artifacts/artemis-portal-agent-registry/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json`
- `artifacts/artemis-portal-agent-registry/run-01/AGENT_REGISTRY.md`
- `artifacts/artemis-portal-agent-registry/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato do Agent Registry estiver documentado,
artifactado, validado e sem provider auth, lease real, runtime, gasto de token
ou mutacao remota.
