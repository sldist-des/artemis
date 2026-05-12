# ARTEMIS PROJECT BRIEF

## Em uma frase

O ARTEMIS Symphony esta pronto como sistema local supervisionado: ele organiza tarefas, evidencia, validacao, memoria e limites antes de qualquer execucao automatica.

## O que esta pronto

- 71 de 71 Exec Packs estao concluidos e versionados.
- O Validation Gate registra 107 checks aprovados e 0 falhas tecnicas.
- O Project Graph conecta 22 nos e 54 relacoes entre tarefas, agentes, gates, memoria, custos e evidencias.
- A Memory Zone tem 3 zonas para contexto humano-AI versionado em Git.

## Onde precisa de humano

- Existem 2 Human Gates ativos. Eles nao sao erro: sao pontos onde uma pessoa precisa decidir antes de rede, auth, custo, escrita remota ou cleanup real.
- O painel ajuda a entender o estado, mas nao aprova nem executa trabalho sensivel sozinho.
- Qualquer mudanca com producao, secrets, auth, push remoto, custo ou cleanup real continua passando por decisao humana explicita.

## Proximas acoes

- Usar este briefing como porta de entrada para pessoas que nao conhecem todos os artifacts.
- Abrir novos cortes somente como nova fase, com Exec Pack, risco, evidencia esperada e decisao humana necessaria.
- Usar o modo guiado e o Done Ledger como entrada para operacao supervisionada sem perder controle terminal-first.

## Como colaborar

- Leia o briefing primeiro para entender o estado geral.
- Abra o Project Graph quando precisar ver relacoes tecnicas.
- Abra Exec Packs e artifacts quando precisar auditar a evidencia.
- Autorize apenas acoes concretas, reversiveis e bem delimitadas.

## Limites

- O briefing e explicacao, nao fonte de verdade.
- Git, Exec Packs, Event Log, Validation Gate e artifacts continuam canonicos.
- Nenhum agente, runner, bridge, fila, indexador ou banco e iniciado por este corte.
- Budget, tokens, auth e escrita remota precisam ser explicitos antes de runtime real.
