# TKT-073 - ARTEMIS Portal Credential Vault Contract

## Objetivo

Definir o contrato do Credential Vault do ARTEMIS Portal antes de qualquer auth
real com Codex app-server, Claude Code/Agent SDK, GitHub ou infra.

## Resultado esperado

Um contrato verificavel deve definir storage boundary, metadados de credencial,
campos proibidos, escopo deny-by-default, leases curtos, auditoria, rotacao,
revogacao e gates antes de uso por Runner Adapters.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md`
- `docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md`
- `scripts/artemis-portal-credential-vault.sh`
- `artifacts/artemis-portal-auth-plan/run-01/portal-auth-plan.json`

## Escopo

- Definir storage boundary.
- Definir schema conceitual de credential record.
- Definir forbidden fields para impedir secrets em artifacts.
- Definir scope model e lease model.
- Definir audit events e campos obrigatorios.
- Definir rotacao, revogacao e gates.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Armazenar segredo real.
- Criar tabela/banco real.
- Escolher fornecedor final de vault.
- Implementar criptografia.
- Emitir lease real.
- Autenticar OpenAI, Anthropic, GitHub ou infra.
- Iniciar agentes pagos ou remotos.

## Invariantes

- Agentes nunca recebem secrets longos diretamente.
- Prompt, Exec Pack, artifact, evento e log nunca registram segredo.
- Escopo padrao e deny.
- Remote write exige gate separado.
- Vault nao substitui Portal Auth, Project Auth, Validation Gate ou Human Gate.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-credential-vault.sh
scripts/artemis-portal-credential-vault.sh --artifact-root artifacts/artemis-portal-credential-vault/run-01 --json
python3 -m json.tool artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json
python3 -m json.tool artifacts/artemis-portal-credential-vault/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json`
- `artifacts/artemis-portal-credential-vault/run-01/CREDENTIAL_VAULT.md`
- `artifacts/artemis-portal-credential-vault/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato do vault estiver documentado, artifactado,
validado e sem secret real, auth real, lease real ou mutacao remota.
