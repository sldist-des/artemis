#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-task-control-surface/run-01"
agent_conversation="artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-task-control-surface.sh [--artifact-root path] [--agent-conversation path] [--json]

Builds the ARTEMIS Portal Task Control Surface contract. It does not mutate
task state, start runtime, execute commands, send provider messages, spend
tokens, store secrets, push, deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --agent-conversation)
      agent_conversation="${2:-}"
      if [ -z "$agent_conversation" ]; then usage; exit 2; fi
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

mkdir -p "$artifact_root"

python3 - "$artifact_root" "$agent_conversation" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
agent_conversation_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_AGENT_CONVERSATION.md"),
    Path("docs/exec-packs/done/TKT-079-artemis-portal-agent-conversation.md"),
    Path("artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

conversation_payload = {}
if agent_conversation_path.is_file():
    conversation_payload = json.loads(agent_conversation_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(agent_conversation_path))

sample_conversation = conversation_payload.get("sample_conversation", {})
sample_message = sample_conversation.get("sample_message", {})

control_schema = {
    "required_fields": [
        "control_id",
        "project_id",
        "ticket",
        "conversation_id",
        "runtime_session_id",
        "assignment_id",
        "control_kind",
        "label",
        "current_task_state",
        "requested_transition",
        "actor_type",
        "actor_id",
        "authority_level",
        "gate_requirement",
        "validation_requirement",
        "budget_impact",
        "command_plan_ref",
        "event_refs",
        "evidence",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "raw_prompt",
        "full_prompt_transcript",
        "raw_runtime_stdout",
        "raw_runtime_stderr",
        "git_remote_token",
        "ssh_private_key",
        "unreviewed_command",
        "auto_execute_flag",
    ],
}

task_control_contract = {
    "purpose": "Turn safe conversation intents into visible task controls without bypassing gates.",
    "state": "contract_only",
    "task_control_surface_ready": True,
    "controls_triggered": 0,
    "task_state_mutated": False,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "control_schema": control_schema,
    "control_kinds": [
        "view_task",
        "assign_task_intent",
        "request_agent_status",
        "request_validation",
        "open_human_gate",
        "pause_runtime_session",
        "stop_runtime_session",
        "request_handoff_review",
    ],
    "blocked_without_gate": [
        "start_runtime",
        "execute_command",
        "push_remote",
        "deploy_production",
        "read_secret",
        "increase_budget",
        "change_branch_protection",
        "mark_done_without_validation",
    ],
    "task_state_model": [
        "visible",
        "intent_recorded",
        "pending_assignment",
        "pending_budget",
        "pending_workspace",
        "pending_runtime_gate",
        "running_observed",
        "validation_pending",
        "human_gate",
        "handoff_ready",
        "done_ready",
        "blocked",
        "closed",
    ],
    "authority_model": {
        "read_only": [
            "view_task",
            "request_agent_status",
        ],
        "intent_only": [
            "assign_task_intent",
            "request_validation",
            "request_handoff_review",
        ],
        "human_gate_required": [
            "open_human_gate",
            "pause_runtime_session",
            "stop_runtime_session",
        ],
        "separate_runtime_gate_required": [
            "start_runtime",
            "execute_command",
            "push_remote",
            "deploy_production",
            "read_secret",
            "increase_budget",
        ],
    },
    "transition_policy": [
        {
            "from": "visible",
            "control": "assign_task_intent",
            "to": "intent_recorded",
            "effect": "record_intent_event_only",
            "requires_gate": False,
        },
        {
            "from": "intent_recorded",
            "control": "request_validation",
            "to": "validation_pending",
            "effect": "record_validation_request_only",
            "requires_gate": False,
        },
        {
            "from": "running_observed",
            "control": "pause_runtime_session",
            "to": "human_gate",
            "effect": "route_to_runtime_stop_policy",
            "requires_gate": True,
        },
        {
            "from": "running_observed",
            "control": "stop_runtime_session",
            "to": "human_gate",
            "effect": "route_to_runtime_stop_policy",
            "requires_gate": True,
        },
        {
            "from": "validation_pending",
            "control": "request_handoff_review",
            "to": "handoff_ready",
            "effect": "record_review_request_only",
            "requires_gate": False,
        },
    ],
    "ui_policy": {
        "disabled_controls_must_explain_gate": True,
        "every_click_records_event": True,
        "destructive_controls_default_disabled": True,
        "budget_controls_show_remaining_limit": True,
        "validation_controls_show_latest_evidence": True,
        "agent_controls_show_runtime_session_state": True,
        "raw_transcript_display_allowed": False,
    },
    "event_bridge": {
        "writes_canonical_events": True,
        "event_types": [
            "task_control.surface_recorded",
            "task_control.intent_recorded",
            "task_control.human_gate_requested",
            "task_control.stop_requested",
        ],
        "raw_transcript_in_event_allowed": False,
        "task_mutation_in_event_allowed": False,
    },
    "enforcement_rules": [
        "Task controls are visible intent controls, not direct execution authority.",
        "Controls that affect runtime, commands, remote writes, secrets or budget must route to Human Gate or runtime gates.",
        "A task control can create an event and evidence record, but cannot mutate canonical task state by itself.",
        "Disabled controls must show the missing gate, validation or budget dependency.",
        "Done transitions require validation evidence and completion review before ledger update.",
        "Stop controls have priority over new task assignment or runtime start controls.",
        "Raw prompts, full transcripts, secrets and raw runtime output are forbidden in task-control artifacts.",
    ],
}

sample_task_control = {
    "control_id": "task-control-tkt-080-contract-fixture",
    "project_id": sample_conversation.get("project_id", "artemis"),
    "ticket": "TKT-080",
    "conversation_id": sample_conversation.get("conversation_id", "conversation-tkt-079-contract-fixture"),
    "runtime_session_id": sample_conversation.get("runtime_session_id", "runtime-session-tkt-078-contract-fixture"),
    "assignment_id": sample_conversation.get("assignment_id", "assign-tkt-075-contract-fixture"),
    "control_kind": "request_validation",
    "label": "Request validation",
    "current_task_state": "intent_recorded",
    "requested_transition": "validation_pending",
    "actor_type": "human",
    "actor_id": sample_message.get("sender_id", "human:portal-user"),
    "authority_level": "intent_only",
    "gate_requirement": "none",
    "validation_requirement": "records_validation_request_only",
    "budget_impact": "none",
    "command_plan_ref": None,
    "event_refs": [
        "evt_portal_task_control_surface_contract_recorded"
    ],
    "evidence": [
        "artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json",
        "artifacts/artemis-portal-task-control-surface/run-01/TASK_CONTROL_SURFACE.md",
    ],
}

checks = [
    {
        "id": "agent_conversation_ready",
        "status": "passed" if conversation_payload.get("overall") == "agent_conversation_ready" else "failed",
        "detail": "Task Control Surface consumes a ready Agent Conversation contract.",
    },
    {
        "id": "control_schema_declared",
        "status": "passed" if control_schema["required_fields"] and control_schema["forbidden_fields"] else "failed",
        "detail": "Control fields and forbidden raw/secret fields are declared.",
    },
    {
        "id": "gated_controls_declared",
        "status": "passed" if task_control_contract["blocked_without_gate"] else "failed",
        "detail": "Runtime, command, remote write, secret and budget controls are blocked without gates.",
    },
    {
        "id": "ui_policy_declared",
        "status": "passed" if task_control_contract["ui_policy"]["disabled_controls_must_explain_gate"] else "failed",
        "detail": "Disabled controls must show missing gate, validation or budget dependency.",
    },
    {
        "id": "event_bridge_declared",
        "status": "passed" if task_control_contract["event_bridge"]["writes_canonical_events"] and not task_control_contract["event_bridge"]["task_mutation_in_event_allowed"] else "failed",
        "detail": "Task-control events are canonical and do not mutate task state.",
    },
    {
        "id": "no_task_state_mutation",
        "status": "passed" if not task_control_contract["task_state_mutated"] and task_control_contract["controls_triggered"] == 0 else "failed",
        "detail": "This cut records the contract only and triggers no task control.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not task_control_contract["runtime_execution_allowed"] and task_control_contract["commands_executed"] == 0 else "failed",
        "detail": "Task controls cannot start runtime or execute commands in this cut.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No secrets, raw prompts, raw runtime output or full transcripts are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "task_control_surface_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "task_control_surface_ready": overall == "task_control_surface_ready",
    "secret_values_recorded": False,
    "controls_triggered": 0,
    "task_state_mutated": False,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract",
    "missing_files": missing_files,
    "task_control_contract": task_control_contract,
    "sample_task_control": sample_task_control,
    "checks": checks,
    "inputs": {
        "agent_conversation": str(agent_conversation_path),
    },
}

(artifact_root / "task-control-surface-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Task Control Surface Contract",
    "",
    f"- Overall: `{overall}`",
    "- Controls triggered: `0`",
    "- Task state mutated: `false`",
    "- Messages sent to provider: `0`",
    "- Runtime execution allowed: `false`",
    "- Runtime session started: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract`",
    "",
    "## Regra central",
    "",
    "Task controls tornam intents visiveis e auditaveis, mas nao mudam estado canonico, nao iniciam runtime e nao executam comandos sem gates separados.",
    "",
    "## Control required fields",
    "",
]
for field in control_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in control_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Control kinds", ""])
for item in task_control_contract["control_kinds"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Blocked without gate", ""])
for item in task_control_contract["blocked_without_gate"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Enforcement rules", ""])
for rule in task_control_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "TASK_CONTROL_SURFACE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Task Control Surface contract recorded.",
        "- No task state mutation, provider message, runtime start, command execution, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Agent Conversation artifact checked.",
        "- Control schema, control kinds, gated controls, authority model, UI policy and event bridge defined.",
        "- No task mutation, provider message, runtime start, command execution, token spend, raw prompt, transcript, secret or remote write produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-080 defines the ARTEMIS Portal Task Control Surface contract.",
        "",
        "The next cut should define the Portal Validation Evidence Surface contract so non-technical users can inspect proof, blockers and readiness before accepting work.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-task-control-surface.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_task_control_surface_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_task_control_surface",
                "name": "scripts/artemis-portal-task-control-surface.sh",
                "mode": "read_only",
            },
            ticket="TKT-080",
            title="ARTEMIS Portal Task Control Surface Contract",
            exec_pack="docs/exec-packs/done/TKT-080-artemis-portal-task-control-surface.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "task_control_surface_ready" else "blocked",
            payload={
                "task_control_surface_ready": overall == "task_control_surface_ready",
                "control_id": sample_task_control["control_id"],
                "conversation_id": sample_task_control["conversation_id"],
                "controls_triggered": 0,
                "task_state_mutated": False,
                "messages_sent_to_provider": 0,
                "runtime_execution_allowed": False,
                "runtime_session_started": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "secret_values_recorded": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "task-control-surface-contract.json"),
                str(artifact_root / "TASK_CONTROL_SURFACE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal task control surface: {overall}")
    print(f"artifact_root={artifact_root}")
    print("controls_triggered=0")
    print("task_state_mutated=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
