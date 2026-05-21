# TKT-118 - ARTEMIS Model/API Review Gate

## Objetivo

Separar explicitamente a fixture sintetica de review da autoridade real de
review de modelo/API, emitindo um template humano sem liberar migracao,
default change, runtime ou gasto.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de mudanca de modelo/API e autoridade humana.

## Agentes envolvidos

- Codex executor: gate de review, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para preencher e aprovar review real.

## Resultado esperado

O metodo reconhece que a fixture prova apenas formato e fronteira. O proximo
passo passa a ser registrar review real com evidencia oficial, probes, evals,
budget e atestacao humana.

## Escopo

- Consumir a Review Fixture.
- Validar que a fixture nao registrou review real nem liberou migracao.
- Gerar `model-api-real-review-template.json`.
- Manter review decision intake, migracao, default change, runtime, gasto e
  remoto bloqueados.
- Expor o gate no grafo, event log e Control Plane.

## Fora de escopo

- Revisar docs oficiais de verdade.
- Registrar review real.
- Autorizar Review Decision Intake.
- Aprovar migracao.
- Alterar binding de modelo.
- Rodar evals reais.
- Chamar APIs ou gastar tokens.

## Arquivos

- `scripts/artemis-model-review-gate.sh`
- `artifacts/artemis-model-api-review-gate/run-01/model-api-review-gate.json`
- `artifacts/artemis-model-api-review-gate/run-01/model-api-real-review-template.json`
- `artifacts/artemis-model-api-review-gate/run-01/MODEL_API_REVIEW_GATE.md`
- `artifacts/artemis-model-api-review-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-review-gate.sh
scripts/artemis-model-review-gate.sh --artifact-root artifacts/artemis-model-api-review-gate/run-01 --json
python3 -m json.tool artifacts/artemis-model-api-review-gate/run-01/model-api-review-gate.json
python3 -m json.tool artifacts/artemis-model-api-review-gate/run-01/model-api-real-review-template.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-api-review-gate/run-01/model-api-review-gate.json`
- `artifacts/artemis-model-api-review-gate/run-01/model-api-real-review-template.json`
- `artifacts/artemis-model-api-review-gate/run-01/MODEL_API_REVIEW_GATE.md`
- `artifacts/artemis-model-api-review-gate/run-01/events.json`

## Handoff

Handoff aceito quando o gate reportar `model_api_review_gate_ready`,
`review_gate_state: waiting_for_real_model_review`,
`fixture_boundary_valid: true`, `real_review_recorded: false`,
`review_decision_intake_allowed: false`, `migration_allowed: false`,
`runtime_execution_allowed: false` e `tokens_spent: 0`.
