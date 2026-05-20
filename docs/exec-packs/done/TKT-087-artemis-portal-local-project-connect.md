# TKT-087 - ARTEMIS Portal Local Project Connect

## Objetivo

Definir o contrato terminal-first para conectar um projeto local ao ARTEMIS e
descobrir fornecedores disponiveis antes de qualquer acao real do portal.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal, seguranca de filesystem local e descoberta de
fornecedores.

## Agentes envolvidos

- Codex executor: implementacao do contrato, script read-only, artifacts e
  validacao.
- Humano owner: autoridade futura para publicar pacote npm, conectar providers
  e permitir runtime real.

## Resultado esperado

O ARTEMIS passa a registrar que acesso a projeto local deve ser dado pelo
terminal, com entrypoint futuro `npx artemis connect --project .`, e que o
comando descobre slots de Codex, Claude Code e Antigravity CLI sem autenticar ou
executar runtime.

## Escopo

- Documentar Local Project Connect.
- Criar script read-only para registrar projeto a partir do terminal.
- Detectar raiz Git, branch, remote e `AGENTS.md`.
- Declarar entrypoint futuro via `npx`.
- Descobrir binarios locais de `codex`, `claude`, `agy` e `antigravity`.
- Bloquear auth, runtime, agentes, comandos, tokens e remoto.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Publicar pacote npm.
- Gravar arquivos no projeto alvo.
- Escanear diretorios do servidor.
- Autenticar Codex, Claude Code ou Antigravity.
- Iniciar Codex app-server.
- Iniciar Claude Code.
- Iniciar Antigravity CLI.
- Executar tarefas.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_LOCAL_PROJECT_CONNECT.md`
- `scripts/artemis-portal-local-project-connect.sh`
- `artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json`
- `artifacts/artemis-portal-local-project-connect/run-01/LOCAL_PROJECT_CONNECT.md`
- `artifacts/artemis-portal-local-project-connect/run-01/STATUS.md`
- `artifacts/artemis-portal-local-project-connect/run-01/VALIDATION.md`
- `artifacts/artemis-portal-local-project-connect/run-01/HANDOFF.md`
- `artifacts/artemis-portal-local-project-connect/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-local-project-connect.sh
scripts/artemis-portal-local-project-connect.sh --project . --artifact-root artifacts/artemis-portal-local-project-connect/run-01 --json
python3 -m json.tool artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json
python3 -m json.tool artifacts/artemis-portal-local-project-connect/run-01/events.json
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json`
- `artifacts/artemis-portal-local-project-connect/run-01/LOCAL_PROJECT_CONNECT.md`
- `artifacts/artemis-portal-local-project-connect/run-01/events.json`

## Handoff

Handoff aceito quando o Local Project Connect registrar o projeto local via
terminal, declarar o entrypoint futuro por `npx`, detectar slots de fornecedores
e preservar runtime bloqueado, sem auth, comandos, agentes, tokens ou remoto.
