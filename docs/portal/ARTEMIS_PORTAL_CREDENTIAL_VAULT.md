# ARTEMIS Portal Credential Vault

O Credential Vault e o limite de seguranca entre o ARTEMIS Portal e os
provedores externos. Ele deve guardar credenciais de OpenAI/Codex,
Anthropic/Claude, GitHub e infra sem expor secrets longos a agentes, prompts,
artifacts ou logs.

## Regra central

Agentes nao recebem tokens longos. Adapters supervisionados recebem leases
curtos, escopados e auditados.

```text
Human login
  -> Portal role
  -> Provider connection
  -> Credential Vault
  -> scoped short-lived lease
  -> Runner Adapter
  -> ARTEMIS gates and validation
```

## Storage boundary

Backends aceitaveis:

- cloud KMS com envelope encryption;
- HashiCorp Vault;
- AWS Secrets Manager;
- GCP Secret Manager;
- Azure Key Vault;
- banco proprio criptografado com KMS externo.

Controles minimos:

- criptografia em repouso;
- criptografia em transito;
- separacao de chave por tenant ou contexto;
- nenhum plaintext fora do vault;
- nenhum secret em prompts, Exec Packs, artifacts, logs ou eventos.

## Credential record

Metadados obrigatorios:

- `credential_id`
- `provider_id`
- `owner_type`
- `owner_id`
- `organization_id`
- `project_scope`
- `created_by`
- `created_at`
- `expires_at`
- `rotation_policy`
- `revocation_state`
- `allowed_adapters`
- `allowed_capabilities`
- `budget_policy_id`
- `human_gate_policy_id`

Campos proibidos fora do vault:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `password`
- `session_cookie`

## Scope model

Escopo deve ser deny-by-default e composto por:

- provider;
- organizacao;
- projeto;
- repositorio;
- ambiente;
- adapter;
- capability.

Exemplo: um token GitHub que permite ler issues nao deve automaticamente
permitir push, merge, CODEOWNERS ou branch protection.

## Lease model

O adapter pede um lease curto para uma capacidade especifica:

- TTL padrao: 15 minutos;
- TTL maximo: 60 minutos;
- renovacao exige gate;
- lease deve ser redigido em logs;
- revoke bloqueia novos leases e invalida execucoes pendentes.

## Audit model

Eventos obrigatorios:

- `credential.created`
- `credential.updated`
- `credential.rotated`
- `credential.revoked`
- `credential.lease_requested`
- `credential.lease_issued`
- `credential.lease_denied`
- `credential.lease_expired`

Campos de auditoria:

- `actor_user_id`
- `organization_id`
- `project_id`
- `provider_id`
- `credential_id`
- `adapter`
- `capability`
- `gate_id`
- `budget_policy_id`
- `result`
- `reason`
- `correlation_id`

Secret values e fragmentos de token nunca entram no audit log.

## Gates

Antes de emitir lease:

- `portal_login`
- `provider_connected`
- `credential_scope_checked`
- `budget_policy_checked`
- `human_gate_policy_checked`
- `lease_approved`
- `adapter_capability_allowed`
- `remote_write_approved` quando houver efeito externo.

## Fora de escopo neste corte

- armazenar segredo real;
- escolher provider final de vault;
- implementar criptografia;
- emitir lease real;
- autenticar Codex, Claude, GitHub ou infra;
- iniciar runtime.

Proximo corte recomendado: `TKT-074 - ARTEMIS Portal Agent Registry Contract`.
