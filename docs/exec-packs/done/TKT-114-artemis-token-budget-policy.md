# TKT-114 - ARTEMIS Token Budget Policy

## Objetivo

Criar a politica de budget/token por classe de tarefa para governar provider
routing e execucoes futuras.

## Nivel ARTEMIS da execucao

Nivel 3 - custo, runtime e limite de automacao.

## Agentes envolvidos

- Codex executor: budget policy, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para liberar gasto acima dos limites.

## Resultado esperado

Toda execucao provider-backed precisa declarar capability role, binding de
provider e budget class antes do runtime.

## Escopo

- Definir classes `fast_probe`, `verification_slice`, `standard_slice`,
  `frontier_guarded` e `supervised_async`.
- Exigir ledger antes de runtime.
- Exigir hard stop e gate humano acima do limite.
- Bloquear gasto real por default.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Consultar billing real.
- Converter valores para moeda real.
- Autorizar gasto.
- Rodar agents.
- Chamar APIs ou gastar tokens.

## Arquivos

- `scripts/artemis-token-budget-policy.sh`
- `artifacts/artemis-token-budget-policy/run-01/model-token-budget-policy.json`
- `artifacts/artemis-token-budget-policy/run-01/MODEL_TOKEN_BUDGET_POLICY.md`
- `artifacts/artemis-token-budget-policy/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-token-budget-policy.sh
scripts/artemis-token-budget-policy.sh --artifact-root artifacts/artemis-token-budget-policy/run-01 --json
python3 -m json.tool artifacts/artemis-token-budget-policy/run-01/model-token-budget-policy.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-token-budget-policy/run-01/model-token-budget-policy.json`
- `artifacts/artemis-token-budget-policy/run-01/MODEL_TOKEN_BUDGET_POLICY.md`
- `artifacts/artemis-token-budget-policy/run-01/events.json`

## Handoff

Handoff aceito quando a politica reportar
`model_token_budget_policy_ready`, com `spend_authorized: false`,
`runtime_execution_allowed: false`, hard stop exigido e ledger obrigatorio antes
do runtime.
