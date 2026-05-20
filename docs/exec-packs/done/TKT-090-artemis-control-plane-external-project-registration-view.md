# TKT-090 - ARTEMIS Control Plane External Project Registration View

## Objetivo

Renderizar no Control Plane a fila de candidatos de registro externo, deixando
claro que candidato nao e projeto selecionado nem runtime liberado.

## Nivel ARTEMIS da execucao

Nivel 2 - superficie visual de portal, registro de projeto e seguranca de
runtime.

## Agentes envolvidos

- Codex executor: implementacao visual, script de validacao, artifacts e
  validacao.
- Humano owner: autoridade futura para revisar candidatos, registrar projetos e
  permitir selecao/runtime real.

## Resultado esperado

O Control Plane mostra o candidato vindo do Local Project Connect, registra que
existem `0` projetos externos registrados, bloqueia troca de projeto e preserva
runtime, agentes, comandos, tokens e remoto desligados.

## Escopo

- Renderizar bloco "Registro externo" no modo simples.
- Consumir artifact `external-project-registration.json`.
- Mostrar candidatos, projetos registrados, troca de projeto e fonte.
- Mostrar candidato em revisao humana.
- Manter auth, runtime, comandos, tokens e remoto bloqueados.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Aprovar candidato.
- Persistir registry editavel.
- Trocar projeto ativo no painel.
- Criar seletor real de projetos.
- Autenticar providers.
- Iniciar app-server, SDK ou CLI.
- Enviar prompt para provider.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-external-project-registration-view.sh`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/control-plane-external-project-registration-view.json`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/CONTROL_PLANE_EXTERNAL_PROJECT_REGISTRATION_VIEW.md`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/HANDOFF.md`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-control-plane-external-project-registration-view.sh
scripts/artemis-control-plane-external-project-registration-view.sh --artifact-root artifacts/artemis-control-plane-external-project-registration-view/run-01 --json
python3 -m json.tool artifacts/artemis-control-plane-external-project-registration-view/run-01/control-plane-external-project-registration-view.json
python3 -m json.tool artifacts/artemis-control-plane-external-project-registration-view/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-external-project-registration-view/run-01/control-plane-external-project-registration-view.json`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/CONTROL_PLANE_EXTERNAL_PROJECT_REGISTRATION_VIEW.md`
- `artifacts/artemis-control-plane-external-project-registration-view/run-01/events.json`

## Handoff

Handoff aceito quando o Control Plane mostrar candidatos de registro externo sem
sugerir troca de projeto ou runtime liberado, preservando auth, agentes,
comandos, tokens e remoto bloqueados.
