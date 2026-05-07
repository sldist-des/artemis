# ARTEMIS GUIDED COLLABORATION

## Entrada guiada

- Escolha o projeto e confirme a fonte canonica.
- Escolha uma tarefa pequena o bastante para validar.
- Escolha o perfil de agente pelo risco, contexto e duracao.
- Declare budget, auth, comandos permitidos e evidencias esperadas.
- Pare em Human Gate antes de custo, rede, remoto, producao ou cleanup real.

## Perfis de agente

- **Codex frontier**: Tarefas longas, arquitetura, integracao, validacao ampla e commits Lore. Budget: `alto`.
- **Claude Code rapido**: Mapear diretorios, entender linguagem, sugerir recortes medios e revisar contexto. Budget: `medio`.
- **Verifier**: Conferir evidencia, testes, gates, screenshots e claims de conclusao. Budget: `baixo_medio`.
- **Humano owner**: Decidir auth, custo, producao, remoto, prioridade, risco e aceite. Budget: `decisao`.

## Gates

- **Auth** (`human_required_before_real_use`): Codex app-server, Claude Code, GitHub ou qualquer conta pessoal precisam de autenticacao explicita do humano.
- **Budget** (`human_required_before_runtime`): Token, custo, modelo, tempo maximo e numero de agentes devem ser declarados antes de execucao real.
- **Remote write** (`blocked_by_default`): Push, PR, issue mutation, deploy e configuracao remota continuam bloqueados ate decisao humana.
- **Validation** (`required_before_done`): Toda tarefa guiada precisa declarar a evidencia que sera aceita antes de entrar em Done.

## Comandos de verificacao

- `scripts/artemis-guided-collaboration.sh --json`
- `scripts/artemis-project-brief.sh --json`
- `scripts/artemis-validation-gate.sh --json`
- `scripts/validate-artemis.sh`
