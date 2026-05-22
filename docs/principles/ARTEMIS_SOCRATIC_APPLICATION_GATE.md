# ARTEMIS Socratic Application Gate

Este gate aplica a logica socratica do ARTEMIS antes de execucao, delegacao,
runtime, review, aceite humano ou handoff.

Ele existe para impedir cinco confusoes frequentes:

- termo sem definicao virar requisito;
- inferencia virar fato;
- fixture virar autorizacao real;
- validacao tecnica virar aceite humano;
- painel observacional virar fonte canonica.

## Decisao operacional

Antes de agir, o agente escolhe exatamente uma rota:

- `proceed_with_explicit_assumption`: seguir localmente com suposicao
  registrada, quando a acao e reversivel, coberta por contrato e sem risco
  sensivel.
- `gather_local_evidence`: buscar evidencia em arquivo, script, artifact,
  teste ou gate local.
- `ask_human_one_question`: perguntar ao humano quando a resposta muda escopo,
  risco, autoridade, custo, permissao, producao ou aceite.
- `split_into_next_cut`: separar quando existem dois resultados, dependencias
  independentes ou mais de um escritor.
- `block_until_authority_exists`: bloquear quando falta autoridade, evidencia,
  Human Gate ou ha erro de categoria.

## Pergunta humana

Quando a rota for perguntar, a pergunta deve ter:

- uma unica pergunta;
- termo ambiguo nomeado;
- duas ou tres opcoes distintas;
- impacto claro por opcao;
- recomendacao apenas quando houver evidencia.

Nao usar perguntas vagas, multiplas perguntas em uma frase ou opcoes que se
sobrepoem.

## Regra para agentes

Codex, Claude Code e Antigravity CLI devem usar este gate antes de abrir lanes,
subagentes, runtime ou mudancas com autoridade ambigua.

O gate nao autoriza execucao real. Ele classifica a proxima acao. Se a proxima
acao envolver secrets, auth, remoto, producao, dinheiro, permissao ampla,
runtime real ou token spend, a decisao humana explicita continua obrigatoria.

## Comando canonico

```bash
scripts/artemis-socratic-application-gate.sh --json
```

Artefatos esperados:

- `artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json`
- `artifacts/artemis-socratic-application-gate/run-01/SOCRATIC_APPLICATION_GATE.md`
- `artifacts/artemis-socratic-application-gate/run-01/STATUS.md`
- `artifacts/artemis-socratic-application-gate/run-01/VALIDATION.md`
- `artifacts/artemis-socratic-application-gate/run-01/HANDOFF.md`
- `artifacts/artemis-socratic-application-gate/run-01/events.json`
