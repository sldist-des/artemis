# TKT-085 - ARTEMIS Control Plane Runtime Gateway Status View

## Objetivo

Renderizar no Control Plane o estado do Runtime Gateway Service para que o
humano entenda quais operadores existem e por que nenhum deles ainda pode rodar
pelo painel.

## Nivel ARTEMIS da execucao

Nivel 2 - UX operacional, superficie de portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: implementacao da view, validacao read-only e handoff.
- Humano owner: autoridade futura para conectar providers, aceitar budget e
  liberar execucao real.

## Resultado esperado

O primeiro modo do Control Plane deve mostrar uma faixa clara de operadores:

- Codex app-server planejado, ainda nao conectado.
- Claude Code planejado, ainda nao conectado.
- Antigravity CLI bloqueado ate capability discovery.

O painel deve continuar explicando que ele nao inicia runtime diretamente.

## Escopo

- Adicionar secao `Runtime Gateway` no modo simples do Control Plane.
- Carregar `runtime-gateway-service.json`.
- Renderizar operadores e bloqueios em linguagem humana.
- Criar script read-only que valida tokens de view e artifact consumido.
- Emitir artifact e evento canonico do TKT-085.

## Fora de escopo

- Iniciar Codex app-server.
- Iniciar Claude Code.
- Iniciar Antigravity CLI.
- Subir servidor do Gateway.
- Abrir websocket.
- Autenticar provider.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-runtime-gateway-view.sh`
- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/control-plane-runtime-gateway-view.json`
- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/CONTROL_PLANE_RUNTIME_GATEWAY_VIEW.md`
- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-control-plane-runtime-gateway-view.sh
scripts/artemis-control-plane-runtime-gateway-view.sh --artifact-root artifacts/artemis-control-plane-runtime-gateway-view/run-01 --json
python3 -m json.tool artifacts/artemis-control-plane-runtime-gateway-view/run-01/control-plane-runtime-gateway-view.json
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/control-plane-runtime-gateway-view.json`
- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/CONTROL_PLANE_RUNTIME_GATEWAY_VIEW.md`
- `artifacts/artemis-control-plane-runtime-gateway-view/run-01/events.json`

## Handoff

Handoff aceito quando o Control Plane mostrar o estado dos operadores em modo
read-only, com validacao local e sem runtime, auth, comandos, tokens ou remoto.
