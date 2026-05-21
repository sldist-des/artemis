# TKT-108 - ARTEMIS Project Registry Registration Approved Write Fixture

## Objetivo

Provar o caminho positivo da aprovacao de escrita do Project Registry com uma
fixture sintetica, sem executar escrita real.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: fixture aprovada, execucao controlada do intake, artifacts,
  evento, grafo e validacao.
- Humano owner: autoridade futura para aprovacao real; a fixture nao substitui
  essa decisao.

## Resultado esperado

O metodo passa a ter evidencia de que uma decisao aprovada bem formada chega em
`approved_for_registry_write_gate`, mantendo `registry_write_allowed: false`.

## Escopo

- Consumir `project-registry-registration-approval-package.json`.
- Criar fixture sintetica de decisao `approved`.
- Executar o Approval Intake em subartefato controlado.
- Confirmar `approved_for_registry_write_gate: true`.
- Bloquear escrita real, registro, troca de projeto e runtime.
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

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md`
- `scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write-fixture.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write.fixture.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/approval-intake/project-registry-registration-approval-intake.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh
scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh --artifact-root artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write-fixture.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write.fixture.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write-fixture.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write.fixture.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/approval-intake/project-registry-registration-approval-intake.json`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md`
- `artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/events.json`

## Handoff

Handoff aceito quando a fixture ficar em
`project_registry_registration_approved_write_fixture_ready`, com
`approved_for_registry_write_gate: true`, `synthetic_fixture_only: true` e
registry write, registro, troca de projeto, runtime, auth, comandos, tokens e
remoto bloqueados.
