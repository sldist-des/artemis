#!/usr/bin/env sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
format="text"

usage() {
  echo "usage: scripts/artemis-claude-code.sh [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --json)
      format="json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

tmp_root=""
if [ -n "$artifact_root" ]; then
  work_root="$artifact_root"
  mkdir -p "$work_root/check-logs"
else
  tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/artemis-claude-code.XXXXXX")
  work_root="$tmp_root"
  mkdir -p "$work_root/check-logs"
fi

cleanup() {
  if [ -n "$tmp_root" ]; then
    rm -rf "$tmp_root"
  fi
}
trap cleanup EXIT INT TERM

log_dir="$work_root/check-logs"
help_log="$log_dir/claude-help.txt"
version_log="$log_dir/claude-version.txt"
auth_log="$log_dir/claude-auth.txt"
agents_log="$log_dir/claude-agents.txt"

claude_installed=0
claude_path=""
if command -v claude >/dev/null 2>&1; then
  claude_installed=1
  claude_path=$(command -v claude)
fi

version_status=1
help_status=1
auth_status=1
agents_status=1

if [ "$claude_installed" -eq 1 ]; then
  set +e
  claude --version >"$version_log" 2>&1
  version_status=$?
  claude --help >"$help_log" 2>&1
  help_status=$?
  claude auth status --text >"$auth_log" 2>&1
  auth_status=$?
  claude agents >"$agents_log" 2>&1
  agents_status=$?
  set -e
else
  printf '%s\n' "claude is not installed" >"$version_log"
  printf '%s\n' "claude is not installed" >"$help_log"
  printf '%s\n' "claude is not installed" >"$auth_log"
  printf '%s\n' "claude is not installed" >"$agents_log"
fi

for log_file in "$version_log" "$help_log" "$auth_log" "$agents_log"; do
  sed -i \
    -e 's/[[:space:]]*$//' \
    -e 's/[A-Za-z0-9._%+-][A-Za-z0-9._%+-]*@[A-Za-z0-9.-][A-Za-z0-9.-]*\.[A-Za-z][A-Za-z]*/<redacted-email>/g' \
    "$log_file"
done

supports_print=0
supports_output_format=0
supports_stream_json=0
supports_input_format=0
supports_hook_events=0
supports_agents=0
supports_allowed_tools=0
supports_disallowed_tools=0
supports_permission_mode=0
supports_debug_file=0
supports_worktree=0
supports_setting_sources=0

grep -q -- "--print" "$help_log" && supports_print=1
grep -q -- "--output-format" "$help_log" && supports_output_format=1
grep -q -- "stream-json" "$help_log" && supports_stream_json=1
grep -q -- "--input-format" "$help_log" && supports_input_format=1
grep -q -- "--include-hook-events" "$help_log" && supports_hook_events=1
grep -q -- "--agents" "$help_log" && supports_agents=1
grep -q -- "--allowedTools" "$help_log" && supports_allowed_tools=1
grep -q -- "--disallowedTools" "$help_log" && supports_disallowed_tools=1
grep -q -- "--permission-mode" "$help_log" && supports_permission_mode=1
grep -q -- "--debug-file" "$help_log" && supports_debug_file=1
grep -q -- "--worktree" "$help_log" && supports_worktree=1
grep -q -- "--setting-sources" "$help_log" && supports_setting_sources=1

project_claude_adapter="missing"
if [ -f "CLAUDE.md" ] && grep -q "AGENTS.md" CLAUDE.md; then
  project_claude_adapter="thin_adapter"
elif [ -f "CLAUDE.md" ]; then
  project_claude_adapter="present_without_agents_reference"
fi

overall="passed"
reason="Claude Code local contract check passed."
if [ "$claude_installed" -ne 1 ]; then
  overall="human_gate"
  reason="claude CLI is not installed."
elif [ "$help_status" -ne 0 ]; then
  overall="failed"
  reason="claude --help did not run."
elif [ "$supports_print" -ne 1 ] || [ "$supports_output_format" -ne 1 ] || [ "$supports_agents" -ne 1 ]; then
  overall="failed"
  reason="claude --help is missing expected adapter capabilities."
elif [ "$auth_status" -ne 0 ]; then
  overall="human_gate"
  reason="claude auth status did not pass."
elif [ "$project_claude_adapter" != "thin_adapter" ]; then
  overall="failed"
  reason="CLAUDE.md is not a thin adapter pointing to AGENTS.md."
fi

payload=$(python3 - "$overall" "$reason" "$claude_installed" "$claude_path" "$version_status" "$help_status" "$auth_status" "$agents_status" "$supports_print" "$supports_output_format" "$supports_stream_json" "$supports_input_format" "$supports_hook_events" "$supports_agents" "$supports_allowed_tools" "$supports_disallowed_tools" "$supports_permission_mode" "$supports_debug_file" "$supports_worktree" "$supports_setting_sources" "$project_claude_adapter" "$version_log" "$help_log" "$auth_log" "$agents_log" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    overall,
    reason,
    claude_installed,
    claude_path,
    version_status,
    help_status,
    auth_status,
    agents_status,
    supports_print,
    supports_output_format,
    supports_stream_json,
    supports_input_format,
    supports_hook_events,
    supports_agents,
    supports_allowed_tools,
    supports_disallowed_tools,
    supports_permission_mode,
    supports_debug_file,
    supports_worktree,
    supports_setting_sources,
    project_claude_adapter,
    version_log,
    help_log,
    auth_log,
    agents_log,
) = sys.argv[1:26]

def read(path):
    return Path(path).read_text(encoding="utf-8", errors="replace")

payload = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "overall": overall,
    "reason": reason,
    "mode": "read_only_contract_probe",
    "sources": [
        "https://code.claude.com/docs/en/cli-reference",
        "https://code.claude.com/docs/en/hooks",
        "https://code.claude.com/docs/en/sub-agents",
        "https://code.claude.com/docs/en/agent-sdk/overview",
    ],
    "checks": {
        "claude_installed": claude_installed == "1",
        "claude_path": claude_path,
        "claude_version_exit_code": int(version_status),
        "claude_help_exit_code": int(help_status),
        "claude_auth_exit_code": int(auth_status),
        "claude_agents_exit_code": int(agents_status),
        "project_claude_adapter": project_claude_adapter,
        "supports_print": supports_print == "1",
        "supports_output_format": supports_output_format == "1",
        "supports_stream_json": supports_stream_json == "1",
        "supports_input_format": supports_input_format == "1",
        "supports_hook_events": supports_hook_events == "1",
        "supports_agents": supports_agents == "1",
        "supports_allowed_tools": supports_allowed_tools == "1",
        "supports_disallowed_tools": supports_disallowed_tools == "1",
        "supports_permission_mode": supports_permission_mode == "1",
        "supports_debug_file": supports_debug_file == "1",
        "supports_worktree": supports_worktree == "1",
        "supports_setting_sources": supports_setting_sources == "1",
    },
    "contract": {
        "agents_md_canonical": True,
        "claude_md_role": "thin_runtime_adapter",
        "runner_role": "headless_or_sdk_runner_adapter",
        "terminal_first": True,
        "remote_writes": "human_gate_only",
        "daemon": "out_of_scope",
        "remote_control": "human_gate_only",
        "dangerously_skip_permissions": "forbidden",
        "default_first_cut": "claude -p with json or stream-json output under supervised runner",
        "production_automation": "prefer_agent_sdk_after_contract_is_stable",
    },
    "mapping": [
        {
            "claude": "claude -p / --print",
            "artemis": "supervised_attempt",
            "rule": "Non-interactive Claude Code run maps to one ARTEMIS attempt with artifacts.",
        },
        {
            "claude": "--output-format json",
            "artemis": "attempt_result",
            "rule": "Single structured result records duration, cost, turns, error state, and session id when available.",
        },
        {
            "claude": "--output-format stream-json",
            "artemis": "event_stream",
            "rule": "Streaming messages become append-only Control Plane and artifact events.",
        },
        {
            "claude": "--include-hook-events",
            "artemis": "guardrail_event_stream",
            "rule": "Hook lifecycle events are evidence and may trigger Human Gate.",
        },
        {
            "claude": "SessionStart",
            "artemis": "context_load",
            "rule": "Load Exec Pack, AGENTS.md, workflow, and task evidence at session start.",
        },
        {
            "claude": "UserPromptSubmit",
            "artemis": "intent_gate",
            "rule": "Validate prompt scope and block secrets or out-of-scope requests before execution.",
        },
        {
            "claude": "PreToolUse",
            "artemis": "policy_gate",
            "rule": "Block or ask before risky Bash/Edit/Write/Web/MCP operations.",
        },
        {
            "claude": "PostToolUse",
            "artemis": "evidence_event",
            "rule": "Record successful tool effects into artifacts and Control Plane events.",
        },
        {
            "claude": "Notification",
            "artemis": "human_gate_signal",
            "rule": "Permission prompts and waiting states become visible Human Gate signals.",
        },
        {
            "claude": "Stop / SubagentStop",
            "artemis": "handoff_or_validation_gate",
            "rule": "Stop hooks can block completion until required validation and handoff evidence exist.",
        },
        {
            "claude": "subagent / Agent tool",
            "artemis": "specialist_agent",
            "rule": "Specialized Claude subagents remain under AGENTS.md authority and scoped tool permissions.",
        },
        {
            "claude": "--worktree",
            "artemis": "workspace_isolation_candidate",
            "rule": "May become a future workspace adapter but does not replace ARTEMIS worktree policy yet.",
        },
    ],
    "event_contract": {
        "required_fields": [
            "event_id",
            "generated_at",
            "ticket",
            "exec_pack",
            "session_id",
            "turn_index",
            "hook_event",
            "tool_name",
            "agent_name",
            "event_type",
            "state",
            "artifact_path",
        ],
        "human_gate_events": [
            "Notification",
            "UserPromptSubmit:block",
            "PreToolUse:ask",
            "PreToolUse:deny",
            "Stop:block",
            "SubagentStop:block",
            "dangerous_permission_mode_requested",
            "remote_control_requested",
        ],
        "protected_tools": [
            "Bash",
            "Edit",
            "Write",
            "WebFetch",
            "WebSearch",
            "Agent",
            "MCP tools",
        ],
    },
    "allowed_first_cut": [
        "claude --version",
        "claude --help",
        "claude auth status --text",
        "claude agents",
        "claude -p --output-format json",
        "claude -p --output-format stream-json --include-hook-events",
    ],
    "blocked_or_human_gate_flags": [
        "--dangerously-skip-permissions",
        "--allow-dangerously-skip-permissions",
        "--remote",
        "--remote-control",
        "--mcp-config with unreviewed server",
        "--allowedTools with broad Bash/Edit/Write",
        "--permission-mode bypassPermissions",
        "--plugin-dir with unreviewed plugins",
    ],
    "logs": {
        "version": read(version_log),
        "help": read(help_log),
        "auth": read(auth_log),
        "agents": read(agents_log),
    },
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  printf '%s\n' "$payload" >"$artifact_root/claude-code-adapter.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path
from scripts.artemis_event_common import event, event_log, write_event_log

root = Path(sys.argv[1])
payload = json.loads((root / "claude-code-adapter.json").read_text(encoding="utf-8"))

lines = [
    "# CLAUDE CODE ADAPTER CONTRACT",
    "",
    f"- Overall: {payload['overall']}",
    f"- Reason: {payload['reason']}",
    f"- Claude CLI: {payload['checks']['claude_path'] or 'missing'}",
    f"- CLAUDE.md role: {payload['checks']['project_claude_adapter']}",
    "",
    "## Sources",
    "",
]
for source in payload["sources"]:
    lines.append(f"- {source}")

lines.extend([
    "",
    "## Boundary",
    "",
    "- AGENTS.md remains canonical.",
    "- CLAUDE.md remains a thin runtime adapter.",
    "- Claude Code is a Runner Adapter, not the owner of ARTEMIS.",
    "- First cut is headless/read-only contract probing.",
    "- Remote control, broad permissions, unreviewed MCP, and bypass permission modes require Human Gate.",
    "- No daemon is introduced in TKT-015.",
    "",
    "## Mapping",
    "",
    "| Claude Code | ARTEMIS | Rule |",
    "|---|---|---|",
])
for item in payload["mapping"]:
    lines.append(f"| `{item['claude']}` | `{item['artemis']}` | {item['rule']} |")

lines.extend([
    "",
    "## Human Gate Events",
    "",
])
for event_type in payload["event_contract"]["human_gate_events"]:
    lines.append(f"- `{event_type}`")

lines.extend([
    "",
    "## Blocked or Human Gate Flags",
    "",
])
for flag in payload["blocked_or_human_gate_flags"]:
    lines.append(f"- `{flag}`")

(root / "CLAUDE_CODE_ADAPTER.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

state_to = "done"
severity = "info"
gate = {"kind": "none", "status": "not_applicable"}
if payload["overall"] == "human_gate":
    state_to = "human_gate"
    severity = "warning"
    gate = {"kind": "human", "status": "human_gate", "reason": payload["reason"]}
elif payload["overall"] == "failed":
    state_to = "blocked"
    severity = "error"
    gate = {"kind": "validation", "status": "failed", "reason": payload["reason"]}

event_payload = {
    "overall": payload["overall"],
    "reason": payload["reason"],
    "checks": payload["checks"],
    "contract": payload["contract"],
    "mapping_count": len(payload["mapping"]),
    "event_contract": payload["event_contract"],
    "blocked_or_human_gate_flags": payload["blocked_or_human_gate_flags"],
}
events = [
    event(
        event_id="evt_tkt-015_claude_code_contract",
        event_type="adapter.contract_recorded",
        generated_at=payload["generated_at"],
        producer={"adapter": "claude_code", "name": "scripts/artemis-claude-code.sh", "mode": "read_only"},
        ticket="TKT-015",
        title="Preparar Claude Code adapter",
        exec_pack="docs/exec-packs/done/TKT-015-claude-code-adapter.md",
        artifact_root=str(root),
        state_from="handoff",
        state_to=state_to,
        runner={"kind": "claude_code"},
        gate=gate,
        severity=severity,
        logs=[
            str(root / "check-logs" / "claude-version.txt"),
            str(root / "check-logs" / "claude-help.txt"),
            str(root / "check-logs" / "claude-auth.txt"),
            str(root / "check-logs" / "claude-agents.txt"),
        ],
        payload=event_payload,
    )
]
write_event_log(root / "events.json", event_log(source="scripts/artemis-claude-code.sh", generated_at=payload["generated_at"], events=events))
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
print(f"ARTEMIS Claude Code Adapter: {payload['overall']}")
print(f"reason={payload['reason']}")
print(
    "headless="
    f"{payload['checks']['supports_print']} "
    f"stream_json={payload['checks']['supports_stream_json']} "
    f"agents_md_canonical={payload['contract']['agents_md_canonical']}"
)
PY
fi

case "$overall" in
  failed)
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
