# TKT-102 - ARTEMIS Project Registry Registration Execution Gate

## Objetivo

Criar o gate de execucao do registro do Project Registry, bloqueando escrita
real ate existir aprovacao humana real e pacote minimo de execucao.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: gate, template de aprovacao, artifacts, evento e validacao.
- Humano owner: autoridade futura para aprovar escrita real no registry.

## Resultado esperado

O metodo passa a ter um gate claro entre plano e escrita real. Como ainda nao
ha aprovacao humana real, registry write, registro de candidato, troca de
projeto e runtime seguem bloqueados.

## Escopo

- Consumir `project-registry-registration-plan.json`.
- Validar que o plano chegou em `ready_for_registration_execution_gate`.
- Criar template de aprovacao real.
- Declarar precondicoes de execucao.
- Bloquear registry write enquanto faltar aprovacao real e evidencias.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Criar aprovacao humana real.
- Executar dry-run de escrita.
- Escrever registry real.
- Registrar projeto externo.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md`
- `scripts/artemis-portal-project-registry-registration-execution-gate.sh`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/project-registry-registration-execution-gate.json`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/project-registry-registration-execution-approval-template.json`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-execution-gate.sh
scripts/artemis-portal-project-registry-registration-execution-gate.sh --artifact-root artifacts/artemis-portal-project-registry-registration-execution-gate/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/project-registry-registration-execution-gate.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/project-registry-registration-execution-gate.json`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/events.json`

## Handoff

Handoff aceito quando o gate ficar em
`waiting_for_real_human_execution_approval`, com template de aprovacao criado e
sem liberar registry write, registro, troca de projeto, runtime, auth,
comandos, tokens ou remoto.
