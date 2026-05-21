# TKT-117 - ARTEMIS Model/API Review Fixture

## Objetivo

Criar uma fixture sintetica que prove o caminho positivo do Model/API Change
Intake sem autorizar review real, migracao ou troca de default.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de mudanca de modelo/API e autoridade humana.

## Agentes envolvidos

- Codex executor: fixture de review, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para registrar review real.

## Resultado esperado

O metodo prova que uma solicitacao completa pode ser aceita para review em
formato valido, mas deixa claro que a fixture e evidencia sintetica.

## Escopo

- Consumir o Change Intake.
- Gerar fixture de docs review.
- Gerar fixture de change request `accepted_for_review`.
- Validar provider e capability role contra o registry.
- Manter review real, migracao, default change, runtime, gasto e remoto
  bloqueados.

## Fora de escopo

- Revisar docs oficiais de verdade.
- Registrar decisao humana real.
- Aprovar migracao.
- Alterar binding de modelo.
- Rodar evals reais.
- Chamar APIs ou gastar tokens.

## Arquivos

- `scripts/artemis-model-review-fixture.sh`
- `artifacts/artemis-model-api-review-fixture/run-01/model-api-review-fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/model-api-change-request.fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/synthetic-docs-review.fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/MODEL_API_REVIEW_FIXTURE.md`
- `artifacts/artemis-model-api-review-fixture/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-review-fixture.sh
scripts/artemis-model-review-fixture.sh --artifact-root artifacts/artemis-model-api-review-fixture/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-review-fixture/run-01/model-api-review-fixture.json
python3 -m json.tool artifacts/artemis-model-api-review-fixture/run-01/model-api-change-request.fixture.json
python3 -m json.tool artifacts/artemis-model-api-review-fixture/run-01/synthetic-docs-review.fixture.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-review-fixture/run-01/model-api-review-fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/model-api-change-request.fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/synthetic-docs-review.fixture.json`
- `artifacts/artemis-model-api-review-fixture/run-01/MODEL_API_REVIEW_FIXTURE.md`
- `artifacts/artemis-model-api-review-fixture/run-01/events.json`

## Handoff

Handoff aceito quando a fixture reportar `model_api_review_fixture_ready`, com
`synthetic_fixture_only: true`, `accepted_for_review_fixture: true`,
`real_review_recorded: false`, `change_review_allowed: false` e
`migration_allowed: false`.
