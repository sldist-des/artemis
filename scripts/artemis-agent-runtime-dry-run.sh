#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-agent-runtime-dry-run/run-01"
contract_path="artifacts/artemis-agent-launch-contract/run-01/agent-launch-contract.json"
tasks_path="control-plane/tasks.json"
project_brief="artifacts/artemis-project-brief/run-01/project-brief.json"
profile=""
task=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-agent-runtime-dry-run.sh [--artifact-root path] [--contract path] [--tasks path] [--project-brief path] [--profile id] [--task text] [--json]

Builds an audited dry-run request for a future ARTEMIS agent runtime launch.
It consumes the Agent Launch Contract, selects a runtime profile, records
preflight gates and writes runtime logs without starting Codex app-server,
Claude Code, paid agents, subagents, remote writes, dependencies or commands.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --contract)
      contract_path="${2:-}"
      if [ -z "$contract_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --tasks)
      tasks_path="${2:-}"
      if [ -z "$tasks_path" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-brief)
      project_brief="${2:-}"
      if [ -z "$project_brief" ]; then usage; exit 2; fi
      shift 2
      ;;
    --profile)
      profile="${2:-}"
      if [ -z "$profile" ]; then usage; exit 2; fi
      shift 2
      ;;
    --task)
      task="${2:-}"
      if [ -z "$task" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$contract_path" "$tasks_path" "$project_brief" "$profile" "$task" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
contract_path = Path(sys.argv[2])
tasks_path = Path(sys.argv[3])
brief_path = Path(sys.argv[4])
requested_profile = sys.argv[5]
requested_task = sys.argv[6]
output_format = sys.argv[7]
generated_at = now_utc()

contract = json.loads(contract_path.read_text(encoding="utf-8"))
tasks_payload = json.loads(tasks_path.read_text(encoding="utf-8"))
brief = json.loads(brief_path.read_text(encoding="utf-8"))

candidate = contract.get("candidate_launch", {})
profiles = {item.get("id"): item for item in contract.get("launch_profiles", [])}
profile_id = requested_profile or candidate.get("recommended_profile") or "codex_terminal"
selected_profile = profiles.get(profile_id)
task_text = requested_task or candidate.get("task") or "TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony"

required_gate_ids = {
    "project_gate",
    "task_gate",
    "auth_gate",
    "budget_gate",
    "command_gate",
    "workspace_gate",
    "validation_gate",
    "rollback_gate",
    "remote_write_gate",
}
present_gate_ids = {item.get("id") for item in contract.get("launch_gates", [])}
missing_gate_ids = sorted(required_gate_ids - present_gate_ids)

required_files = [
    contract_path,
    tasks_path,
    brief_path,
    Path("scripts/artemis-agent-runtime-dry-run.sh"),
    Path("docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DRY_RUN.md"),
    Path("docs/exec-packs/done/TKT-059-artemis-agent-runtime-dry-run.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

tasks = tasks_payload.get("tasks", [])
done_tasks = [item for item in tasks if item.get("state") == "done"]
summary_from_brief = brief.get("summary", {})

profile_runtime = selected_profile.get("runtime") if selected_profile else "unknown"
profile_command = selected_profile.get("command_surface") if selected_profile else "unknown"
auth_required = bool(selected_profile.get("auth_required")) if selected_profile else True

launch_request = {
    "project": "ARTEMIS",
    "task": task_text,
    "profile_id": profile_id,
    "profile_name": selected_profile.get("name") if selected_profile else "unknown",
    "runtime": profile_runtime,
    "command_surface": profile_command,
    "execute": False,
    "reason": "Dry-run materializes the launch request and preflight evidence without starting an agent runtime.",
    "model_policy": {
        "selection": "inherited_or_human_approved",
        "frontier_default": "gpt-5.4",
        "claude_default": "human_account_runtime",
        "override_allowed": False,
    },
    "budget": {
        "approval_state": "human_required_before_runtime",
        "max_agents": 1,
        "max_commands": 0,
        "max_paid_tokens": 0,
        "max_runtime_seconds": 0,
        "stop_rule": "Stop before any real runtime, paid token use, remote write, production touch, secret access or missing validation evidence.",
    },
    "auth": {
        "required": auth_required,
        "state": "human_required" if auth_required else "not_required_for_dry_run",
        "secrets_touched": False,
    },
    "workspace": {
        "repo": str(Path.cwd()),
        "write_scope": "none",
        "branch_policy": "observe_only",
        "worktree_policy": "not_materialized",
        "dirty_state_policy": "record_only",
    },
    "rollback": {
        "required_before_runtime": True,
        "dry_run_abort": "Delete or ignore this artifact root; no runtime side effects were created.",
        "runtime_abort": "Future runtime must preserve logs, stop agents and hand off unresolved gates before retry.",
    },
    "evidence": {
        "request": str(artifact_root / "REQUEST.md"),
        "preflight": str(artifact_root / "PREFLIGHT.md"),
        "runtime_log": str(artifact_root / "RUNTIME_LOG.md"),
        "handoff": str(artifact_root / "HANDOFF.md"),
        "json": str(artifact_root / "runtime-dry-run.json"),
    },
}

preflight_checks = [
    {
        "id": "contract_ready",
        "status": "passed" if contract.get("overall") == "agent_launch_contract_ready" else "failed",
        "proof": f"contract overall: {contract.get('overall')}",
    },
    {
        "id": "profile_selected",
        "status": "passed" if selected_profile else "failed",
        "proof": profile_id,
    },
    {
        "id": "required_gates_present",
        "status": "passed" if not missing_gate_ids else "failed",
        "proof": ", ".join(sorted(present_gate_ids)),
    },
    {
        "id": "execute_false",
        "status": "passed" if launch_request["execute"] is False else "failed",
        "proof": "execute=false",
    },
    {
        "id": "runtime_not_started",
        "status": "passed",
        "proof": "runtime_started=false",
    },
    {
        "id": "agents_not_started",
        "status": "passed",
        "proof": "agents_started=0",
    },
    {
        "id": "commands_not_executed",
        "status": "passed",
        "proof": "commands_executed=0",
    },
    {
        "id": "remote_writes_blocked",
        "status": "passed",
        "proof": "remote_writes_allowed=false",
    },
    {
        "id": "auth_gate",
        "status": "human_gate" if auth_required else "passed",
        "proof": launch_request["auth"]["state"],
    },
    {
        "id": "budget_gate",
        "status": "human_gate",
        "proof": "max_paid_tokens=0 until explicit budget approval",
    },
    {
        "id": "workspace_gate",
        "status": "passed",
        "proof": "write_scope=none and worktree_policy=not_materialized",
    },
    {
        "id": "rollback_gate",
        "status": "passed",
        "proof": "dry-run and future runtime abort rules recorded",
    },
    {
        "id": "validation_gate",
        "status": "passed",
        "proof": "future runtime must declare tests/checks/screenshots before Done",
    },
]

failed_checks = [item for item in preflight_checks if item["status"] == "failed"]
human_gates = [item for item in preflight_checks if item["status"] == "human_gate"]

summary = {
    "tasks_total": len(tasks),
    "tasks_done": len(done_tasks),
    "validation_passed": int(summary_from_brief.get("validation_passed", 0)),
    "validation_failed": int(summary_from_brief.get("validation_failed", 0)),
    "human_gates_from_project": int(summary_from_brief.get("human_gates", 0)),
    "preflight_checks": len(preflight_checks),
    "preflight_passed": sum(1 for item in preflight_checks if item["status"] == "passed"),
    "preflight_failed": len(failed_checks),
    "preflight_human_gate": len(human_gates),
    "execute": False,
    "runtime_started": False,
    "agents_started": 0,
    "commands_executed": 0,
    "dependencies_installed": 0,
    "remote_writes_allowed": False,
    "paid_tokens_authorized": 0,
    "auth_required": auth_required,
    "selected_profile": profile_id,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-agent-runtime-dry-run.sh",
    "mode": "agent_runtime_dry_run",
    "overall": "agent_runtime_dry_run_ready",
    "reason": "Runtime launch request was materialized as auditable dry-run without starting agents.",
    "artifact_root": str(artifact_root),
    "inputs": {
        "contract": str(contract_path),
        "tasks": str(tasks_path),
        "project_brief": str(brief_path),
    },
    "launch_request": launch_request,
    "preflight": preflight_checks,
    "summary": summary,
    "runtime_log": [
        "No Codex app-server process was started.",
        "No Claude Code process was started.",
        "No subagent, paid model session, queue bridge execution or daemon runtime was started.",
        "No command was executed by this dry-run.",
        "No dependency, secret, remote write, production resource, issue, PR or deploy was touched.",
    ],
    "invariants": [
        "Agent Runtime Dry-Run is a launch rehearsal, not a launcher.",
        "execute=false remains mandatory until an exact Human Gate approval artifact exists.",
        "Auth-backed, paid, remote, production and secret-touching work remain blocked.",
        "Future runtime must preserve logs, budget accounting, validation evidence and rollback path.",
        "Control Plane remains observational.",
    ],
    "missing_files": missing_files,
    "missing_gate_ids": missing_gate_ids,
    "next_cut": "TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony",
}

ready = (
    contract.get("overall") == "agent_launch_contract_ready"
    and selected_profile is not None
    and not missing_gate_ids
    and not missing_files
    and not failed_checks
    and summary["execute"] is False
    and summary["runtime_started"] is False
    and summary["agents_started"] == 0
    and summary["commands_executed"] == 0
    and summary["remote_writes_allowed"] is False
    and summary["paid_tokens_authorized"] == 0
)
if not ready:
    payload["overall"] = "failed"
    payload["reason"] = "Agent Runtime Dry-Run preflight is incomplete."

(artifact_root / "runtime-dry-run.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN STATUS",
    "",
    f"- Overall: `{payload['overall']}`",
    f"- Reason: {payload['reason']}",
    f"- Selected profile: `{profile_id}`",
    f"- Runtime: `{profile_runtime}`",
    f"- Execute: `{str(summary['execute']).lower()}`",
    f"- Runtime started: `{str(summary['runtime_started']).lower()}`",
    f"- Agents started: `{summary['agents_started']}`",
    f"- Commands executed: `{summary['commands_executed']}`",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`",
    f"- Paid tokens authorized: `{summary['paid_tokens_authorized']}`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN VALIDATION",
    "",
    f"- Contract ready: `{str(contract.get('overall') == 'agent_launch_contract_ready').lower()}`",
    f"- Profile selected: `{str(selected_profile is not None).lower()}`",
    f"- Required gates present: `{str(not missing_gate_ids).lower()}`",
    f"- Required files present: `{str(not missing_files).lower()}`",
    f"- Failed preflight checks: `{len(failed_checks)}`",
    f"- Human Gate checks: `{len(human_gates)}`",
    f"- Execute false: `{str(summary['execute'] is False).lower()}`",
    f"- Runtime started: `{str(summary['runtime_started']).lower()}`",
    f"- Agents started: `{summary['agents_started']}`",
    f"- Commands executed: `{summary['commands_executed']}`",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`",
    f"- Paid tokens authorized: `{summary['paid_tokens_authorized']}`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

request_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN REQUEST",
    "",
    f"- Project: `{launch_request['project']}`",
    f"- Task: `{launch_request['task']}`",
    f"- Profile: `{profile_id}`",
    f"- Runtime: `{profile_runtime}`",
    f"- Command surface: `{profile_command}`",
    f"- Execute: `{str(launch_request['execute']).lower()}`",
    f"- Model policy: `{launch_request['model_policy']['selection']}`",
    f"- Budget approval: `{launch_request['budget']['approval_state']}`",
    f"- Auth state: `{launch_request['auth']['state']}`",
    f"- Workspace write scope: `{launch_request['workspace']['write_scope']}`",
    "",
    "## Stop rule",
    "",
    launch_request["budget"]["stop_rule"],
]
(artifact_root / "REQUEST.md").write_text("\n".join(request_lines) + "\n", encoding="utf-8")

preflight_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN PREFLIGHT",
    "",
]
for item in preflight_checks:
    preflight_lines.append(f"- `{item['id']}`: `{item['status']}` - {item['proof']}")
(artifact_root / "PREFLIGHT.md").write_text("\n".join(preflight_lines) + "\n", encoding="utf-8")

runtime_log_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN LOG",
    "",
]
runtime_log_lines.extend(f"- {line}" for line in payload["runtime_log"])
(artifact_root / "RUNTIME_LOG.md").write_text("\n".join(runtime_log_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# ARTEMIS AGENT RUNTIME DRY-RUN HANDOFF",
    "",
    "O dry-run de runtime materializou pedido, budget zero, auth gate, workspace read-only, rollback e evidencia sem iniciar agente real.",
    "",
    "Proximo corte:",
    "",
    "- Implementar `TKT-065 - Agent Runtime Launcher Supervised Execution do ARTEMIS Symphony`.",
    "- Usar o Agent Runtime Launcher Preflight como entrada obrigatoria antes de materializar comandos.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

runtime_event = event(
    event_id="evt_tkt-059_agent_runtime_dry_run",
    event_type="runner.attempt_planned",
    generated_at=generated_at,
    producer={"adapter": "agent_runtime_dry_run", "name": "scripts/artemis-agent-runtime-dry-run.sh", "mode": "dry_run"},
    ticket="TKT-059",
    title="Agent Runtime Dry-Run do ARTEMIS Symphony",
    exec_pack="docs/exec-packs/done/TKT-059-artemis-agent-runtime-dry-run.md",
    artifact_root=str(artifact_root),
    state_from="planned",
    state_to="done" if ready else "blocked",
    severity="info" if ready else "error",
    payload={
        "overall": payload["overall"],
        "reason": payload["reason"],
        "summary": payload["summary"],
        "launch_request": payload["launch_request"],
        "next_cut": payload["next_cut"],
    },
    runner={
        "kind": profile_runtime,
        "attempt_id": "dry-run-only",
        "command": profile_command,
        "exit_code": 0 if ready else 1,
    },
    gate={
        "kind": "human" if human_gates else "none",
        "status": "human_gate" if human_gates else "not_applicable",
        "reason": "Auth and budget remain Human Gates before real runtime." if human_gates else "",
    },
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-agent-runtime-dry-run.sh", generated_at=generated_at, events=[runtime_event]),
)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Agent Runtime Dry-Run: {payload['overall']}")
    print(f"profile={profile_id} execute=false agents=0 commands=0 paid_tokens=0")

if not ready:
    raise SystemExit(1)
PY
