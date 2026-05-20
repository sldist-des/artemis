# TKT-083 - ARTEMIS Portal Runtime Gateway

## Objetivo

Criar o contrato do Runtime Gateway multi-operador que ficara entre o Control
Plane e qualquer runtime real de Codex app-server, Claude Code, Antigravity CLI
ou futuros agentes.

## Nivel ARTEMIS da execucao

Nivel 2 - arquitetura de portal, seguranca operacional e preparacao de runtime.

## Agentes envolvidos

- Codex executor: implementacao do contrato, script read-only, artifact e
  validacao.
- Humano: autoridade futura para auth, budget, conexao de provider e runtime
  real.

## Resultado esperado

O ARTEMIS passa a ter uma fronteira explicita para operacao multi-operador:
o painel nao chama providers diretamente; ele chama o Runtime Gateway, que
exige projeto, operador, vault lease, budget, workspace, command plan, Human
Gate e validacao antes de qualquer execucao.

## Escopo

- Documentar o Runtime Gateway.
- Declarar adapters para Codex app-server, Claude Code e Antigravity CLI.
- Marcar Antigravity CLI como `unverified_adapter` ate capability discovery.
- Criar script read-only para gerar contrato, status, validacao, handoff e
  eventos.
- Preservar `agents_started=0`, `commands_executed=0`, `tokens_spent=0` e
  `runtime_auth_executed=false`.

## Fora de escopo

- Iniciar Codex app-server.
- Iniciar Claude Code.
- Iniciar Antigravity CLI.
- Autenticar provider.
- Emitir vault lease real.
- Abrir websocket.
- Enviar prompt para provider.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY.md`
- `scripts/artemis-portal-runtime-gateway.sh`
- `artifacts/artemis-portal-runtime-gateway/run-01/runtime-gateway-contract.json`
- `artifacts/artemis-portal-runtime-gateway/run-01/RUNTIME_GATEWAY.md`
- `artifacts/artemis-portal-runtime-gateway/run-01/STATUS.md`
- `artifacts/artemis-portal-runtime-gateway/run-01/VALIDATION.md`
- `artifacts/artemis-portal-runtime-gateway/run-01/HANDOFF.md`
- `artifacts/artemis-portal-runtime-gateway/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-runtime-gateway.sh
scripts/artemis-portal-runtime-gateway.sh --artifact-root artifacts/artemis-portal-runtime-gateway/run-01 --json
python3 -m json.tool artifacts/artemis-portal-runtime-gateway/run-01/runtime-gateway-contract.json
python3 -m json.tool artifacts/artemis-portal-runtime-gateway/run-01/events.json
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-runtime-gateway/run-01/runtime-gateway-contract.json`
- `artifacts/artemis-portal-runtime-gateway/run-01/RUNTIME_GATEWAY.md`
- `artifacts/artemis-portal-runtime-gateway/run-01/events.json`

## Handoff

Handoff aceito quando o contrato multi-operador estiver documentado,
artifactado, validado e sem execucao real de auth, runtime, agentes, comandos,
tokens ou remoto.
