#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-decision-intake/run-01"
approval_gate_path="artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-gate.json"
decision_path="artifacts/artemis-agent-runtime-approval-gate/run-01/runtime-approval-decision.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-decision-intake.sh [--artifact-root path] [--approval-gate path] [--decision path] [--json]

Reads a human-owned ARTEMIS runtime approval decision and classifies it as
pending, approved_ready, deferred, rejected or invalid. This intake is read-only:
it never starts Codex, Claude Code, subagents, queues, daemons, commands, paid
tokens, remote writes, secrets, deploys or production changes.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --approval-gate)
      approval_gate_path="${2:-}"
      if [ -z "$approval_gate_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision)
      decision_path="${2:-}"
      if [ -z "$decision_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$approval_gate_path" "$decision_path" "$format" <<'PY'
import json
import re
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
approval_gate_path = Path(sys.argv[2])
decision_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()
blockers = []


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        blockers.append(f"missing JSON: {path}")
    except json.JSONDecodeError as exc:
        blockers.append(f"invalid JSON at {path}: {exc}")
    return {}


def valid_timestamp(value):
    if not value:
        return False
    try:
        datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


def nonempty_string(value):
    return isinstance(value, str) and bool(value.strip())


approval_gate = read_json(approval_gate_path)
decision_payload = read_json(decision_path)
approval_request = decision_payload.get("approval_request") or approval_gate.get("approval_request") or {}
record = decision_payload.get("decision_record") or {}
valid_decisions = set((approval_gate.get("approval_contract") or {}).get("valid_decisions") or ["pending", "approved", "deferred", "rejected"])

if approval_gate.get("overall") != "agent_runtime_approval_gate_ready":
    blockers.append("approval gate is not ready")
if (approval_gate.get("summary") or {}).get("runtime_started") is not False:
    blockers.append("approval gate reports runtime_started different from false")
if int((approval_gate.get("summary") or {}).get("commands_executed", -1) or 0) != 0:
    blockers.append("approval gate reports executed commands")
if (approval_gate.get("summary") or {}).get("remote_writes_allowed") is not False:
    blockers.append("approval gate reports remote writes allowed")

decision = str(record.get("decision") or "pending").strip()
decision_blockers = []
warnings = []
approved_commands = list(record.get("approved_commands") or [])
approved_budget = record.get("approved_budget") or {}
approved_workspace = record.get("approved_workspace") or {}
approved_auth = record.get("approved_auth") or {}
approved_rollback = record.get("approved_rollback") or {}
approved_validation = record.get("approved_validation") or {}

if decision not in valid_decisions:
    decision_blockers.append("decision must be one of: pending, approved, deferred, rejected")

if decision in {"approved", "deferred", "rejected"}:
    for field in ["decided_by", "decided_at", "reason"]:
        if not nonempty_string(record.get(field)):
            decision_blockers.append(f"{field} is required for {decision}")
    if not valid_timestamp(record.get("decided_at")):
        decision_blockers.append("decided_at must be ISO-8601")

if decision == "approved":
    if record.get("approved_profile_id") != approval_request.get("profile_id"):
        decision_blockers.append("approved_profile_id must match approval_request.profile_id")
    if record.get("approved_runtime") != approval_request.get("runtime"):
        decision_blockers.append("approved_runtime must match approval_request.runtime")
    if record.get("approved_command_surface") != approval_request.get("command_surface"):
        decision_blockers.append("approved_command_surface must match approval_request.command_surface")
    if not isinstance(record.get("approved_model_policy"), dict) or not record.get("approved_model_policy"):
        decision_blockers.append("approved_model_policy must be explicit")
    if int(approved_budget.get("max_agents", 0) or 0) <= 0:
        decision_blockers.append("approved_budget.max_agents must be positive")
    if int(approved_budget.get("max_commands", 0) or 0) <= 0:
        decision_blockers.append("approved_budget.max_commands must be positive")
    if int(approved_budget.get("max_paid_tokens", 0) or 0) <= 0:
        decision_blockers.append("approved_budget.max_paid_tokens must be positive")
    if int(approved_budget.get("max_runtime_seconds", 0) or 0) <= 0:
        decision_blockers.append("approved_budget.max_runtime_seconds must be positive")
    if not nonempty_string(approved_budget.get("stop_rule")):
        decision_blockers.append("approved_budget.stop_rule is required")
    if bool((approval_request.get("auth") or {}).get("required")) and approved_auth.get("auth_confirmed") is not True:
        decision_blockers.append("approved_auth.auth_confirmed is required for account-backed runtime")
    if approved_auth.get("secrets_touched") is not False:
        decision_blockers.append("approved_auth.secrets_touched must remain false before launcher preflight")
    if approved_workspace.get("repo") != (approval_request.get("workspace") or {}).get("repo"):
        decision_blockers.append("approved_workspace.repo must match approval_request.workspace.repo")
    if not nonempty_string(approved_workspace.get("write_scope")):
        decision_blockers.append("approved_workspace.write_scope is required")
    if not nonempty_string(approved_workspace.get("branch_policy")):
        decision_blockers.append("approved_workspace.branch_policy is required")
    if not nonempty_string(approved_workspace.get("worktree_policy")):
        decision_blockers.append("approved_workspace.worktree_policy is required")
    if not nonempty_string(approved_workspace.get("dirty_state_policy")):
        decision_blockers.append("approved_workspace.dirty_state_policy is required")
    if approved_rollback.get("required_before_runtime") is not True:
        decision_blockers.append("approved_rollback.required_before_runtime must be true")
    if not nonempty_string(approved_rollback.get("abort_path")):
        decision_blockers.append("approved_rollback.abort_path is required")
    if approved_rollback.get("preserve_logs") is not True:
        decision_blockers.append("approved_rollback.preserve_logs must be true")
    checks = list(approved_validation.get("checks") or [])
    evidence_artifacts = list(approved_validation.get("evidence_artifacts") or [])
    if approved_validation.get("required_before_done") is not True:
        decision_blockers.append("approved_validation.required_before_done must be true")
    if not checks and not evidence_artifacts:
        decision_blockers.append("approved_validation must include checks or evidence_artifacts")
    if not approved_commands:
        decision_blockers.append("approved_commands must include exact command(s)")
    if int(approved_budget.get("max_commands", 0) or 0) < len(approved_commands):
        decision_blockers.append("approved_budget.max_commands must cover approved_commands length")
    blocked_patterns = [
        r"\bgit\s+push\b",
        r"\bgh\s+(pr|issue|repo|api)\b",
        r"\bdeploy\b",
        r"\bkubectl\b",
        r"\bscp\b",
        r"\brsync\b",
        r"\bssh\s+",
    ]
    for command in approved_commands:
        if not nonempty_string(command):
            decision_blockers.append("approved_commands cannot contain empty commands")
            continue
        for pattern in blocked_patterns:
            if re.search(pattern, command):
                decision_blockers.append(f"approved command is blocked before separate remote/production gate: {command}")
                break
elif approved_commands:
    decision_blockers.append("pending, deferred and rejected decisions must not include approved_commands")

if decision == "pending":
    intake_state = "pending"
    next_action = "human_decision_required"
elif decision == "deferred" and not decision_blockers:
    intake_state = "deferred"
    next_action = "keep_runtime_request_open_for_later_review"
elif decision == "rejected" and not decision_blockers:
    intake_state = "rejected"
    next_action = "record_runtime_refusal_and_keep_evidence"
elif decision == "approved" and not decision_blockers and not blockers:
    intake_state = "approved_ready"
    next_action = "eligible_for_agent_runtime_launcher_preflight"
else:
    intake_state = "invalid"
    next_action = "fix_human_decision_record_before_launcher_preflight"

summary = {
    "decision": decision,
    "pending": 1 if intake_state == "pending" else 0,
    "approved_ready": 1 if intake_state == "approved_ready" else 0,
    "deferred": 1 if intake_state == "deferred" else 0,
    "rejected": 1 if intake_state == "rejected" else 0,
    "invalid": 1 if intake_state == "invalid" else 0,
    "runtime_execution_allowed": False,
    "launcher_preflight_allowed": intake_state == "approved_ready",
    "runtime_started": False,
    "agents_started": 0,
    "commands_executed": 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "paid_tokens_authorized": int(approved_budget.get("max_paid_tokens", 0) or 0) if intake_state == "approved_ready" else 0,
}

if blockers or intake_state == "invalid":
    overall = "failed"
elif intake_state == "approved_ready":
    overall = "ready_for_launcher_preflight"
elif intake_state == "pending":
    overall = "human_gate"
elif intake_state == "deferred":
    overall = "decision_deferred"
else:
    overall = "decision_rejected"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-decision-intake.sh",
    "mode": "read_only_agent_runtime_decision_intake",
    "overall": overall,
    "reason": "Runtime approval decision was classified without starting any agent runtime.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "approval_gate": str(approval_gate_path),
        "decision": str(decision_path),
    },
    "approval_request": approval_request,
    "decision_record": record,
    "intake_state": intake_state,
    "next_action": next_action,
    "summary": summary,
    "blockers": blockers + decision_blockers,
    "warnings": warnings,
    "invariants": [
        "Decision Intake is read-only and never starts runtime.",
        "Decision records remain human-owned.",
        "approved_ready means eligible for launcher preflight, not executed.",
        "pending, deferred, rejected and invalid states do not execute commands.",
        "Remote writes, secrets, deploys and production remain separate Human Gates.",
    ],
    "next_cut": "TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony",
}

(artifact_root / "runtime-decision-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME DECISION INTAKE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Intake state: `{intake_state}`",
    f"- Decision: `{decision}`",
    f"- Next action: `{next_action}`",
    f"- Launcher preflight allowed: `{str(summary['launcher_preflight_allowed']).lower()}`",
    f"- Runtime execution allowed by this intake: `false`",
    f"- Runtime started: `false`",
    f"- Agents started: `0`",
    f"- Commands executed: `0`",
    f"- Paid tokens authorized: `{summary['paid_tokens_authorized']}`",
    f"- Remote writes allowed: `false`",
    "",
    "## Blockers",
    "",
]
if payload["blockers"]:
    status_lines.extend(f"- {blocker}" for blocker in payload["blockers"])
else:
    status_lines.append("- Nenhum blocker tecnico local.")
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT RUNTIME DECISION INTAKE VALIDATION",
    "",
    f"- Approval gate ready: `{str(approval_gate.get('overall') == 'agent_runtime_approval_gate_ready').lower()}`",
    f"- Decision file exists: `{str(decision_path.is_file()).lower()}`",
    f"- Decision: `{decision}`",
    f"- Intake state: `{intake_state}`",
    f"- Launcher preflight allowed: `{str(summary['launcher_preflight_allowed']).lower()}`",
    f"- Runtime execution allowed by this intake: `false`",
    f"- Commands executed: `0`",
    f"- Remote writes allowed: `false`",
    f"- Blockers: `{len(payload['blockers'])}`",
    "",
    "## Gaps",
    "",
    "- Nenhum runtime real foi iniciado.",
    "- Nenhum comando aprovado foi executado.",
    "- Nenhum token pago, segredo, deploy, producao ou escrita remota foi usado.",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME DECISION INTAKE HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-061 classificou a decisao humana de runtime como `{intake_state}` com overall `{overall}`.",
    "",
    "## Interpretacao",
    "",
    "- `approved_ready`: pode seguir para launcher preflight, ainda sem executar agente.",
    "- `pending`: humano ainda precisa preencher a decisao.",
    "- `deferred`: pedido de runtime fica preservado para revisao futura.",
    "- `rejected`: runtime foi recusado e a evidencia fica registrada.",
    "- `invalid`: decisao precisa ser corrigida antes de qualquer preflight.",
    "",
    "## Proximo corte",
    "",
]
if intake_state == "approved_ready":
    handoff_lines.append("- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony` usando esta decisao aprovada.")
else:
    handoff_lines.append("- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony`, mantendo runtime bloqueado ate existir `approved_ready`.")
handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao iniciar Codex app-server, Claude Code, SDK, CLI, subagente, fila ou daemon neste intake.",
    "- Nao executar `approved_commands` neste intake.",
    "- Nao preencher decisao humana em nome do humano.",
    "- Nao fazer push, PR, deploy, producao ou tocar secrets.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

state_to = {
    "approved_ready": "ready",
    "pending": "human_gate",
    "deferred": "human_gate",
    "rejected": "handoff",
    "invalid": "blocked",
}[intake_state]
runtime_event = event(
    event_id="evt_tkt-061_agent_runtime_decision_intake",
    event_type="approval.intake_recorded",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_decision_intake", "name": "scripts/artemis-agent-runtime-decision-intake.sh", "mode": "read_only"},
    ticket="TKT-061",
    title="Agent Runtime Decision Intake do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-061-artemis-agent-runtime-decision-intake.md",
    artifact_root=str(artifact_root),
    state_from="human_gate",
    state_to=state_to,
    severity="error" if overall == "failed" else ("warning" if state_to == "human_gate" else "info"),
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": summary,
        "intake_state": intake_state,
        "next_action": next_action,
        "next_cut": payload["next_cut"],
    },
    gate={
        "kind": "human",
        "status": "human_gate" if state_to == "human_gate" else "not_applicable",
        "reason": "Runtime remains blocked unless decision intake reaches approved_ready.",
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-decision-intake.sh", generated_at=generated_at, events=[runtime_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Decision Intake: {overall}")
    print(
        "summary: "
        f"decision={decision} "
        f"intake_state={intake_state} "
        f"launcher_preflight_allowed={str(summary['launcher_preflight_allowed']).lower()} "
        "runtime_execution_allowed=false commands=0"
    )

if blockers or intake_state == "invalid":
    raise SystemExit(1)
PY
