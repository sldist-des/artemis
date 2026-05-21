# TKT-100 - ARTEMIS Project Registry Approved Decision Fixture

## Objetivo

Criar uma fixture sintetica de decisao aprovada para validar o caminho positivo
do Project Registry sem registrar projeto, trocar projeto ou iniciar runtime.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: fixture, script, artifacts, evento e validacao.
- Humano owner: autoridade futura para emitir uma decisao real.

## Resultado esperado

O metodo prova que uma decisao `approved` registrada pelo intake desbloqueia
apenas o estado de planejamento do registro, mantendo todas as execucoes reais
bloqueadas.

## Escopo

- Gerar `project-registry-approved-decision.fixture.json`.
- Executar Decision Intake com a fixture aprovada.
- Executar Registration Gate consumindo o intake aprovado.
- Validar `ready_for_registration_plan`.
- Manter registro, troca de projeto, runtime, auth, comandos e tokens
  bloqueados.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Criar aprovacao humana real.
- Registrar projeto externo.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos de runtime.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md`
- `scripts/artemis-portal-project-registry-approved-decision-fixture.sh`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/project-registry-approved-decision-fixture.json`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/project-registry-approved-decision.fixture.json`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-approved-decision-fixture.sh
scripts/artemis-portal-project-registry-approved-decision-fixture.sh --artifact-root artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/project-registry-approved-decision-fixture.json
python3 -m json.tool artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/project-registry-approved-decision-fixture.json`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md`
- `artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/events.json`

## Handoff

Handoff aceito quando o caminho aprovado chegar em
`ready_for_registration_plan` sem liberar registro, troca de projeto, runtime,
auth, comandos, tokens ou remoto.
