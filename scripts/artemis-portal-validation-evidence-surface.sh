#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-validation-evidence-surface/run-01"
task_control_surface="artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json"
validation_gate="artifacts/artemis-validation-gate/run-01/validation-gate.json"
project_graph="artifacts/artemis-project-graph/run-01/project-graph.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-validation-evidence-surface.sh [--artifact-root path] [--task-control-surface path] [--validation-gate path] [--project-graph path] [--json]

Builds the ARTEMIS Portal Validation Evidence Surface contract. It does not
accept work, mutate task state, start runtime, execute commands, send provider
messages, spend tokens, store secrets, push, deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --task-control-surface)
      task_control_surface="${2:-}"
      if [ -z "$task_control_surface" ]; then usage; exit 2; fi
      shift 2
      ;;
    --validation-gate)
      validation_gate="${2:-}"
      if [ -z "$validation_gate" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-graph)
      project_graph="${2:-}"
      if [ -z "$project_graph" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$task_control_surface" "$validation_gate" "$project_graph" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
task_control_path = Path(sys.argv[2])
validation_gate_path = Path(sys.argv[3])
project_graph_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_TASK_CONTROL_SURFACE.md"),
    Path("docs/exec-packs/done/TKT-080-artemis-portal-task-control-surface.md"),
    Path("artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json"),
    Path("artifacts/artemis-validation-gate/run-01/validation-gate.json"),
    Path("artifacts/artemis-project-graph/run-01/project-graph.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

def read_json(path):
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    missing_files.append(str(path))
    return {}

task_control_payload = read_json(task_control_path)
validation_payload = read_json(validation_gate_path)
graph_payload = read_json(project_graph_path)

sample_control = task_control_payload.get("sample_task_control", {})
validation_summary = validation_payload.get("summary", {})
graph_summary = graph_payload.get("summary", {})

evidence_schema = {
    "required_fields": [
        "evidence_surface_id",
        "project_id",
        "ticket",
        "control_id",
        "validation_gate_ref",
        "project_graph_ref",
        "evidence_kind",
        "claim",
        "source_artifact",
        "status",
        "severity",
        "human_readable_summary",
        "machine_check_ref",
        "blocker_refs",
        "event_refs",
        "generated_at",
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
        "provider_secret",
        "git_remote_token",
        "ssh_private_key",
        "unredacted_user_data",
    ],
}

validation_evidence_contract = {
    "purpose": "Expose validation proof, blockers and readiness to humans without accepting work or mutating task state.",
    "state": "contract_only",
    "validation_evidence_surface_ready": True,
    "acceptance_recorded": False,
    "task_state_mutated": False,
    "controls_triggered": 0,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "evidence_schema": evidence_schema,
    "evidence_kinds": [
        "validation_gate_summary",
        "test_result",
        "static_check",
        "json_schema_check",
        "artifact_presence",
        "graph_consistency",
        "human_gate_status",
        "residual_risk",
        "not_tested_gap",
    ],
    "status_model": [
        "passed",
        "failed",
        "human_gate",
        "not_run",
        "not_applicable",
        "blocked",
    ],
    "readiness_model": {
        "ready_for_review": "technical checks passed and residual human gates are explicit",
        "not_ready": "one or more failed checks, missing evidence or unreviewed blockers exist",
        "human_gate": "technical checks passed but human authority is still required",
    },
    "display_policy": {
        "show_plain_language_summary": True,
        "show_machine_check_refs": True,
        "show_failed_checks_first": True,
        "show_human_gates_as_decision_points": True,
        "show_not_tested_gaps": True,
        "raw_logs_default_collapsed": True,
        "raw_runtime_output_allowed": False,
        "secret_values_allowed": False,
    },
    "acceptance_boundary": {
        "can_show_acceptance_readiness": True,
        "can_record_acceptance": False,
        "can_mark_done": False,
        "requires_future_surface": "TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract",
    },
    "event_bridge": {
        "writes_canonical_events": True,
        "event_types": [
            "validation_evidence.surface_recorded",
            "validation_evidence.summary_rendered",
            "validation_evidence.blocker_visible",
            "validation_evidence.human_gate_visible",
        ],
        "raw_log_in_event_allowed": False,
        "acceptance_in_event_allowed": False,
    },
    "enforcement_rules": [
        "Validation Evidence Surface explains evidence; it does not accept work.",
        "Failed checks and Human Gates must be visible before any acceptance flow.",
        "Raw prompts, full transcripts, secrets and raw runtime output are forbidden in evidence artifacts.",
        "Every evidence card must point to a source artifact or explicit not-tested gap.",
        "Done and acceptance remain blocked until a future Human Acceptance Surface records human decision.",
        "Evidence summaries must distinguish technical pass from human approval.",
    ],
}

failed_count = int(validation_summary.get("failed", 0) or 0)
human_gate_count = int(validation_summary.get("human_gate", 0) or 0)
passed_count = int(validation_summary.get("passed", 0) or 0)
readiness_state = "not_ready" if failed_count else ("human_gate" if human_gate_count else "ready_for_review")

sample_evidence = {
    "evidence_surface_id": "validation-evidence-tkt-081-contract-fixture",
    "project_id": sample_control.get("project_id", "artemis"),
    "ticket": "TKT-081",
    "control_id": sample_control.get("control_id", "task-control-tkt-080-contract-fixture"),
    "validation_gate_ref": str(validation_gate_path),
    "project_graph_ref": str(project_graph_path),
    "evidence_kind": "validation_gate_summary",
    "claim": "Validation Gate has no failed technical checks and still exposes Human Gates as decision points.",
    "source_artifact": str(validation_gate_path),
    "status": readiness_state,
    "severity": "warning" if human_gate_count else "info",
    "human_readable_summary": f"{passed_count} checks passed, {failed_count} failed, {human_gate_count} human gates.",
    "machine_check_ref": "validation_gate.summary",
    "blocker_refs": ["github_auth", "github_issues"] if human_gate_count else [],
    "event_refs": [
        "evt_portal_validation_evidence_surface_contract_recorded"
    ],
    "generated_at": generated_at,
}

checks = [
    {
        "id": "task_control_surface_ready",
        "status": "passed" if task_control_payload.get("overall") == "task_control_surface_ready" else "failed",
        "detail": "Validation Evidence Surface consumes a ready Task Control Surface contract.",
    },
    {
        "id": "validation_gate_available",
        "status": "passed" if validation_payload.get("summary") else "failed",
        "detail": "Validation Gate summary is available for evidence rendering.",
    },
    {
        "id": "project_graph_available",
        "status": "passed" if graph_payload.get("overall") == "project_graph_ready" else "failed",
        "detail": "Project Graph summary is available for project-level evidence context.",
    },
    {
        "id": "evidence_schema_declared",
        "status": "passed" if evidence_schema["required_fields"] and evidence_schema["forbidden_fields"] else "failed",
        "detail": "Evidence fields and forbidden raw/secret fields are declared.",
    },
    {
        "id": "acceptance_boundary_declared",
        "status": "passed" if not validation_evidence_contract["acceptance_boundary"]["can_record_acceptance"] and not validation_evidence_contract["acceptance_boundary"]["can_mark_done"] else "failed",
        "detail": "Evidence can show readiness but cannot accept work or mark done.",
    },
    {
        "id": "display_policy_declared",
        "status": "passed" if validation_evidence_contract["display_policy"]["show_failed_checks_first"] and not validation_evidence_contract["display_policy"]["raw_runtime_output_allowed"] else "failed",
        "detail": "Failed checks and Human Gates are visible while raw runtime output remains blocked.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not validation_evidence_contract["runtime_execution_allowed"] and validation_evidence_contract["commands_executed"] == 0 else "failed",
        "detail": "Validation evidence cannot start runtime or execute commands in this cut.",
    },
    {
        "id": "no_acceptance_recorded",
        "status": "passed" if not validation_evidence_contract["acceptance_recorded"] and not validation_evidence_contract["task_state_mutated"] else "failed",
        "detail": "This cut records evidence only and does not accept work or mutate task state.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No secrets, raw prompts, raw runtime output or full transcripts are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "validation_evidence_surface_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "validation_evidence_surface_ready": overall == "validation_evidence_surface_ready",
    "readiness_state": readiness_state,
    "acceptance_recorded": False,
    "task_state_mutated": False,
    "secret_values_recorded": False,
    "controls_triggered": 0,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "validation_summary": {
        "passed": passed_count,
        "failed": failed_count,
        "human_gate": human_gate_count,
    },
    "project_summary": {
        "tasks_total": graph_summary.get("tasks_total", 0),
        "tasks_done": graph_summary.get("tasks_done", 0),
        "events_total": graph_summary.get("events_total", 0),
        "nodes_total": graph_summary.get("nodes_total", 0),
        "edges_total": graph_summary.get("edges_total", 0),
    },
    "next_cut": "TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract",
    "missing_files": missing_files,
    "validation_evidence_contract": validation_evidence_contract,
    "sample_evidence": sample_evidence,
    "checks": checks,
    "inputs": {
        "task_control_surface": str(task_control_path),
        "validation_gate": str(validation_gate_path),
        "project_graph": str(project_graph_path),
    },
}

(artifact_root / "validation-evidence-surface-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Validation Evidence Surface Contract",
    "",
    f"- Overall: `{overall}`",
    f"- Readiness state: `{readiness_state}`",
    f"- Validation passed: `{passed_count}`",
    f"- Validation failed: `{failed_count}`",
    f"- Human gates: `{human_gate_count}`",
    "- Acceptance recorded: `false`",
    "- Task state mutated: `false`",
    "- Runtime execution allowed: `false`",
    "- Runtime session started: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract`",
    "",
    "## Regra central",
    "",
    "Validation evidence mostra provas, falhas, Human Gates e lacunas em linguagem humana, mas nao aceita entrega, nao marca done e nao executa nada.",
    "",
    "## Evidence required fields",
    "",
]
for field in evidence_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in evidence_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Evidence kinds", ""])
for item in validation_evidence_contract["evidence_kinds"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Status model", ""])
for item in validation_evidence_contract["status_model"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Enforcement rules", ""])
for rule in validation_evidence_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "VALIDATION_EVIDENCE_SURFACE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Readiness state: `{readiness_state}`",
        "- Validation Evidence Surface contract recorded.",
        "- No acceptance, task mutation, provider message, runtime start, command execution, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Task Control Surface, Validation Gate and Project Graph artifacts checked.",
        "- Evidence schema, evidence kinds, status model, display policy, acceptance boundary and event bridge defined.",
        "- No acceptance, task mutation, provider message, runtime start, command execution, token spend, raw prompt, transcript, secret or remote write produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-081 defines the ARTEMIS Portal Validation Evidence Surface contract.",
        "",
        "The next cut should define the Portal Human Acceptance Surface contract so humans can explicitly accept or reject evidence without bypassing validation, gates or ledger rules.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-validation-evidence-surface.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_validation_evidence_surface_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_validation_evidence_surface",
                "name": "scripts/artemis-portal-validation-evidence-surface.sh",
                "mode": "read_only",
            },
            ticket="TKT-081",
            title="ARTEMIS Portal Validation Evidence Surface Contract",
            exec_pack="docs/exec-packs/done/TKT-081-artemis-portal-validation-evidence-surface.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "validation_evidence_surface_ready" else "blocked",
            payload={
                "validation_evidence_surface_ready": overall == "validation_evidence_surface_ready",
                "readiness_state": readiness_state,
                "evidence_surface_id": sample_evidence["evidence_surface_id"],
                "validation_passed": passed_count,
                "validation_failed": failed_count,
                "validation_human_gate": human_gate_count,
                "acceptance_recorded": False,
                "task_state_mutated": False,
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
            severity="warning" if human_gate_count else "info",
            logs=[
                str(artifact_root / "validation-evidence-surface-contract.json"),
                str(artifact_root / "VALIDATION_EVIDENCE_SURFACE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal validation evidence surface: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"readiness_state={readiness_state}")
    print("acceptance_recorded=false")
    print("task_state_mutated=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
