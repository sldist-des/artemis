# ARTEMIS Socratic Logic

## Objetivo

A Logica Socratica do ARTEMIS existe para impedir execucao em cima de termos
confusos, premissas escondidas, conclusoes misturadas ou perguntas vagas.

Ela nao e um modo de conversar mais. E um gate de coerencia antes de plano,
delegacao, runtime, review, decisao humana ou handoff.

## Regra curta

Antes de agir, o agente precisa saber:

1. Qual resultado unico esta buscando.
2. Quais termos podem ter mais de um sentido.
3. Quais premissas esta usando como verdade.
4. Quais conceitos precisam ficar distintos.
5. Quem ou qual artefato tem autoridade.
6. Qual evidencia provaria a conclusao.
7. Que fato derrubaria a conclusao.
8. Se a proxima acao e observacao, inferencia, decisao ou execucao.
9. Como entregar o handoff sem ambiguidade.

## Perguntas para humano

O agente pergunta ao humano quando a resposta muda escopo, risco, custo,
autoridade ou arquivo de escrita.

A pergunta deve ser curta e conter:

- o termo ou decisao ambigua;
- duas ou tres opcoes distintas;
- o impacto pratico de cada opcao.

Nao perguntar quando uma validacao local segura resolve a duvida ou quando uma
suposicao declarada nao altera risco.

## Contrato de argumento

Toda conclusao importante deve separar:

- `objective`: resultado buscado;
- `defined_terms`: termos e significados usados;
- `premises`: premissas e fontes;
- `distinctions`: conceitos que nao podem ser misturados;
- `evidence`: comandos, arquivos, gates ou artifacts;
- `inference`: interpretacao feita a partir da evidencia;
- `conclusion`: afirmacao final;
- `confidence`: confianca e limites;
- `counterexample`: fato que derrubaria a conclusao;
- `next_action`: proximo passo permitido.

## Escada de conclusao

- Observacao: fato visto em arquivo, comando ou artifact.
- Inferencia: interpretacao derivada de observacoes.
- Decisao: escolha com autoridade explicita.
- Compromisso: promessa operacional registrada em Exec Pack ou gate.
- Execucao: mudanca aplicada e validada.

## Colapsos proibidos

- Hipotese como fato.
- Preferencia como requisito.
- Fixture como autorizacao real.
- Template pendente como decisao.
- Validacao tecnica como aceite humano.
- Painel observacional como fonte canonica.

## Uso por agentes

- Codex usa este gate antes de editar codigo quando escopo, termo, autoridade
  ou validacao puderem mudar o resultado.
- Claude Code usa este gate para mapear diretorio, linguagem, limites e
  handoff antes de tarefas medias.
- Antigravity CLI exige escopo, permissao herdada, budget e Human Gate antes de
  qualquer lane assincrona ou ampla.

## Artefato canonico

```bash
scripts/artemis-socratic-logic.sh --json
```

Saida principal:

- `artifacts/artemis-socratic-logic/run-01/socratic-logic.json`
- `artifacts/artemis-socratic-logic/run-01/SOCRATIC_LOGIC.md`
- `artifacts/artemis-socratic-logic/run-01/STATUS.md`
- `artifacts/artemis-socratic-logic/run-01/VALIDATION.md`
- `artifacts/artemis-socratic-logic/run-01/HANDOFF.md`
- `artifacts/artemis-socratic-logic/run-01/events.json`
