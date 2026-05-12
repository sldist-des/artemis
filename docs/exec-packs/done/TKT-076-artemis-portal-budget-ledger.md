# TKT-076 - ARTEMIS Portal Budget and Cost Ledger Contract

## Objetivo

Definir o contrato de Budget and Cost Ledger do ARTEMIS Portal para vincular um
Run Assignment a limites explicitos de token, custo, duracao e numero de
agentes antes de qualquer launcher, runtime ou gasto real.

## Resultado esperado

Um contrato verificavel deve definir budget policies, schema append-only de cost
ledger, campos proibidos, estados, thresholds de Human Gate, hard stops,
evidencia e handoff sem consultar billing real nem gastar tokens.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md`
- `docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md`
- `scripts/artemis-portal-budget-ledger.sh`
- `artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json`

## Escopo

- Definir Budget and Cost Ledger como contrato pre-runtime.
- Definir budget policies iniciais para frontier, slice medio e verificacao.
- Definir schema append-only de ledger.
- Definir campos proibidos para impedir secrets, billing bruto e output bruto
  de runtime.
- Definir estados e hard stops antes de gasto real.
- Definir thresholds de Human Gate para custo estimado.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Consultar billing real.
- Autenticar providers.
- Emitir vault lease real.
- Iniciar agente real.
- Executar comando.
- Gastar tokens.
- Criar scheduler real.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Budget aprovado nao e permissao de execucao.
- Ledger nao guarda segredo.
- Ledger nao guarda credencial ou invoice bruto de provider.
- Run Assignment precisa resolver budget policy conhecida.
- Human Gate precede custo acima de threshold.
- Hard stop precede gasto fora de limite.
- Remote write segue bloqueado por padrao.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-budget-ledger.sh
scripts/artemis-portal-budget-ledger.sh --artifact-root artifacts/artemis-portal-budget-ledger/run-01 --json
python3 -m json.tool artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json
python3 -m json.tool artifacts/artemis-portal-budget-ledger/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json`
- `artifacts/artemis-portal-budget-ledger/run-01/BUDGET_LEDGER.md`
- `artifacts/artemis-portal-budget-ledger/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Budget and Cost Ledger estiver documentado,
artifactado, validado e sem billing real, provider auth, lease real, runtime,
comandos, gasto de token ou mutacao remota.
