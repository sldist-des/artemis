# TKT-099 - ARTEMIS Project Registry Registration Gate

## Objetivo

Criar o gate de registro do Project Registry, mantendo o candidato bloqueado
enquanto a decisao humana estiver pendente.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: contrato, script, artifacts, evento e leitura na home.
- Humano owner: autoridade futura para registrar decisao aprovada.

## Resultado esperado

O metodo passa a ter um gate explicito entre decisao humana e registro de
projeto. Como a decisao segue pendente, nenhum registro e permitido.

## Escopo

- Consumir `project-registry-decision-intake.json`.
- Calcular precondicoes de registro.
- Bloquear registro enquanto nao houver decisao aprovada.
- Emitir artifacts e evento de Human Gate.
- Manter registro, troca de projeto, runtime, auth, comandos e tokens
  bloqueados.

## Fora de escopo

- Registrar projeto externo.
- Criar decisao aprovada real.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_GATE.md`
- `scripts/artemis-portal-project-registry-registration-gate.sh`
- `control-plane/index.html`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/project-registry-registration-gate.json`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/PROJECT_REGISTRY_REGISTRATION_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-registration-gate.sh
scripts/artemis-portal-project-registry-registration-gate.sh --artifact-root artifacts/artemis-portal-project-registry-registration-gate/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-gate/run-01/project-registry-registration-gate.json
python3 -m json.tool artifacts/artemis-portal-project-registry-registration-gate/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-registration-gate/run-01/project-registry-registration-gate.json`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/PROJECT_REGISTRY_REGISTRATION_GATE.md`
- `artifacts/artemis-portal-project-registry-registration-gate/run-01/events.json`

## Handoff

Handoff aceito quando o gate provar que registro segue bloqueado por decisao
pendente e preservar troca de projeto, runtime, auth, comandos e remoto
bloqueados.
