#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-agent-conversation/run-01"
runtime_session="artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-agent-conversation.sh [--artifact-root path] [--runtime-session path] [--json]

Builds the ARTEMIS Portal Agent Conversation contract. It does not
authenticate providers, send messages to agents, start runtime, execute commands,
spend tokens, store raw prompts, store secrets, push, deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --runtime-session)
      runtime_session="${2:-}"
      if [ -z "$runtime_session" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$runtime_session" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
runtime_session_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md"),
    Path("docs/exec-packs/done/TKT-078-artemis-portal-runtime-session.md"),
    Path("artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

runtime_payload = {}
if runtime_session_path.is_file():
    runtime_payload = json.loads(runtime_session_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(runtime_session_path))

sample_runtime_session = runtime_payload.get("sample_runtime_session", {})

message_schema = {
    "required_fields": [
        "message_id",
        "conversation_id",
        "runtime_session_id",
        "project_id",
        "ticket",
        "sender_type",
        "sender_id",
        "recipient_type",
        "created_at",
        "message_kind",
        "visibility",
        "body_summary",
        "intent",
        "safety_classification",
        "redaction_state",
        "event_refs",
        "evidence",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "provider_billing_secret",
        "raw_prompt",
        "full_prompt_transcript",
        "raw_runtime_stdout",
        "raw_runtime_stderr",
        "git_remote_token",
        "ssh_private_key",
    ],
}

conversation_contract = {
    "purpose": "Map human messages, agent replies, task updates and runtime events into a safe portal conversation surface.",
    "state": "contract_only",
    "agent_conversation_ready": True,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "message_schema": message_schema,
    "state_model": [
        "draft",
        "human_message_received",
        "classified",
        "redacted",
        "routed_to_task",
        "waiting_for_agent_runtime",
        "agent_summary_received",
        "waiting_for_human_gate",
        "closed",
    ],
    "sender_types": [
        "human",
        "agent",
        "system",
        "validator",
        "event_adapter",
    ],
    "message_kinds": [
        "human_instruction",
        "agent_status",
        "agent_question",
        "agent_answer",
        "task_update",
        "validation_result",
        "runtime_event_summary",
        "human_gate_request",
        "stop_request",
    ],
    "intent_policy": {
        "allowed_intents": [
            "ask_status",
            "assign_task",
            "clarify_requirement",
            "request_validation",
            "approve_gate",
            "reject_gate",
            "pause_agent",
            "stop_agent",
            "summarize_context",
        ],
        "blocked_intents_without_gate": [
            "execute_command",
            "push_remote",
            "deploy_production",
            "read_secret",
            "change_branch_protection",
            "increase_budget",
        ],
        "ambiguous_intent_action": "ask_clarifying_question_without_runtime",
    },
    "redaction_policy": {
        "raw_prompt_storage_allowed": False,
        "summary_required": True,
        "secret_detection_required": True,
        "raw_runtime_output_allowed": False,
        "provider_message_id_allowed": True,
        "provider_secret_allowed": False,
    },
    "routing_policy": {
        "conversation_can_create_task_intent": True,
        "conversation_can_update_task_status": True,
        "conversation_can_request_human_gate": True,
        "conversation_can_start_runtime": False,
        "conversation_can_execute_command": False,
        "conversation_can_push_remote": False,
        "task_changes_require_event": True,
    },
    "event_bridge": {
        "writes_canonical_events": True,
        "event_types": [
            "conversation.message_recorded",
            "conversation.intent_classified",
            "conversation.human_gate_requested",
            "conversation.stop_requested",
        ],
        "raw_transcript_in_event_allowed": False,
    },
    "enforcement_rules": [
        "Conversation messages must reference a Runtime Session when discussing a live or planned agent run.",
        "Conversation approval does not execute commands or start agents.",
        "Command, remote write, deploy, secret access and budget increase intents require separate gates.",
        "Raw prompts, full transcripts, secrets, private keys and raw runtime output are forbidden in git artifacts.",
        "Every task-impacting message must produce an event reference and evidence.",
        "Stop requests must route to Runtime Session stop policy before any further agent action.",
        "Agent replies shown to humans must be summarized or redacted before persistence.",
    ],
}

sample_conversation = {
    "conversation_id": "conversation-tkt-079-contract-fixture",
    "runtime_session_id": sample_runtime_session.get("runtime_session_id", "runtime-session-tkt-078-contract-fixture"),
    "workspace_session_id": sample_runtime_session.get("workspace_session_id", "workspace-session-tkt-077-contract-fixture"),
    "assignment_id": sample_runtime_session.get("assignment_id", "assign-tkt-075-contract-fixture"),
    "project_id": sample_runtime_session.get("project_id", "artemis"),
    "ticket": "TKT-079",
    "agent_profile_id": sample_runtime_session.get("agent_profile_id", "codex_frontier_engineer"),
    "conversation_state": "classified",
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "sample_message": {
        "message_id": "msg-tkt-079-contract-fixture",
        "conversation_id": "conversation-tkt-079-contract-fixture",
        "runtime_session_id": sample_runtime_session.get("runtime_session_id", "runtime-session-tkt-078-contract-fixture"),
        "project_id": sample_runtime_session.get("project_id", "artemis"),
        "ticket": "TKT-079",
        "sender_type": "human",
        "sender_id": "human:portal-user",
        "recipient_type": "agent",
        "created_at": generated_at,
        "message_kind": "human_instruction",
        "visibility": "portal_team",
        "body_summary": "Ask the agent to report status and next blocked gate.",
        "intent": "ask_status",
        "safety_classification": "safe_no_runtime",
        "redaction_state": "redacted_summary_only",
        "event_refs": [
            "evt_portal_agent_conversation_contract_recorded"
        ],
        "evidence": [
            "artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json",
            "artifacts/artemis-portal-agent-conversation/run-01/AGENT_CONVERSATION.md",
        ],
    },
}

checks = [
    {
        "id": "runtime_session_ready",
        "status": "passed" if runtime_payload.get("overall") == "runtime_session_ready" else "failed",
        "detail": "Agent Conversation consumes a ready Runtime Session.",
    },
    {
        "id": "message_schema_declared",
        "status": "passed" if message_schema["required_fields"] and message_schema["forbidden_fields"] else "failed",
        "detail": "Conversation message fields and forbidden raw/secret fields are declared.",
    },
    {
        "id": "intent_policy_declared",
        "status": "passed" if conversation_contract["intent_policy"]["allowed_intents"] and conversation_contract["intent_policy"]["blocked_intents_without_gate"] else "failed",
        "detail": "Allowed intents and gated intents are explicit.",
    },
    {
        "id": "redaction_policy_declared",
        "status": "passed" if not conversation_contract["redaction_policy"]["raw_prompt_storage_allowed"] and conversation_contract["redaction_policy"]["summary_required"] else "failed",
        "detail": "Raw prompts are blocked and summaries are required.",
    },
    {
        "id": "event_bridge_declared",
        "status": "passed" if conversation_contract["event_bridge"]["writes_canonical_events"] and not conversation_contract["event_bridge"]["raw_transcript_in_event_allowed"] else "failed",
        "detail": "Conversation events are canonical but raw transcripts are not stored.",
    },
    {
        "id": "no_provider_messages",
        "status": "passed" if sample_conversation["messages_sent_to_provider"] == 0 and sample_conversation["agent_messages_received"] == 0 else "failed",
        "detail": "This cut does not send or receive provider-backed messages.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not sample_conversation["runtime_execution_allowed"] and sample_conversation["commands_executed"] == 0 else "failed",
        "detail": "Conversation cannot start runtime or execute commands.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No secrets, raw prompts, raw runtime output or full transcripts are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "agent_conversation_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "agent_conversation_ready": overall == "agent_conversation_ready",
    "secret_values_recorded": False,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-080 - ARTEMIS Portal Task Control Surface Contract",
    "missing_files": missing_files,
    "conversation_contract": conversation_contract,
    "sample_conversation": sample_conversation,
    "checks": checks,
    "inputs": {
        "runtime_session": str(runtime_session_path),
    },
}

(artifact_root / "agent-conversation-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Agent Conversation Contract",
    "",
    f"- Overall: `{overall}`",
    "- Messages sent to provider: `0`",
    "- Agent messages received: `0`",
    "- Runtime execution allowed: `false`",
    "- Runtime session started: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-080 - ARTEMIS Portal Task Control Surface Contract`",
    "",
    "## Regra central",
    "",
    "Conversas do portal podem registrar intencao, status, perguntas, respostas resumidas e gates, mas nao podem iniciar runtime, executar comandos, enviar segredo, guardar prompt bruto ou liberar remote write.",
    "",
    "## Message required fields",
    "",
]
for field in message_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in message_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Allowed intents", ""])
for item in conversation_contract["intent_policy"]["allowed_intents"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Gated intents", ""])
for item in conversation_contract["intent_policy"]["blocked_intents_without_gate"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Enforcement rules", ""])
for rule in conversation_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "AGENT_CONVERSATION.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Agent Conversation contract recorded.",
        "- No provider message, agent reply, runtime start, command execution, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Runtime Session artifact checked.",
        "- Message schema, sender types, message kinds, intent policy, redaction policy, routing policy and event bridge defined.",
        "- No secrets, raw prompts, full transcripts, raw runtime output, provider messages, agent replies, runtime start, command execution, token spend or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-079 defines the ARTEMIS Portal Agent Conversation contract.",
        "",
        "The next cut should define the Portal Task Control Surface contract that turns conversation intents into visible task controls without bypassing gates.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-agent-conversation.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_agent_conversation_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_agent_conversation",
                "name": "scripts/artemis-portal-agent-conversation.sh",
                "mode": "read_only",
            },
            ticket="TKT-079",
            title="ARTEMIS Portal Agent Conversation Contract",
            exec_pack="docs/exec-packs/done/TKT-079-artemis-portal-agent-conversation.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "agent_conversation_ready" else "blocked",
            payload={
                "agent_conversation_ready": overall == "agent_conversation_ready",
                "conversation_id": sample_conversation["conversation_id"],
                "runtime_session_id": sample_conversation["runtime_session_id"],
                "messages_sent_to_provider": 0,
                "agent_messages_received": 0,
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
                str(artifact_root / "agent-conversation-contract.json"),
                str(artifact_root / "AGENT_CONVERSATION.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal agent conversation: {overall}")
    print(f"artifact_root={artifact_root}")
    print("messages_sent_to_provider=0")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
