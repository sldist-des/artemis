# TKT-115 - ARTEMIS Model/API Documentation Radar

## Objetivo

Criar o radar de documentacao oficial para mudancas de modelos, APIs, SDKs e
CLIs usados pelo ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de atualizacao, provider routing e migracao segura.

## Agentes envolvidos

- Codex executor: documentation radar, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para revisar fontes oficiais e liberar
  intake de mudanca.

## Resultado esperado

O ARTEMIS passa a ter uma lista verificavel de fontes oficiais e de evidencias
necessarias antes de qualquer migracao de modelo/API.

## Escopo

- Consumir `config/artemis-model-registry.json`.
- Mapear `refresh_sources` de Codex, Claude Code e Antigravity.
- Exigir revisao de docs oficiais, release notes quando aplicavel e probe local.
- Emitir template de registro de revisao.
- Bloquear migracao, troca de default, auth, APIs, agentes, tokens e remoto.

## Fora de escopo

- Buscar docs externas automaticamente.
- Confirmar que docs estao atuais.
- Aprovar migracao.
- Alterar modelo default.
- Chamar APIs ou gastar tokens.

## Arquivos

- `scripts/artemis-model-docs-radar.sh`
- `artifacts/artemis-model-api-documentation-radar/run-01/model-api-documentation-radar.json`
- `artifacts/artemis-model-api-documentation-radar/run-01/MODEL_API_DOCUMENTATION_RADAR.md`
- `artifacts/artemis-model-api-documentation-radar/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-docs-radar.sh
scripts/artemis-model-docs-radar.sh --artifact-root artifacts/artemis-model-api-documentation-radar/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-documentation-radar/run-01/model-api-documentation-radar.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-documentation-radar/run-01/model-api-documentation-radar.json`
- `artifacts/artemis-model-api-documentation-radar/run-01/MODEL_API_DOCUMENTATION_RADAR.md`
- `artifacts/artemis-model-api-documentation-radar/run-01/events.json`

## Handoff

Handoff aceito quando o radar reportar
`model_api_documentation_radar_ready`, com
`docs_radar_state: waiting_for_official_docs_review`,
`external_fetch_executed: false`, `official_docs_reviewed: false` e
`migration_allowed: false`.
