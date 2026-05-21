# TKT-109 - ARTEMIS Project Registry Registration Write Gate

## Objetivo

Criar o gate de escrita real do Project Registry, separando a fixture aprovada
da autoridade humana real para escrita.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: write gate, template de aprovacao real, artifacts, evento,
  grafo e validacao.
- Humano owner: autoridade futura para aprovar, rejeitar ou diferir a escrita
  real.

## Resultado esperado

O metodo passa a ter uma trava explicita entre "o caminho aprovado funciona" e
"podemos escrever o registry". A fixture aprovada vira evidencia, nao
permissao.

## Escopo

- Consumir `project-registry-registration-approved-write-fixture.json`.
- Confirmar que a fixture positiva esta pronta.
- Confirmar que a fixture e sintetica.
- Emitir template de aprovacao humana real para escrita.
- Manter o estado padrao em `waiting_for_real_human_write_approval`.
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

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md`
- `scripts/artemis-portal-project-registry-registration-write-gate.sh`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-gate.json`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-approval-template.json`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-write-gate.sh
scripts/artemis-portal-project-registry-registration-write-gate.sh --artifact-root artifacts/artemis-portal-project-registry-registration-write-gate/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-gate.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-approval-template.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-write-gate/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-gate.json`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/project-registry-registration-write-approval-template.json`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-write-gate/run-01/events.json`

## Handoff

Handoff aceito quando o gate ficar em
`project_registry_registration_write_gate_ready`, com
`write_gate_state: waiting_for_real_human_write_approval`, fixture sintetica
reconhecida e registry write, registro, troca de projeto, runtime, auth,
comandos, tokens e remoto bloqueados.
