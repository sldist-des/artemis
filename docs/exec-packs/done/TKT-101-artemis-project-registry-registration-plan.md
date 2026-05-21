# TKT-101 - ARTEMIS Project Registry Registration Plan

## Objetivo

Criar o plano declarativo de registro do Project Registry a partir do caminho
aprovado, sem registrar projeto nem liberar runtime.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: plano, script, artifacts, evento e validacao.
- Humano owner: autoridade futura para aprovar execucao real de registro.

## Resultado esperado

O metodo passa a ter um plano claro para registro futuro, com registros
planejados e requisitos de execution gate, mantendo todas as mutacoes
bloqueadas.

## Escopo

- Consumir a fixture aprovada do TKT-100.
- Validar `ready_for_registration_plan`.
- Gerar plano de registros futuros.
- Declarar requisitos do execution gate.
- Manter registro, troca de projeto, runtime, auth, comandos e tokens
  bloqueados.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Criar aprovacao humana real.
- Registrar projeto externo.
- Escrever registry real.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_PLAN.md`
- `scripts/artemis-portal-project-registry-registration-plan.sh`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/project-registry-registration-plan.json`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/PROJECT_REGISTRY_REGISTRATION_PLAN.md`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-plan.sh
scripts/artemis-portal-project-registry-registration-plan.sh --artifact-root artifacts/artemis-portal-project-registry-registration-plan/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-plan/run-01/project-registry-registration-plan.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-plan/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-plan/run-01/project-registry-registration-plan.json`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/PROJECT_REGISTRY_REGISTRATION_PLAN.md`
- `artifacts/artemis-portal-project-registry-registration-plan/run-01/events.json`

## Handoff

Handoff aceito quando o plano chegar em
`ready_for_registration_execution_gate` sem liberar registro, troca de projeto,
runtime, auth, comandos, tokens ou remoto.
