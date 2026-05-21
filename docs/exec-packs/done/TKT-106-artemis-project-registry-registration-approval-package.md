# TKT-106 - ARTEMIS Project Registry Registration Human Approval Package

## Objetivo

Empacotar o dry-run de registro do Project Registry para decisao humana
explícita, sem registrar aprovacao nem executar escrita real.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: pacote de aprovacao, template de decisao, artifacts, evento e
  validacao.
- Humano owner: autoridade futura para aprovar, rejeitar ou diferir o pacote.

## Resultado esperado

O metodo passa a ter um pacote claro para o humano revisar: rascunho de escrita,
diff preview, rollback plan, comandos de validacao e template de decisao.

## Escopo

- Consumir `project-registry-registration-dry-run.json`.
- Consumir `registry-write-draft.json`.
- Consumir `registry-diff-preview.md`.
- Consumir `registry-rollback-plan.md`.
- Criar template preenchivel de decisao humana.
- Bloquear escrita real ate intake futuro validar a decisao.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Registrar aprovacao humana real.
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

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md`
- `scripts/artemis-portal-project-registry-registration-approval-package.sh`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-approval-package.json`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-human-decision-template.json`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-approval-package.sh
scripts/artemis-portal-project-registry-registration-approval-package.sh --artifact-root artifacts/artemis-portal-project-registry-registration-approval-package/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-approval-package.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-human-decision-template.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-package/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-approval-package.json`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-human-decision-template.json`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md`
- `artifacts/artemis-portal-project-registry-registration-approval-package/run-01/events.json`

## Handoff

Handoff aceito quando o pacote ficar em
`project_registry_registration_approval_package_ready`, com template de decisao
criado, mantendo aprovacao, registry write, registro, troca de projeto, runtime,
auth, comandos, tokens e remoto bloqueados.

