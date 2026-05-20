# TKT-095 - ARTEMIS Control Plane Project Registry Home State

## Objetivo

Validar que a home humana do Control Plane consome o Project Selector Registry
Intake sem reintroduzir uma superficie tecnica grande na primeira leitura.

## Nivel ARTEMIS da execucao

Nivel 2 - experiencia de portal, contexto de projeto e seguranca de runtime.

## Agentes envolvidos

- Codex executor: ajuste da home, script de validacao, artifacts e evento.
- Humano owner: autoridade futura para aprovar candidatos e runtime.

## Resultado esperado

A home mostra projeto selecionado, candidato em revisao e runtime bloqueado,
mantendo auditoria tecnica fora da superficie primaria.

## Escopo

- Validar consumo de `project-selector-registry-intake.json`.
- Atualizar labels humanos da home para projeto selecionado e candidato em
  revisao.
- Manter links curtos para resumo, validacao e handoff.
- Garantir que a superficie tecnica nao volte a ser primaria.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Aprovar candidato.
- Trocar projeto selecionado.
- Criar review gate editavel.
- Conectar provider auth.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/control-plane/ARTEMIS_CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md`
- `control-plane/index.html`
- `scripts/artemis-control-plane-project-registry-home-state.sh`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/control-plane-project-registry-home-state.json`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/STATUS.md`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/HANDOFF.md`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-control-plane-project-registry-home-state.sh
scripts/artemis-control-plane-project-registry-home-state.sh --artifact-root artifacts/artemis-control-plane-project-registry-home-state/run-01 --json
python3 -m json.tool artifacts/artemis-control-plane-project-registry-home-state/run-01/control-plane-project-registry-home-state.json
python3 -m json.tool artifacts/artemis-control-plane-project-registry-home-state/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-project-registry-home-state/run-01/control-plane-project-registry-home-state.json`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md`
- `artifacts/artemis-control-plane-project-registry-home-state/run-01/events.json`

## Handoff

Handoff aceito quando a home consumir o registry intake, mostrar estado humano
claro e preservar runtime, troca de projeto, auth, comandos, tokens e remoto
bloqueados.
