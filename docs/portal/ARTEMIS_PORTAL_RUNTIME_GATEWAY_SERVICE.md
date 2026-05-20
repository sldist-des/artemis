# ARTEMIS Portal Runtime Gateway Read-only Service

O Runtime Gateway Service e a primeira superficie consumivel pelo Control Plane
para entender operadores, projetos, gates e estado de runtime sem iniciar
nenhum agente.

Neste corte ele e um contrato read-only: gera um artifact JSON com rotas,
payloads e limites. Ele ainda nao sobe servidor persistente, nao abre socket e
nao recebe comandos do painel.

## Regra central

Antes do portal poder operar Codex app-server, Claude Code, Antigravity CLI ou
outro runtime, ele precisa de uma API local que diga claramente:

- qual projeto esta selecionado;
- quais operadores existem;
- quais operadores estao conectados;
- quais estao bloqueados;
- quais gates faltam;
- se o painel pode ou nao iniciar runtime;
- quais evidencias seriam exigidas antes do handoff.

```text
Control Plane
  -> Runtime Gateway Service read-only artifact
  -> Runtime Gateway contract
  -> Operator status
  -> Project/runtime readiness
  -> Human-readable explanation
```

## Endpoints planejados

Todos os endpoints deste corte sao `GET` planejados. Nenhum endpoint muta
estado.

| Endpoint | Uso |
| --- | --- |
| `GET /runtime-gateway/health` | informa que o Gateway esta em modo read-only |
| `GET /runtime-gateway/status` | resume estado do gateway, gates e side effects |
| `GET /runtime-gateway/operators` | lista Codex app-server, Claude Code e Antigravity CLI |
| `GET /runtime-gateway/projects` | lista projetos registrados ou o projeto local atual |
| `GET /runtime-gateway/readiness` | mostra o que falta para runtime real |
| `GET /runtime-gateway/evidence` | aponta artifacts, checks e handoff |

## Proibido neste corte

- `POST`;
- `PATCH`;
- `DELETE`;
- iniciar Codex app-server;
- iniciar Claude Code;
- iniciar Antigravity CLI;
- abrir websocket;
- enviar prompt para provider;
- executar comando;
- gastar token;
- emitir vault lease real;
- autenticar provider;
- fazer push, PR, deploy ou escrita remota.

## Operadores

O service deve mostrar operadores de forma simples:

- **Codex app-server**: planejado, nao conectado, exige provider auth, vault
  lease, budget, workspace, command plan e Human Gate.
- **Claude Code**: planejado, nao conectado, exige os mesmos gates antes de
  runtime.
- **Antigravity CLI**: futuro/experimental, bloqueado ate capability discovery
  confirmar CLI, auth, modo headless e logs.

## Para leigos

Este service e como a tela de "estado do motor".

Ele ainda nao liga o motor. Ele mostra:

- quais motores existem;
- quais estao desconectados;
- qual esta bloqueado;
- quais permissoes faltam;
- por que o painel ainda nao pode apertar "rodar".

## Invariantes

- O frontend nunca deve inferir permissao de runtime sozinho.
- O service read-only nao substitui o Runtime Gateway real.
- O Control Plane pode ler este artifact para explicar estado ao humano.
- O proximo corte que aceitar comandos precisa mudar de contrato, adicionar
  auth, CSRF/session policy, audit log, rate limit e Human Gate real.

## Proximo corte

Criar uma pequena camada local que sirva este payload em HTTP somente leitura
ou integrar o Control Plane diretamente ao artifact gerado, mantendo
`panel_can_start_runtime=false`.
