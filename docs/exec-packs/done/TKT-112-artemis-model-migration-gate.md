# TKT-112 - ARTEMIS Model Migration Gate

## Objetivo

Criar o gate que impede migracoes de modelo/API sem docs oficiais, probes,
evals, custo e decisao humana.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de mudanca de default e seguranca operacional.

## Agentes envolvidos

- Codex executor: migration gate, template de decisao, artifacts e validacao.
- Humano owner: autoridade futura para aprovar migracoes.

## Resultado esperado

Atualizacoes de modelos e APIs deixam de ser alteracoes ad hoc e passam a ser
decisoes versionadas com evidencia.

## Escopo

- Consumir registry e provider probes.
- Emitir estado `waiting_for_external_model_review`.
- Exigir docs oficiais atualizadas, evals, impacto de budget e decisao humana.
- Bloquear mudanca de default.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Buscar docs externas.
- Aprovar migracao real.
- Alterar `AGENTS.md` ou configs runtime para novo modelo.
- Rodar provider runtime.
- Gastar tokens.

## Arquivos

- `scripts/artemis-model-migration-gate.sh`
- `artifacts/artemis-model-migration-gate/run-01/model-migration-gate.json`
- `artifacts/artemis-model-migration-gate/run-01/MODEL_MIGRATION_GATE.md`
- `artifacts/artemis-model-migration-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-model-migration-gate.sh
scripts/artemis-model-migration-gate.sh --artifact-root artifacts/artemis-model-migration-gate/run-01 --json
python3 -m json.tool artifacts/artemis-model-migration-gate/run-01/model-migration-gate.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-model-migration-gate/run-01/model-migration-gate.json`
- `artifacts/artemis-model-migration-gate/run-01/MODEL_MIGRATION_GATE.md`
- `artifacts/artemis-model-migration-gate/run-01/events.json`

## Handoff

Handoff aceito quando o gate reportar `model_migration_gate_ready`, com
`migration_allowed: false`, `default_model_change_allowed: false` e estado
`waiting_for_external_model_review`.
