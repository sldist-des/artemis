# ARTEMIS Socratic Application Gate

- Overall: `socratic_application_gate_ready`
- Logic input: `artemis_socratic_logic_ready`
- Application stages: `6`
- Routes: `5`
- Contexts: `6`
- Runtime execution allowed: `false`
- Agents started: `false`
- Tokens spent: `0`
- Next cut: `TKT-122 - External Operator Reference Intake`

## Routes

- `proceed_with_explicit_assumption`: Prosseguir sem perguntar quando a acao e local, reversivel, coberta por contrato existente e a suposicao nao muda risco.
- `gather_local_evidence`: Rodar verificacao local segura quando a duvida pode ser resolvida por arquivo, script, artifact ou teste.
- `ask_human_one_question`: Perguntar ao humano quando a resposta muda escopo, risco, autoridade, custo, permissao, producao ou resultado.
- `split_into_next_cut`: Separar a tarefa quando ha mais de um resultado final, mais de um escritor, ou validacoes independentes demais.
- `block_until_authority_exists`: Bloquear quando ha category error, autoridade ausente, conclusao sem evidencia ou acao sensivel sem Human Gate.

## Application Matrix

- `planning`: before exec pack or implementation plan is treated as approved; default `gather_local_evidence`.
- `code_edit`: before editing files when term, authority or validation may change implementation; default `proceed_with_explicit_assumption`.
- `delegation`: before launching Codex, Claude Code or Antigravity subagent lanes; default `ask_human_one_question`.
- `runtime`: before starting app-server, provider runtime, bridge, queue or daemon; default `block_until_authority_exists`.
- `review`: before declaring done, accepting review or closing a validation loop; default `gather_local_evidence`.
- `handoff`: before final response, Done Ledger or transfer to another agent; default `proceed_with_explicit_assumption`.

## Human Question Template

Qual caminho devo seguir para resolver a ambiguidade X?
- `recommended`: Usar evidencia local -> mais rapido, sem autoridade nova, depende de validacao local.
- `human_decision`: Decisao humana -> mais seguro quando muda escopo, custo, permissao ou aceite.
- `split_cut`: Separar corte -> reduz risco quando ha dois resultados ou dependencias distintas.
