# TKT-116 - ARTEMIS Model/API Change Intake

## Objetivo

Criar o intake formal para solicitações de mudança de modelo, API, SDK ou CLI
governadas pelo ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de mudanca de provider routing, custo e runtime.

## Agentes envolvidos

- Codex executor: change intake, template de solicitacao, artifacts, evento,
  grafo e validacao.
- Humano owner: autoridade futura para aceitar, rejeitar ou diferir uma
  solicitacao de mudanca.

## Resultado esperado

O metodo passa a diferenciar "existe uma fonte a revisar" de "existe uma
solicitacao de mudanca pronta para revisao". Nenhuma migracao ocorre neste
corte.

## Escopo

- Consumir o Documentation Radar.
- Emitir template de change request.
- Exigir provider e capability role registrados.
- Exigir evidencias de docs oficiais, probe local, eval operacional, budget e
  rollback.
- Manter review, migracao, default change, runtime, gasto e remoto bloqueados.

## Fora de escopo

- Preencher uma solicitacao real.
- Aprovar review.
- Alterar bindings de modelo.
- Rodar evals reais.
- Chamar APIs ou gastar tokens.
- Fazer push ou mutacao remota.

## Arquivos

- `scripts/artemis-model-change-intake.sh`
- `artifacts/artemis-model-api-change-intake/run-01/model-api-change-intake.json`
- `artifacts/artemis-model-api-change-intake/run-01/model-api-change-request-template.json`
- `artifacts/artemis-model-api-change-intake/run-01/MODEL_API_CHANGE_INTAKE.md`
- `artifacts/artemis-model-api-change-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-change-intake.sh
scripts/artemis-model-change-intake.sh --artifact-root artifacts/artemis-model-api-change-intake/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-change-intake/run-01/model-api-change-intake.json
python3 -m json.tool artifacts/artemis-model-api-change-intake/run-01/model-api-change-request-template.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-change-intake/run-01/model-api-change-intake.json`
- `artifacts/artemis-model-api-change-intake/run-01/model-api-change-request-template.json`
- `artifacts/artemis-model-api-change-intake/run-01/MODEL_API_CHANGE_INTAKE.md`
- `artifacts/artemis-model-api-change-intake/run-01/events.json`

## Handoff

Handoff aceito quando o intake reportar `model_api_change_intake_ready`, com
`change_intake_state: waiting_for_docs_review_evidence`,
`request_recorded: false`, `change_review_allowed: false`,
`migration_allowed: false` e `default_model_change_allowed: false`.
