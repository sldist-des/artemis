# TKT-094 - ARTEMIS Portal Project Selector Registry Intake

## Objetivo

Criar o read model de intake do registry que junta o projeto selecionado atual
com candidatos vindos do terminal, sem transformar candidato em runtime
selecionavel.

## Nivel ARTEMIS da execucao

Nivel 2 - contexto de projeto, registry do portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: contrato, script, artifacts, evento e validacao.
- Humano owner: autoridade futura para aprovar candidatos, troca de projeto e
  runtime real.

## Resultado esperado

O ARTEMIS registra que o projeto atual segue como `selected_read_only`, que o
projeto conectado pelo terminal segue como `candidate_review_pending`, e que
troca de projeto/runtime continuam bloqueados.

## Escopo

- Documentar Registry Intake.
- Consumir Project Selector existente.
- Consumir External Project Registration existente.
- Gerar registry read model.
- Preservar candidato como nao selecionavel.
- Emitir artifacts e evento canonico.
- Manter UI limpa, sem adicionar nova superficie tecnica.

## Fora de escopo

- Aprovar projeto candidato.
- Trocar projeto selecionado.
- Criar registry editavel.
- Abrir browser filesystem picker.
- Criar worktree.
- Trocar branch.
- Autenticar providers.
- Iniciar Codex app-server, Claude Code ou Antigravity CLI.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR_REGISTRY_INTAKE.md`
- `scripts/artemis-portal-project-selector-registry-intake.sh`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/PROJECT_SELECTOR_REGISTRY_INTAKE.md`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/STATUS.md`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-selector-registry-intake.sh
scripts/artemis-portal-project-selector-registry-intake.sh --artifact-root artifacts/artemis-portal-project-selector-registry-intake/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json
python3 -m json.tool artifacts/artemis-portal-project-selector-registry-intake/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/PROJECT_SELECTOR_REGISTRY_INTAKE.md`
- `artifacts/artemis-portal-project-selector-registry-intake/run-01/events.json`

## Handoff

Handoff aceito quando o registry intake mostrar projeto selecionado e candidato
em revisao sem liberar troca, runtime, auth, comandos, tokens ou remoto.
