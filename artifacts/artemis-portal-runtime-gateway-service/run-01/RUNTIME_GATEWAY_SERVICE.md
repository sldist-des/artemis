# ARTEMIS Portal Runtime Gateway Read-only Service

- Overall: `runtime_gateway_service_ready`
- HTTP server started: `false`
- WebSocket opened: `false`
- POST routes enabled: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-085 - Control Plane Runtime Gateway Status View`

## Rotas planejadas

- `GET /runtime-gateway/health` - Read service health and read-only mode.
- `GET /runtime-gateway/status` - Read gateway state, side effects, gates and next cut.
- `GET /runtime-gateway/operators` - List registered runtime operators and connection states.
- `GET /runtime-gateway/projects` - List the current local project source and future project selector shape.
- `GET /runtime-gateway/readiness` - Explain what remains blocked before real runtime launch.
- `GET /runtime-gateway/evidence` - Return artifact paths for status, validation and handoff.

## Operadores visiveis

### Codex app-server

- Operator id: `codex_app_server`
- Adapter: `codex_app_server`
- Connection state: `planned_not_connected`
- Auth state: `requires_provider_connection_and_vault_lease`
- Runtime disponivel: `false`
- Leitura humana: Planejado, mas ainda nao conectado.

### Claude Code

- Operator id: `claude_code`
- Adapter: `claude_agent_sdk`
- Connection state: `planned_not_connected`
- Auth state: `requires_provider_connection_and_vault_lease`
- Runtime disponivel: `false`
- Leitura humana: Planejado, mas ainda nao conectado.

### Antigravity CLI

- Operator id: `antigravity_cli`
- Adapter: `antigravity_cli`
- Connection state: `unverified_adapter`
- Auth state: `blocked_until_capability_discovery`
- Runtime disponivel: `false`
- Leitura humana: Bloqueado ate descoberta de capacidades.

## Checks

- `gateway_contract_ready`: passed - Service consumes the Runtime Gateway contract before exposing panel data.
- `read_only_routes_only`: passed - Every declared endpoint is GET-only and non-mutating.
- `no_server_started`: passed - This cut writes a static read-only artifact and starts no persistent service.
- `panel_still_cannot_start_runtime`: passed - The Control Plane remains a reader and cannot launch provider runtime.
- `operators_visible`: passed - Codex app-server, Claude Code and Antigravity CLI appear in the read-only operator list.
- `no_runtime_side_effects`: passed - No auth, socket, agent launch, token spend, command execution or remote mutation happened.
