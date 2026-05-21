# TKT-119 - ARTEMIS Model/API Review Decision Intake

## Objetivo

Criar a superficie de intake da decisao humana sobre um review real de
modelo/API, mantendo a decisao pendente por padrao e sem liberar migracao,
runtime, gasto ou troca de default.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de mudanca de modelo/API e autoridade humana.

## Agentes envolvidos

- Codex executor: decision intake, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para registrar a decisao real.

## Resultado esperado

O metodo mostra quais campos uma decisao real precisa conter e classifica o
estado atual como pendente. Uma aprovacao futura pode alimentar um gate
posterior, mas este corte nao altera binding, nao inicia runtime e nao gasta
tokens.

## Escopo

- Consumir o Model/API Review Gate.
- Gerar `model-api-review-decision-template.json`.
- Classificar o estado default como `pending`.
- Manter `approved_for_migration_gate`, migracao, default change, runtime,
  gasto e remoto bloqueados.
- Expor o intake no grafo, event log e Control Plane.

## Fora de escopo

- Registrar decisao humana real.
- Aprovar migracao.
- Alterar binding de modelo.
- Rodar evals reais.
- Autenticar provider.
- Chamar APIs ou gastar tokens.
- Fazer push.

## Arquivos

- `scripts/artemis-model-review-decision-intake.sh`
- `artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-intake.json`
- `artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-template.json`
- `artifacts/artemis-model-api-review-decision-intake/run-01/MODEL_API_REVIEW_DECISION_INTAKE.md`
- `artifacts/artemis-model-api-review-decision-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-review-decision-intake.sh
scripts/artemis-model-review-decision-intake.sh --artifact-root artifacts/artemis-model-api-review-decision-intake/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-intake.json
python3 -m json.tool artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-template.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-intake.json`
- `artifacts/artemis-model-api-review-decision-intake/run-01/model-api-review-decision-template.json`
- `artifacts/artemis-model-api-review-decision-intake/run-01/MODEL_API_REVIEW_DECISION_INTAKE.md`
- `artifacts/artemis-model-api-review-decision-intake/run-01/events.json`

## Handoff

Handoff aceito quando o intake reportar
`model_api_review_decision_intake_ready`, `review_decision_state: pending`,
`real_review_decision_recorded: false`, `approved_for_migration_gate: false`,
`migration_allowed: false`, `runtime_execution_allowed: false` e
`tokens_spent: 0`.
