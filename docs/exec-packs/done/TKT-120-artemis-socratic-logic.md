# TKT-120 - ARTEMIS Socratic Logic

## Objetivo

Adicionar ao metodo ARTEMIS uma camada socratica geral para reduzir
ambiguidade, separar termos, premissas, conclusoes e autoridade, e orientar
perguntas claras para humano e agentes.

## Nivel ARTEMIS da execucao

Nivel 3 - governanca de metodo, decisao e coerencia operacional.

## Agentes envolvidos

- Codex executor: contrato socratico, artifacts, grafo e validacao.
- Humano owner: autoridade para decidir quando uma pergunta muda escopo ou
  risco.

## Resultado esperado

O metodo passa a ter um gate de clareza antes de plano, delegacao, runtime,
review, decisao humana ou handoff. Perguntas ao humano ficam curtas, distintas
e ligadas ao impacto pratico.

## Escopo

- Criar `docs/principles/ARTEMIS_SOCRATIC_LOGIC.md`.
- Criar `scripts/artemis-socratic-logic.sh`.
- Gerar artifact canonico de perguntas, contrato de argumento e ambiguity
  gates.
- Expor a Logica Socratica no Project Graph, Event Log e comandos canonicos.
- Manter runtime, agentes, tokens e remoto bloqueados.

## Fora de escopo

- Iniciar agentes.
- Enviar prompt para providers.
- Rodar runtime remoto.
- Fazer mudanca em producao.
- Alterar secrets.

## Arquivos

- `docs/principles/ARTEMIS_SOCRATIC_LOGIC.md`
- `scripts/artemis-socratic-logic.sh`
- `artifacts/artemis-socratic-logic/run-01/socratic-logic.json`
- `artifacts/artemis-socratic-logic/run-01/SOCRATIC_LOGIC.md`
- `artifacts/artemis-socratic-logic/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-socratic-logic.sh
scripts/artemis-socratic-logic.sh --artifact-root artifacts/artemis-socratic-logic/run-01 --json
python3 -m json.tool artifacts/artemis-socratic-logic/run-01/socratic-logic.json
python3 -m json.tool artifacts/artemis-socratic-logic/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-socratic-logic/run-01/socratic-logic.json`
- `artifacts/artemis-socratic-logic/run-01/SOCRATIC_LOGIC.md`
- `artifacts/artemis-socratic-logic/run-01/events.json`

## Handoff

Handoff aceito quando `artemis_socratic_logic_ready` estiver registrado com
perguntas de clareza, contrato de argumento, ambiguity gates, policy de
perguntas e zero runtime side effects.
