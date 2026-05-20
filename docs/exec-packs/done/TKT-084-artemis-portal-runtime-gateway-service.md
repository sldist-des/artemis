# TKT-084 - ARTEMIS Portal Runtime Gateway Read-only Service

## Objetivo

Criar a primeira superficie consumivel pelo Control Plane para ler o Runtime
Gateway multi-operador sem iniciar runtime real.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal, seguranca operacional e preparacao de API
read-only.

## Agentes envolvidos

- Codex executor: implementacao do contrato, script read-only, artifact e
  validacao.
- Humano owner: autoridade futura para aceitar auth real, servidor persistente,
  budget e execucao de agentes.

## Resultado esperado

O ARTEMIS passa a ter um artifact de service read-only que o painel pode ler
para mostrar:

- estado do Runtime Gateway;
- operadores Codex app-server, Claude Code e Antigravity CLI;
- quais operadores estao planejados, conectados ou bloqueados;
- por que o painel ainda nao pode iniciar runtime;
- quais rotas GET serao expostas quando o service virar HTTP real.

## Escopo

- Documentar o Runtime Gateway Service read-only.
- Criar script que consome o contrato TKT-083.
- Gerar `runtime-gateway-service.json`.
- Declarar endpoints GET planejados.
- Declarar que POST, sockets, auth, comandos, tokens e remoto seguem
  desabilitados.
- Emitir evento canonico.

## Fora de escopo

- Subir servidor HTTP persistente.
- Abrir websocket.
- Aceitar POST/PATCH/DELETE.
- Iniciar Codex app-server.
- Iniciar Claude Code.
- Iniciar Antigravity CLI.
- Autenticar provider.
- Emitir vault lease real.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY_SERVICE.md`
- `scripts/artemis-portal-runtime-gateway-service.sh`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/RUNTIME_GATEWAY_SERVICE.md`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/STATUS.md`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/VALIDATION.md`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/HANDOFF.md`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-runtime-gateway-service.sh
scripts/artemis-portal-runtime-gateway-service.sh --artifact-root artifacts/artemis-portal-runtime-gateway-service/run-01 --json
python3 -m json.tool artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json
python3 -m json.tool artifacts/artemis-portal-runtime-gateway-service/run-01/events.json
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/RUNTIME_GATEWAY_SERVICE.md`
- `artifacts/artemis-portal-runtime-gateway-service/run-01/events.json`

## Handoff

Handoff aceito quando o service read-only estiver documentado, artifactado,
validado e sem servidor persistente, auth, runtime, agentes, comandos, tokens
ou remoto.
