# TKT-105 - ARTEMIS Project Registry Registration Dry Run

## Objetivo

Gerar uma previa auditavel da escrita futura no Project Registry sem escrever o
registry real, registrar candidato, trocar projeto ou iniciar runtime.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: dry-run, diff preview, rollback plan, artifacts, evento e
  validacao.
- Humano owner: autoridade futura para aceitar, rejeitar ou ajustar a previa
  antes de qualquer escrita real.

## Resultado esperado

O metodo passa a mostrar exatamente quais registros seriam escritos no registry
e como desfazer uma escrita futura, mantendo registry write bloqueado.

## Escopo

- Consumir `project-registry-registration-plan.json`.
- Consumir `project-registry-registration-execution-gate.json`.
- Resolver o candidato pelo Human Review Gate.
- Criar `registry-write-draft.json`.
- Criar `registry-diff-preview.md`.
- Criar `registry-rollback-plan.md`.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Escrever registry real.
- Registrar candidato.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos por provider.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md`
- `scripts/artemis-portal-project-registry-registration-dry-run.sh`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/project-registry-registration-dry-run.json`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-write-draft.json`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-diff-preview.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-rollback-plan.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-dry-run.sh
scripts/artemis-portal-project-registry-registration-dry-run.sh --artifact-root artifacts/artemis-portal-project-registry-registration-dry-run/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-dry-run/run-01/project-registry-registration-dry-run.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-write-draft.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-dry-run/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/project-registry-registration-dry-run.json`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-write-draft.json`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-diff-preview.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-rollback-plan.md`
- `artifacts/artemis-portal-project-registry-registration-dry-run/run-01/events.json`

## Handoff

Handoff aceito quando o dry-run ficar em
`project_registry_registration_dry_run_ready`, com draft, diff preview e
rollback plan criados, mantendo registry write, registro, troca de projeto,
runtime, auth, comandos, tokens e remoto bloqueados.

