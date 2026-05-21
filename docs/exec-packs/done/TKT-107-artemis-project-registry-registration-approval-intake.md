# TKT-107 - ARTEMIS Project Registry Registration Approval Intake

## Objetivo

Classificar a decisao humana do pacote de aprovacao de registro do Project
Registry sem executar escrita real.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: intake, validacao de decisao, artifacts, evento e grafo.
- Humano owner: autoridade para preencher a decisao real em momento futuro.

## Resultado esperado

O metodo passa a distinguir `pending`, `approved`, `rejected`, `deferred` e
`invalid`, validando candidato, escopo, caminhos aceitos, comandos de validacao
e timestamp antes de permitir que um gate futuro considere a escrita.

## Escopo

- Consumir `project-registry-registration-approval-package.json`.
- Consumir a decision template do pacote ou um arquivo fornecido via
  `--decision`.
- Validar campos obrigatorios para decisoes nao pendentes.
- Validar `candidate_project_id`, caminhos aceitos, comandos aceitos e
  timestamp.
- Emitir artifacts e evento canonico.
- Manter registry write e runtime bloqueados.

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

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md`
- `scripts/artemis-portal-project-registry-registration-approval-intake.sh`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-approval-intake.json`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-decision-received.json`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-approval-intake.sh
scripts/artemis-portal-project-registry-registration-approval-intake.sh --artifact-root artifacts/artemis-portal-project-registry-registration-approval-intake/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-approval-intake.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-decision-received.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-approval-intake.json`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/project-registry-registration-decision-received.json`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md`
- `artifacts/artemis-portal-project-registry-registration-approval-intake/run-01/events.json`

## Handoff

Handoff aceito quando o intake ficar em
`project_registry_registration_approval_intake_ready`, classificando a decisao
padrao como `pending` e mantendo registry write, registro, troca de projeto,
runtime, auth, comandos, tokens e remoto bloqueados.
