# ARTEMIS Socratic Logic

- Overall: `artemis_socratic_logic_ready`
- Questions: `9`
- Ambiguity gates: `5`
- Runtime execution allowed: `false`
- Agents started: `false`
- Tokens spent: `0`
- Next cut: `TKT-121 - Socratic Logic Application Gate`

## Clarity Questions

- `objective`: Qual resultado unico esta sendo buscado agora? Evidence: uma frase com artefato ou estado final verificavel.
- `terms`: Quais termos podem ter mais de um sentido nesta tarefa? Evidence: termo, significado usado e significado rejeitado.
- `premises`: Quais premissas estamos usando como verdade e de onde elas vieram? Evidence: premissa, fonte local ou decisao humana.
- `distinctions`: O que precisa ficar distinto para nao misturar conceitos? Evidence: par conceitual e criterio de separacao.
- `authority`: Quem ou qual artefato tem autoridade para decidir isto? Evidence: git, Exec Pack, Validation Gate, Human Gate ou documento canonico.
- `evidence`: Que evidencia provaria que a conclusao e correta? Evidence: comando, arquivo, gate ou artifact verificavel.
- `counterexample`: Que fato faria a conclusao cair? Evidence: contraexemplo, risco ou condicao de reversao.
- `decision`: A proxima acao e observacao, inferencia, decisao ou execucao? Evidence: uma categoria e o motivo.
- `handoff`: Como a resposta sera entregue sem deixar ambiguidade para humano ou agente? Evidence: estado, evidencia, limites e proximo passo.

## Argument Contract

- `objective`
- `defined_terms`
- `premises`
- `distinctions`
- `evidence`
- `inference`
- `conclusion`
- `confidence`
- `counterexample`
- `next_action`

## Ambiguity Gates

- `undefined_term`: termo central sem definicao operacional -> definir termo ou perguntar ao humano antes de executar.
- `mixed_authority`: duas fontes de autoridade competindo -> priorizar hierarquia ARTEMIS e registrar a decisao.
- `multi_outcome`: mais de um resultado final no mesmo corte -> dividir em cortes ou escolher um objetivo unico.
- `conclusion_without_evidence`: conclusao sem comando, artifact, fonte ou decisao -> bloquear handoff ate existir evidencia.
- `category_error`: observacao, inferencia, decisao e execucao misturadas -> reescrever no conclusion_ladder antes de prosseguir.

## Question Policy

- Ask when: a resposta muda escopo, risco, custo, autoridade ou arquivo de escrita.
- Ask when: um termo central tem dois sentidos plausiveis.
- Ask when: a conclusao depende de informacao que nao existe no repositorio.
- Ask when: a acao pode tocar secrets, auth, remoto, producao, dinheiro ou permissao ampla.
- Do not ask when: a proxima acao e local, reversivel e coberta por contrato existente.
- Do not ask when: a lacuna pode virar suposicao declarada sem afetar risco.
- Do not ask when: a validacao local pode resolver a duvida com comando seguro.
