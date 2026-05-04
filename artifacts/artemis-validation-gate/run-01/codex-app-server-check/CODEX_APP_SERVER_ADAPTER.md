# CODEX APP-SERVER ADAPTER CONTRACT

- Overall: passed
- Reason: Codex app-server local contract check passed.
- Codex CLI: /usr/bin/codex
- Generated schema files during probe: 234

## Sources

- https://developers.openai.com/codex/app-server
- https://openai.com/index/open-source-codex-orchestration-symphony/

## Boundary

- Terminal remains sovereign.
- App-server is an event source and rich-client protocol, not the owner of ARTEMIS.
- Default first cut is stdio only.
- WebSocket and non-loopback listeners require Human Gate.
- Remote writes and auth changes require Human Gate.
- No daemon is introduced in TKT-014.

## Mapping

| Codex app-server | ARTEMIS | Rule |
|---|---|---|
| `thread` | `task_exec_pack` | One durable thread may be linked to one Exec Pack or task workspace. |
| `turn` | `attempt` | Each turn maps to a supervised attempt with STATUS, VALIDATION, and HANDOFF evidence. |
| `item` | `event` | Items become append-only observable events for Control Plane and artifacts. |
| `approval_request` | `human_gate_or_policy_gate` | Command, file-change, user-input, and side-effecting tool approvals must stop for explicit decision. |
| `notification` | `control_plane_event` | Notifications update visible state but do not replace Exec Packs or Git history. |
| `thread_metadata` | `workspace_task_state` | Metadata may store task, workspace, branch, artifact path, and validation pointers. |

## Approval handling

- `item/commandExecution/requestApproval` -> Human Gate or policy gate
- `item/fileChange/requestApproval` -> Human Gate or policy gate
- `item/tool/requestUserInput` -> Human Gate or policy gate
- `mcp_tool_side_effect_approval` -> Human Gate or policy gate

## Blocked or Human Gate methods

- `thread/shellCommand`
- `config/value/write`
- `config/batchWrite`
- `fs/writeFile`
- `fs/remove`
- `marketplace/install`
- `plugin/install`
- `plugin/uninstall`
- `account/login/start`
- `account/logout`

## Schema sample

- `ApplyPatchApprovalParams.json`
- `ApplyPatchApprovalResponse.json`
- `ChatgptAuthTokensRefreshParams.json`
- `ChatgptAuthTokensRefreshResponse.json`
- `ClientNotification.json`
- `ClientRequest.json`
- `CommandExecutionRequestApprovalParams.json`
- `CommandExecutionRequestApprovalResponse.json`
- `DynamicToolCallParams.json`
- `DynamicToolCallResponse.json`
- `ExecCommandApprovalParams.json`
- `ExecCommandApprovalResponse.json`
- `FileChangeRequestApprovalParams.json`
- `FileChangeRequestApprovalResponse.json`
- `FuzzyFileSearchParams.json`
- `FuzzyFileSearchResponse.json`
- `FuzzyFileSearchSessionCompletedNotification.json`
- `FuzzyFileSearchSessionUpdatedNotification.json`
- `JSONRPCError.json`
- `JSONRPCErrorError.json`
- `JSONRPCMessage.json`
- `JSONRPCNotification.json`
- `JSONRPCRequest.json`
- `JSONRPCResponse.json`
- `McpServerElicitationRequestParams.json`
