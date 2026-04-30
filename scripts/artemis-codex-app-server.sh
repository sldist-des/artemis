#!/usr/bin/env sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
format="text"

usage() {
  echo "usage: scripts/artemis-codex-app-server.sh [--artifact-root path] [--json]" >&2
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
  tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/artemis-codex-app-server.XXXXXX")
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
help_log="$log_dir/codex-app-server-help.txt"
version_log="$log_dir/codex-version.txt"
schema_log="$log_dir/codex-app-server-schema.txt"
schema_index="$work_root/schema-index.txt"

codex_installed=0
codex_path=""
if command -v codex >/dev/null 2>&1; then
  codex_installed=1
  codex_path=$(command -v codex)
fi

version_status=1
help_status=1
schema_status=1
schema_count=0

if [ "$codex_installed" -eq 1 ]; then
  set +e
  codex --version >"$version_log" 2>&1
  version_status=$?
  codex app-server --help >"$help_log" 2>&1
  help_status=$?
  set -e

  schema_tmp=$(mktemp -d "${TMPDIR:-/tmp}/artemis-codex-app-server-schema.XXXXXX")
  set +e
  codex app-server generate-json-schema --out "$schema_tmp" >"$schema_log" 2>&1
  schema_status=$?
  set -e
  if [ "$schema_status" -eq 0 ]; then
    find "$schema_tmp" -type f | sed "s#^$schema_tmp/##" | sort >"$schema_index"
    schema_count=$(wc -l <"$schema_index" | tr -d ' ')
  else
    : >"$schema_index"
  fi
  rm -rf "$schema_tmp"
else
  printf '%s\n' "codex is not installed" >"$version_log"
  printf '%s\n' "codex is not installed" >"$help_log"
  printf '%s\n' "codex is not installed" >"$schema_log"
  : >"$schema_index"
fi

sed -i 's/[[:space:]]*$//' "$version_log" "$help_log" "$schema_log"

supports_listen=0
supports_ws_auth=0
supports_schema=0
if grep -q -- "--listen" "$help_log"; then
  supports_listen=1
fi
if grep -q -- "--ws-auth" "$help_log"; then
  supports_ws_auth=1
fi
if grep -q -- "generate-json-schema" "$help_log"; then
  supports_schema=1
fi

overall="passed"
reason="Codex app-server local contract check passed."
if [ "$codex_installed" -ne 1 ]; then
  overall="failed"
  reason="codex CLI is not installed."
elif [ "$help_status" -ne 0 ]; then
  overall="failed"
  reason="codex app-server help did not run."
elif [ "$schema_status" -ne 0 ]; then
  overall="failed"
  reason="codex app-server schema generation did not run."
elif [ "$supports_listen" -ne 1 ] || [ "$supports_schema" -ne 1 ]; then
  overall="failed"
  reason="codex app-server help is missing expected protocol capabilities."
fi

payload=$(python3 - "$overall" "$reason" "$codex_installed" "$codex_path" "$version_status" "$help_status" "$schema_status" "$schema_count" "$supports_listen" "$supports_ws_auth" "$supports_schema" "$version_log" "$help_log" "$schema_log" "$schema_index" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

(
    overall,
    reason,
    codex_installed,
    codex_path,
    version_status,
    help_status,
    schema_status,
    schema_count,
    supports_listen,
    supports_ws_auth,
    supports_schema,
    version_log,
    help_log,
    schema_log,
    schema_index,
) = sys.argv[1:16]

def read(path):
    return Path(path).read_text(encoding="utf-8", errors="replace")

schema_files = [line for line in read(schema_index).splitlines() if line]

payload = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "overall": overall,
    "reason": reason,
    "mode": "read_only_contract_probe",
    "sources": [
        "https://developers.openai.com/codex/app-server",
        "https://openai.com/index/open-source-codex-orchestration-symphony/",
    ],
    "checks": {
        "codex_installed": codex_installed == "1",
        "codex_path": codex_path,
        "codex_version_exit_code": int(version_status),
        "app_server_help_exit_code": int(help_status),
        "schema_generation_exit_code": int(schema_status),
        "generated_schema_files": int(schema_count),
        "supports_listen": supports_listen == "1",
        "supports_ws_auth": supports_ws_auth == "1",
        "supports_schema_generation": supports_schema == "1",
    },
    "contract": {
        "terminal_first": True,
        "app_server_role": "event_source_and_rich_client_protocol",
        "not_owner_of_method": True,
        "remote_writes": "human_gate_only",
        "daemon": "out_of_scope",
        "default_transport": "stdio",
        "websocket_transport": "future_human_gate",
        "non_loopback_listener": "forbidden_without_explicit_human_gate",
        "thread_shell_command": "human_gate_required_because_it_runs_outside_thread_sandbox",
    },
    "mapping": [
        {
            "codex": "thread",
            "artemis": "task_exec_pack",
            "rule": "One durable thread may be linked to one Exec Pack or task workspace.",
        },
        {
            "codex": "turn",
            "artemis": "attempt",
            "rule": "Each turn maps to a supervised attempt with STATUS, VALIDATION, and HANDOFF evidence.",
        },
        {
            "codex": "item",
            "artemis": "event",
            "rule": "Items become append-only observable events for Control Plane and artifacts.",
        },
        {
            "codex": "approval_request",
            "artemis": "human_gate_or_policy_gate",
            "rule": "Command, file-change, user-input, and side-effecting tool approvals must stop for explicit decision.",
        },
        {
            "codex": "notification",
            "artemis": "control_plane_event",
            "rule": "Notifications update visible state but do not replace Exec Packs or Git history.",
        },
        {
            "codex": "thread_metadata",
            "artemis": "workspace_task_state",
            "rule": "Metadata may store task, workspace, branch, artifact path, and validation pointers.",
        },
    ],
    "event_contract": {
        "required_fields": [
            "event_id",
            "generated_at",
            "ticket",
            "exec_pack",
            "thread_id",
            "turn_id",
            "item_id",
            "event_type",
            "state",
            "artifact_path",
        ],
        "states": [
            "ready",
            "running",
            "validating",
            "review",
            "human_gate",
            "handoff",
            "done",
            "blocked",
        ],
        "approval_event_types": [
            "item/commandExecution/requestApproval",
            "item/fileChange/requestApproval",
            "item/tool/requestUserInput",
            "mcp_tool_side_effect_approval",
        ],
    },
    "allowed_first_cut": [
        "initialize",
        "initialized",
        "model/list",
        "thread/start",
        "thread/resume",
        "thread/read",
        "thread/list",
        "turn/start",
        "turn/steer",
        "turn/interrupt",
    ],
    "blocked_or_human_gate_methods": [
        "thread/shellCommand",
        "config/value/write",
        "config/batchWrite",
        "fs/writeFile",
        "fs/remove",
        "marketplace/install",
        "plugin/install",
        "plugin/uninstall",
        "account/login/start",
        "account/logout",
    ],
    "schema_files_sample": schema_files[:25],
    "logs": {
        "version": read(version_log),
        "help": read(help_log),
        "schema_generation": read(schema_log),
    },
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  printf '%s\n' "$payload" >"$artifact_root/codex-app-server-adapter.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "codex-app-server-adapter.json").read_text(encoding="utf-8"))

lines = [
    "# CODEX APP-SERVER ADAPTER CONTRACT",
    "",
    f"- Overall: {payload['overall']}",
    f"- Reason: {payload['reason']}",
    f"- Codex CLI: {payload['checks']['codex_path'] or 'missing'}",
    f"- Generated schema files during probe: {payload['checks']['generated_schema_files']}",
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
    "- Terminal remains sovereign.",
    "- App-server is an event source and rich-client protocol, not the owner of ARTEMIS.",
    "- Default first cut is stdio only.",
    "- WebSocket and non-loopback listeners require Human Gate.",
    "- Remote writes and auth changes require Human Gate.",
    "- No daemon is introduced in TKT-014.",
    "",
    "## Mapping",
    "",
    "| Codex app-server | ARTEMIS | Rule |",
    "|---|---|---|",
])
for item in payload["mapping"]:
    lines.append(f"| `{item['codex']}` | `{item['artemis']}` | {item['rule']} |")

lines.extend([
    "",
    "## Approval handling",
    "",
])
for event_type in payload["event_contract"]["approval_event_types"]:
    lines.append(f"- `{event_type}` -> Human Gate or policy gate")

lines.extend([
    "",
    "## Blocked or Human Gate methods",
    "",
])
for method in payload["blocked_or_human_gate_methods"]:
    lines.append(f"- `{method}`")

lines.extend([
    "",
    "## Schema sample",
    "",
])
for schema_file in payload["schema_files_sample"]:
    lines.append(f"- `{schema_file}`")

(root / "CODEX_APP_SERVER_ADAPTER.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
print(f"ARTEMIS Codex app-server Adapter: {payload['overall']}")
print(f"reason={payload['reason']}")
print(
    "schema_files="
    f"{payload['checks']['generated_schema_files']} "
    f"transport={payload['contract']['default_transport']} "
    f"terminal_first={payload['contract']['terminal_first']}"
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
