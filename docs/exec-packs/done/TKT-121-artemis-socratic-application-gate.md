# TKT-121 - ARTEMIS Socratic Application Gate

## Objetivo

Transformar a logica socratica do ARTEMIS em um gate operacional que escolha
uma rota clara antes de execucao, delegacao, runtime, review, aceite humano ou
handoff.

## Nivel ARTEMIS da execucao

Nivel 1 - contrato local, sem runtime real, sem provider, sem secrets, sem
tokens e sem escrita remota.

## Agentes envolvidos

- Codex executor: script, documento, artifacts, grafo, validacao e commit.

## Resultado esperado

O metodo deve declarar quando o agente pode seguir com suposicao explicita,
quando deve buscar evidencia local, quando deve perguntar ao humano, quando
deve dividir o corte e quando deve bloquear por falta de autoridade.

## Escopo

- Criar `docs/principles/ARTEMIS_SOCRATIC_APPLICATION_GATE.md`.
- Criar `scripts/artemis-socratic-application-gate.sh`.
- Gerar artifact JSON e Markdown do gate.
- Incluir o gate no Event Log, Project Graph, README, AGENTS e validacao.

## Fora de escopo

- Iniciar runtime.
- Chamar Codex, Claude Code, Antigravity CLI ou APIs de modelo.
- Enviar prompts a providers.
- Pedir ou armazenar secrets.
- Fazer deploy, push por runtime ou escrita remota automatica.
- Substituir Human Gate real.

## Invariantes

- A logica socratica classifica a proxima acao; ela nao concede autoridade.
- Fixture, template, painel e validacao tecnica continuam distintos de decisao
  humana.
- Uma pergunta humana deve ter opcoes distintas e impacto claro.
- Toda conclusao precisa de evidencia, autoridade ou suposicao explicitamente
  registrada.

## Evidencias obrigatorias

- `scripts/artemis-socratic-application-gate.sh`
- `artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json`
- `artifacts/artemis-socratic-application-gate/run-01/SOCRATIC_APPLICATION_GATE.md`
- `artifacts/artemis-socratic-application-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-socratic-application-gate.sh
scripts/artemis-socratic-application-gate.sh --artifact-root artifacts/artemis-socratic-application-gate/run-01 --json
python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json
python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/events.json
scripts/validate-artemis.sh
```

## Handoff

Handoff aceito quando `socratic_application_gate_ready` estiver registrado, com
rotas distintas, template de pergunta humana limitado a tres opcoes e efeitos
reais bloqueados.
