# TKT-113 - ARTEMIS Provider Operational Evals

## Objetivo

Definir a suite minima de evals operacionais que um provider/model binding deve
passar antes de virar default.

## Nivel ARTEMIS da execucao

Nivel 2 - qualidade, validacao e promocao de provider.

## Agentes envolvidos

- Codex executor: suite de evals, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para aceitar resultados de eval.

## Resultado esperado

O ARTEMIS passa a validar comportamento pratico de modelo/API antes de confiar
em release notes ou marketing.

## Escopo

- Definir evals de repo map, plano, patch seguro, validacao, budget e fronteira
  de subagente.
- Manter evals como especificacao, sem rodar provider.
- Vincular promocao ao migration gate.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Rodar evals reais em modelos.
- Chamar APIs.
- Autenticar provider.
- Promover modelo default.
- Gastar tokens.

## Arquivos

- `scripts/artemis-provider-operational-evals.sh`
- `artifacts/artemis-provider-operational-evals/run-01/provider-operational-evals.json`
- `artifacts/artemis-provider-operational-evals/run-01/PROVIDER_OPERATIONAL_EVALS.md`
- `artifacts/artemis-provider-operational-evals/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-provider-operational-evals.sh
scripts/artemis-provider-operational-evals.sh --artifact-root artifacts/artemis-provider-operational-evals/run-01 --json
python3 -m json.tool artifacts/artemis-provider-operational-evals/run-01/provider-operational-evals.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-provider-operational-evals/run-01/provider-operational-evals.json`
- `artifacts/artemis-provider-operational-evals/run-01/PROVIDER_OPERATIONAL_EVALS.md`
- `artifacts/artemis-provider-operational-evals/run-01/events.json`

## Handoff

Handoff aceito quando a suite reportar
`provider_operational_evals_ready`, com `evals_runtime_executed: false` e
promocao bloqueada ate o migration gate.
