# TKT-110 - ARTEMIS Model/API Governance Registry

## Objetivo

Criar o registro canonico de governanca para modelos, APIs, CLIs e SDKs usados
pelo ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de arquitetura, provider routing e custo.

## Agentes envolvidos

- Codex executor: registry, script, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para aprovar mudancas de default.

## Resultado esperado

O metodo passa a rotear por `capability_role`, nao por nome fixo de modelo.
Modelos reais viram bindings versionados e migraveis por gate.

## Escopo

- Criar `config/artemis-model-registry.json`.
- Documentar a governanca em `docs/models/ARTEMIS_MODEL_API_GOVERNANCE.md`.
- Criar `scripts/artemis-model-registry.sh`.
- Emitir artifacts e evento canonico.
- Manter auth, APIs, agentes, tokens e remoto bloqueados.

## Fora de escopo

- Consultar docs externas em runtime.
- Chamar APIs de provider.
- Autenticar Codex, Claude Code ou Antigravity.
- Alterar modelo default real.
- Gastar tokens.

## Arquivos

- `config/artemis-model-registry.json`
- `docs/models/ARTEMIS_MODEL_API_GOVERNANCE.md`
- `scripts/artemis-model-registry.sh`
- `scripts/artemis_model_governance_common.py`
- `artifacts/artemis-model-api-governance-registry/run-01/model-api-governance-registry.json`
- `artifacts/artemis-model-api-governance-registry/run-01/MODEL_API_GOVERNANCE_REGISTRY.md`
- `artifacts/artemis-model-api-governance-registry/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-registry.sh
python3 -m json.tool config/artemis-model-registry.json
scripts/artemis-model-registry.sh --artifact-root artifacts/artemis-model-api-governance-registry/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-governance-registry/run-01/model-api-governance-registry.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-governance-registry/run-01/model-api-governance-registry.json`
- `artifacts/artemis-model-api-governance-registry/run-01/MODEL_API_GOVERNANCE_REGISTRY.md`
- `artifacts/artemis-model-api-governance-registry/run-01/events.json`

## Handoff

Handoff aceito quando o registry reportar
`model_api_governance_registry_ready`, com provedores, capability roles e
regras de migracao registradas sem chamadas de API, auth, agentes, tokens ou
remoto.
