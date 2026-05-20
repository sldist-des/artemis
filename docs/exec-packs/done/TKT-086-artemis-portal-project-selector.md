# TKT-086 - ARTEMIS Portal Project Selector Contract

## Objetivo

Definir o contrato read-only do Project Selector do portal para separar o
projeto ARTEMIS atual de projetos externos que futuramente poderao receber
operadores como Codex app-server, Claude Code e Antigravity CLI.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal, contexto de projeto e seguranca de runtime.

## Agentes envolvidos

- Codex executor: implementacao do contrato, script read-only, artifacts e
  validacao.
- Humano owner: autoridade futura para cadastrar projetos externos e confirmar
  runtime real.

## Resultado esperado

O ARTEMIS passa a registrar explicitamente que o Control Plane atual esta
selecionado para o projeto `ARTEMIS Method Kit`, no repositorio local, e que
nenhum projeto externo foi selecionado.

## Escopo

- Documentar Project Selector.
- Criar script read-only que detecta raiz Git, branch e contrato `AGENTS.md`.
- Consumir Runtime Gateway Service.
- Registrar projeto local como `selected_read_only`.
- Declarar operadores vinculados ao projeto.
- Bloquear runtime ate cadastro/confirmacao humana.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Cadastrar projetos externos reais.
- Escanear diretorios do servidor.
- Abrir seletor de filesystem.
- Criar worktree.
- Trocar branch.
- Iniciar Codex app-server.
- Iniciar Claude Code.
- Iniciar Antigravity CLI.
- Autenticar provider.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR.md`
- `scripts/artemis-portal-project-selector.sh`
- `artifacts/artemis-portal-project-selector/run-01/project-selector-contract.json`
- `artifacts/artemis-portal-project-selector/run-01/PROJECT_SELECTOR.md`
- `artifacts/artemis-portal-project-selector/run-01/STATUS.md`
- `artifacts/artemis-portal-project-selector/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-selector/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-selector/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-selector.sh
scripts/artemis-portal-project-selector.sh --artifact-root artifacts/artemis-portal-project-selector/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-selector/run-01/project-selector-contract.json
python3 -m json.tool artifacts/artemis-portal-project-selector/run-01/events.json
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-selector/run-01/project-selector-contract.json`
- `artifacts/artemis-portal-project-selector/run-01/PROJECT_SELECTOR.md`
- `artifacts/artemis-portal-project-selector/run-01/events.json`

## Handoff

Handoff aceito quando o Project Selector registrar o projeto local ARTEMIS,
bloquear projetos externos nao cadastrados, preservar runtime read-only e passar
validacao sem auth, worktree, comandos, tokens ou remoto.
