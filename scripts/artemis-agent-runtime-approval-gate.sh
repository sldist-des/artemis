#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-approval-gate/run-01"
dry_run_path="artifacts/artemis-agent-runtime-dry-run/run-01/runtime-dry-run.json"
decision_path=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-approval-gate.sh [--artifact-root path] [--dry-run path] [--decision path] [--json]

Builds a human-fillable approval gate from an ARTEMIS Agent Runtime Dry-Run.
It records the exact fields a person must approve, reject or defer before any
real Codex app-server, Claude Code, subagent, paid model, remote write, command
execution, dependency install, secret access, deploy or production touch.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --dry-run)
      dry_run_path="${2:-}"
      if [ -z "$dry_run_path" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$dry_run_path" "$decision_path" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
dry_run_path = Path(sys.argv[2])
provided_decision_path = sys.argv[3]
output_format = sys.argv[4]
generated_at = now_utc()

decision_path = Path(provided_decision_path) if provided_decision_path else artifact_root / "runtime-approval-decision.json"
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
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return True


dry_run = read_json(dry_run_path)
launch_request = dry_run.get("launch_request") or {}
summary = dry_run.get("summary") or {}
preflight = dry_run.get("preflight") or []

if dry_run.get("overall") != "agent_runtime_dry_run_ready":
    blockers.append("runtime dry-run is not ready")
if launch_request.get("execute") is not False:
    blockers.append("dry-run launch request does not keep execute=false")
if summary.get("runtime_started") is not False:
    blockers.append("dry-run reports runtime_started different from false")
if int(summary.get("agents_started", -1) or 0) != 0:
    blockers.append("dry-run reports started agents")
if int(summary.get("commands_executed", -1) or 0) != 0:
    blockers.append("dry-run reports executed commands")
if int(summary.get("paid_tokens_authorized", -1) or 0) != 0:
    blockers.append("dry-run reports paid tokens already authorized")
if summary.get("remote_writes_allowed") is not False:
    blockers.append("dry-run reports remote writes allowed")

approval_options = {
    "pending": "Decision is still open; no runtime can start.",
    "approved": "Requires exact approval metadata, budget, command, workspace, validation and rollback fields.",
    "deferred": "Requires metadata and reason; keeps runtime blocked for later review.",
    "rejected": "Requires metadata and reason; refuses this runtime request while preserving evidence.",
}

required_approval_fields = [
    "decision_record.decision",
    "decision_record.decided_by",
    "decision_record.decided_at",
    "decision_record.reason",
    "decision_record.approved_profile_id",
    "decision_record.approved_runtime",
    "decision_record.approved_command_surface",
    "decision_record.approved_model_policy",
    "decision_record.approved_budget",
    "decision_record.approved_auth",
    "decision_record.approved_workspace",
    "decision_record.approved_rollback",
    "decision_record.approved_validation",
    "decision_record.approved_commands",
]

human_gate_items = [
    {
        "id": "decision",
        "label": "Decision",
        "status": "pending",
        "required": True,
        "proof_required": "Human must choose approved, deferred or rejected with identity, timestamp and reason.",
    },
    {
        "id": "model_policy",
        "label": "Model policy",
        "status": "pending",
        "required": True,
        "proof_required": "Human must accept model selection or provide an explicit override policy.",
    },
    {
        "id": "budget",
        "label": "Budget",
        "status": "pending",
        "required": True,
        "proof_required": "Human must set max paid tokens, max agents, max commands, max runtime seconds and stop rule.",
    },
    {
        "id": "auth",
        "label": "Auth",
        "status": "pending",
        "required": bool((launch_request.get("auth") or {}).get("required")),
        "proof_required": "Human-owned account auth must be confirmed before account-backed runtime.",
    },
    {
        "id": "command",
        "label": "Command",
        "status": "pending",
        "required": True,
        "proof_required": "Human must record exact command(s); placeholders or partial commands cannot execute.",
    },
    {
        "id": "workspace",
        "label": "Workspace",
        "status": "pending",
        "required": True,
        "proof_required": "Human must approve repo, branch/worktree policy, dirty-state policy and write scope.",
    },
    {
        "id": "validation",
        "label": "Validation",
        "status": "pending",
        "required": True,
        "proof_required": "Human must define checks, tests, screenshots or artifacts required before Done.",
    },
    {
        "id": "rollback",
        "label": "Rollback",
        "status": "pending",
        "required": True,
        "proof_required": "Human must approve abort path, logs to preserve and retry/handoff rules.",
    },
    {
        "id": "remote_write",
        "label": "Remote write",
        "status": "blocked_by_default",
        "required": False,
        "proof_required": "Remote writes remain false unless a later, separate Human Gate authorizes them exactly.",
    },
]

decision_payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-approval-gate.sh",
    "mode": "human_fillable_pending",
    "based_on": str(dry_run_path),
    "approval_options": approval_options,
    "approval_request": {
        "project": launch_request.get("project", "ARTEMIS"),
        "task": launch_request.get("task", ""),
        "profile_id": launch_request.get("profile_id", ""),
        "profile_name": launch_request.get("profile_name", ""),
        "runtime": launch_request.get("runtime", ""),
        "command_surface": launch_request.get("command_surface", ""),
        "model_policy": launch_request.get("model_policy", {}),
        "budget": launch_request.get("budget", {}),
        "auth": launch_request.get("auth", {}),
        "workspace": launch_request.get("workspace", {}),
        "rollback": launch_request.get("rollback", {}),
        "evidence": launch_request.get("evidence", {}),
        "preflight": preflight,
    },
    "decision_record": {
        "decision": "pending",
        "decided_by": "",
        "decided_at": "",
        "reason": "",
        "approved_profile_id": "",
        "approved_runtime": "",
        "approved_command_surface": "",
        "approved_model_policy": {},
        "approved_budget": {
            "max_agents": 0,
            "max_commands": 0,
            "max_paid_tokens": 0,
            "max_runtime_seconds": 0,
            "stop_rule": "",
        },
        "approved_auth": {
            "auth_confirmed": False,
            "secrets_touched": False,
        },
        "approved_workspace": {
            "repo": "",
            "write_scope": "none",
            "branch_policy": "",
            "worktree_policy": "",
            "dirty_state_policy": "",
        },
        "approved_rollback": {
            "required_before_runtime": True,
            "abort_path": "",
            "preserve_logs": True,
        },
        "approved_validation": {
            "required_before_done": True,
            "checks": [],
            "evidence_artifacts": [],
        },
        "approved_commands": [],
    },
    "fillable_fields": required_approval_fields,
    "invariants": [
        "This file is a human-fillable approval package, not approval.",
        "Generated decisions start as pending.",
        "Agents must not approve runtime on behalf of humans.",
        "Approved runtime requires exact command, budget, workspace, rollback and validation fields.",
        "Remote writes, production, deploys and secrets remain blocked unless separately approved.",
    ],
}

if provided_decision_path and decision_path.is_file():
    decision_payload = read_json(decision_path)
else:
    decision_path.write_text(json.dumps(decision_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

record = decision_payload.get("decision_record") or {}
decision = str(record.get("decision") or "pending").strip()
approved_commands = list(record.get("approved_commands") or [])
decision_blockers = []

if decision not in approval_options:
    decision_blockers.append("decision must be one of: pending, approved, deferred, rejected")
if decision in {"approved", "deferred", "rejected"}:
    for field in ["decided_by", "decided_at", "reason"]:
        if not str(record.get(field) or "").strip():
            decision_blockers.append(f"{field} is required for {decision}")
    if not valid_timestamp(str(record.get("decided_at") or "")):
        decision_blockers.append("decided_at must be ISO-8601")
if decision == "approved":
    if not approved_commands:
        decision_blockers.append("approved runtime requires exact approved_commands")
    if not str(record.get("approved_profile_id") or ""):
        decision_blockers.append("approved_profile_id is required")
    if not str(record.get("approved_runtime") or ""):
        decision_blockers.append("approved_runtime is required")
    budget = record.get("approved_budget") or {}
    if int(budget.get("max_paid_tokens", 0) or 0) <= 0:
        decision_blockers.append("approved runtime requires a positive max_paid_tokens budget")
    if int(budget.get("max_runtime_seconds", 0) or 0) <= 0:
        decision_blockers.append("approved runtime requires a positive max_runtime_seconds limit")
elif approved_commands:
    decision_blockers.append("pending, deferred and rejected decisions must not include approved_commands")

runtime_execution_allowed = decision == "approved" and not blockers and not decision_blockers
decision_state = "approved_ready" if runtime_execution_allowed else decision
overall = "failed" if blockers or decision_blockers else "agent_runtime_approval_gate_ready"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-approval-gate.sh",
    "mode": "agent_runtime_approval_gate",
    "overall": overall,
    "reason": "Runtime approval gate is ready for a human decision before any real agent launch.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "dry_run": str(dry_run_path),
        "decision": str(decision_path),
    },
    "approval_contract": {
        "valid_decisions": list(approval_options),
        "metadata_required_for": ["approved", "deferred", "rejected"],
        "required_approval_fields": required_approval_fields,
        "approved_requires_exact_commands": True,
        "approved_requires_positive_budget": True,
        "partial_approval_executes": False,
        "non_approved_commands_allowed": False,
        "remote_writes_allowed_by_default": False,
    },
    "approval_request": decision_payload.get("approval_request", {}),
    "decision_file": str(decision_path),
    "decision_state": decision_state,
    "human_gate_items": human_gate_items,
    "summary": {
        "decision": decision,
        "pending": 1 if decision == "pending" else 0,
        "approved_ready": 1 if runtime_execution_allowed else 0,
        "deferred": 1 if decision == "deferred" and not decision_blockers else 0,
        "rejected": 1 if decision == "rejected" and not decision_blockers else 0,
        "invalid": 1 if decision_blockers else 0,
        "human_gate_items": len(human_gate_items),
        "runtime_execution_allowed": runtime_execution_allowed,
        "execute": False,
        "runtime_started": False,
        "agents_started": 0,
        "commands_executed": 0,
        "dependencies_installed": 0,
        "remote_writes_allowed": False,
        "paid_tokens_authorized": int((record.get("approved_budget") or {}).get("max_paid_tokens", 0) or 0) if runtime_execution_allowed else 0,
    },
    "blockers": blockers + decision_blockers,
    "invariants": [
        "Agent Runtime Approval Gate requests human approval; it does not launch runtime.",
        "Pending, deferred and rejected decisions keep runtime_execution_allowed=false.",
        "Approved runtime still requires a later launcher/preflight to execute exact commands.",
        "Agents must not fill or approve the human decision record.",
        "Control Plane remains observational.",
    ],
    "next_cut": "TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony",
}

(artifact_root / "runtime-approval-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME APPROVAL GATE STATUS",
    "",
    f"- Overall: `{overall}`",
    f"- Decision: `{decision}`",
    f"- Runtime execution allowed: `{str(runtime_execution_allowed).lower()}`",
    f"- Execute: `false`",
    f"- Runtime started: `false`",
    f"- Agents started: `0`",
    f"- Commands executed: `0`",
    f"- Paid tokens authorized: `{payload['summary']['paid_tokens_authorized']}`",
    f"- Remote writes allowed: `false`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT RUNTIME APPROVAL GATE VALIDATION",
    "",
    f"- Dry-run ready: `{str(dry_run.get('overall') == 'agent_runtime_dry_run_ready').lower()}`",
    f"- Decision file exists: `{str(decision_path.is_file()).lower()}`",
    f"- Decision state: `{decision_state}`",
    f"- Runtime execution allowed: `{str(runtime_execution_allowed).lower()}`",
    f"- Technical blockers: `{len(blockers)}`",
    f"- Decision blockers: `{len(decision_blockers)}`",
    "- Runtime started: `false`",
    "- Commands executed: `0`",
    "- Remote writes allowed: `false`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

request = decision_payload.get("approval_request", {})
approval_lines = [
    "# ARTEMIS AGENT RUNTIME APPROVAL REQUEST",
    "",
    f"- Project: `{request.get('project', '')}`",
    f"- Task: `{request.get('task', '')}`",
    f"- Profile: `{request.get('profile_id', '')}`",
    f"- Runtime: `{request.get('runtime', '')}`",
    f"- Command surface: `{request.get('command_surface', '')}`",
    "- Execute now: `false`",
    "- Runtime execution allowed now: `false`",
    "",
    "## Human Gate items",
    "",
]
for item in human_gate_items:
    approval_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof_required']}")
(artifact_root / "APPROVAL_REQUEST.md").write_text("\n".join(approval_lines) + "\n", encoding="utf-8")

template_lines = [
    "# ARTEMIS AGENT RUNTIME DECISION TEMPLATE",
    "",
    f"Edit `{decision_path}` only as the human decision record.",
    "",
    "Valid decisions:",
    "",
]
for key, description in approval_options.items():
    template_lines.append(f"- `{key}`: {description}")
template_lines.extend([
    "",
    "Rules:",
    "",
    "- Keep `approved_commands` empty unless decision is `approved`.",
    "- Use `deferred` for partial approval or uncertainty.",
    "- Runtime cannot execute from this gate directly.",
    "- A later intake/launcher must validate the filled decision before any command.",
])
(artifact_root / "DECISION_TEMPLATE.md").write_text("\n".join(template_lines) + "\n", encoding="utf-8")

checklist_lines = [
    "# ARTEMIS AGENT RUNTIME APPROVAL CHECKLIST",
    "",
    "Before changing `decision_record.decision` from `pending`:",
    "",
]
for field in required_approval_fields:
    checklist_lines.append(f"- Review `{field}`.")
checklist_lines.extend([
    "- Confirm exact command(s), budget, auth, workspace, rollback and validation evidence.",
    "- Confirm no remote write, secret, deploy or production action is bundled accidentally.",
    "- Run the validation gate after editing the decision.",
])
(artifact_root / "CHECKLIST.md").write_text("\n".join(checklist_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME APPROVAL GATE HANDOFF",
    "",
    "O gate de aprovacao de runtime esta pronto como decisao humana pendente.",
    "",
    "Proximo corte:",
    "",
    "- Implementar `TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony`.",
    "- Passar primeiro pelo Agent Runtime Decision Intake; o gate sozinho nao autoriza launcher.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

approval_event = event(
    event_id="evt_tkt-060_agent_runtime_approval_gate",
    event_type="approval.requested",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_approval_gate", "name": "scripts/artemis-agent-runtime-approval-gate.sh", "mode": "read_only"},
    ticket="TKT-060",
    title="Agent Runtime Approval Gate do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-060-artemis-agent-runtime-approval-gate.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="human_gate" if overall != "failed" else "failed",
    severity="warning" if overall != "failed" else "error",
    payload={
        "overall": overall,
        "reason": payload["reason"],
        "summary": payload["summary"],
        "decision_file": str(decision_path),
        "next_cut": payload["next_cut"],
    },
    gate={
        "kind": "human",
        "status": "human_gate" if overall != "failed" else "failed",
        "reason": "Human must approve, defer or reject runtime before any real launch.",
        "options": ["approved", "deferred", "rejected"],
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-approval-gate.sh", generated_at=generated_at, events=[approval_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Approval Gate: {overall}")
    print(f"decision={decision} runtime_execution_allowed={str(runtime_execution_allowed).lower()} commands=0 paid_tokens={payload['summary']['paid_tokens_authorized']}")

if overall == "failed":
    raise SystemExit(1)
PY
