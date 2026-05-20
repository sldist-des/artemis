# TKT-089 - ARTEMIS Portal External Project Registration

## Objetivo

Definir o contrato de cadastro de projetos externos do portal, consumindo
somente artifacts de Local Project Connect e bloqueando registro automatico,
troca de projeto e runtime real.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal, seguranca de filesystem local e governanca de
projetos.

## Agentes envolvidos

- Codex executor: implementacao do contrato, script read-only, artifacts e
  validacao.
- Humano owner: autoridade futura para revisar candidatos, registrar projetos e
  permitir selecao/runtime real.

## Resultado esperado

O ARTEMIS passa a diferenciar projeto conectado pelo terminal de projeto
registrado no portal. O projeto conectado vira apenas candidato, aguardando
revisao humana, sem registro externo automatico e sem permissao de runtime.

## Escopo

- Documentar External Project Registration.
- Criar script read-only que consome Local Project Connect.
- Criar record de candidato a partir do connect artifact.
- Bloquear browser filesystem, server scan e registro automatico.
- Bloquear troca de projeto, auth, runtime, agentes, comandos, tokens e remoto.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Publicar pacote npm.
- Criar registry persistente editavel.
- Registrar projeto externo automaticamente.
- Trocar projeto ativo no painel.
- Criar workspace ou worktree.
- Autenticar providers.
- Iniciar Codex app-server, Claude Code ou Antigravity CLI.
- Executar tarefas.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_EXTERNAL_PROJECT_REGISTRATION.md`
- `scripts/artemis-portal-external-project-registration.sh`
- `artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json`
- `artifacts/artemis-portal-external-project-registration/run-01/EXTERNAL_PROJECT_REGISTRATION.md`
- `artifacts/artemis-portal-external-project-registration/run-01/STATUS.md`
- `artifacts/artemis-portal-external-project-registration/run-01/VALIDATION.md`
- `artifacts/artemis-portal-external-project-registration/run-01/HANDOFF.md`
- `artifacts/artemis-portal-external-project-registration/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-external-project-registration.sh
scripts/artemis-portal-external-project-registration.sh --artifact-root artifacts/artemis-portal-external-project-registration/run-01 --json
python3 -m json.tool artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json
python3 -m json.tool artifacts/artemis-portal-external-project-registration/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json`
- `artifacts/artemis-portal-external-project-registration/run-01/EXTERNAL_PROJECT_REGISTRATION.md`
- `artifacts/artemis-portal-external-project-registration/run-01/events.json`

## Handoff

Handoff aceito quando o registro externo aceitar somente candidato vindo de
terminal connect, bloquear registro automatico e preservar auth, runtime,
agentes, comandos, tokens e remoto bloqueados.
