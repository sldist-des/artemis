#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-approval-package/run-01"
registration_dry_run="artifacts/artemis-portal-project-registry-registration-dry-run/run-01/project-registry-registration-dry-run.json"
registry_write_draft="artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-write-draft.json"
diff_preview="artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-diff-preview.md"
rollback_plan="artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-rollback-plan.md"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-approval-package.sh [--artifact-root path] [--registration-dry-run path] [--registry-write-draft path] [--diff-preview path] [--rollback-plan path] [--json]

Builds the ARTEMIS Project Registry Registration Human Approval Package. It
packages the dry-run evidence and a fillable human decision template. It does
not record approval, write the registry, register candidates, switch projects,
authenticate providers, start runtime, execute commands, spend tokens or mutate
remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --registration-dry-run)
      registration_dry_run="${2:-}"
      if [ -z "$registration_dry_run" ]; then usage; exit 2; fi
      shift 2
      ;;
    --registry-write-draft)
      registry_write_draft="${2:-}"
      if [ -z "$registry_write_draft" ]; then usage; exit 2; fi
      shift 2
      ;;
    --diff-preview)
      diff_preview="${2:-}"
      if [ -z "$diff_preview" ]; then usage; exit 2; fi
      shift 2
      ;;
    --rollback-plan)
      rollback_plan="${2:-}"
      if [ -z "$rollback_plan" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$registration_dry_run" "$registry_write_draft" "$diff_preview" "$rollback_plan" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
dry_run_path = Path(sys.argv[2])
draft_path = Path(sys.argv[3])
diff_path = Path(sys.argv[4])
rollback_path = Path(sys.argv[5])
output_format = sys.argv[6]
generated_at = now_utc()

missing_files = []
for path in [
    dry_run_path,
    draft_path,
    diff_path,
    rollback_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md"),
    Path("docs/exec-packs/done/TKT-106-artemis-project-registry-registration-approval-package.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

dry_run_payload = json.loads(dry_run_path.read_text(encoding="utf-8")) if dry_run_path.is_file() else {}
draft_payload = json.loads(draft_path.read_text(encoding="utf-8")) if draft_path.is_file() else {}

candidate_id = dry_run_payload.get("candidate_project_id", "")
records = draft_payload.get("records_to_write_if_later_approved", [])
validation_commands = dry_run_payload.get("dry_run_contract", {}).get("validation_commands", [])

decision_template = {
    "schema_version": 1,
    "candidate_project_id": candidate_id,
    "decision": "pending",
    "decided_by": "",
    "decided_at": "",
    "approval_scope": "project_registry_registration_write",
    "accepted_write_target": "future_project_registry",
    "accepted_registry_write_draft": str(draft_path),
    "accepted_diff_preview": str(diff_path),
    "accepted_rollback_plan": str(rollback_path),
    "accepted_validation_commands": validation_commands,
    "rationale": "",
    "decision_options": ["approved", "rejected", "deferred"],
    "acknowledged_constraints": [
        "approval_allows_future_write_gate_only",
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
        "post_write_review_required_before_project_selection",
    ],
}
(artifact_root / "project-registry-registration-human-decision-template.json").write_text(
    json.dumps(decision_template, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

approval_package = {
    "purpose": "Ask a human to accept, reject or defer the Project Registry registration dry-run.",
    "state": "registration_approval_package",
    "approval_state": "waiting_for_human_approval",
    "candidate_project_id": candidate_id,
    "dry_run": str(dry_run_path),
    "registry_write_draft": str(draft_path),
    "diff_preview": str(diff_path),
    "rollback_plan": str(rollback_path),
    "draft_record_count": len(records),
    "decision_template": str(artifact_root / "project-registry-registration-human-decision-template.json"),
    "required_human_fields": [
        "candidate_project_id",
        "decision",
        "decided_by",
        "decided_at",
        "approval_scope",
        "accepted_write_target",
        "accepted_registry_write_draft",
        "accepted_diff_preview",
        "accepted_rollback_plan",
        "accepted_validation_commands",
        "rationale",
    ],
    "decision_options": ["approved", "rejected", "deferred"],
    "human_decision_recorded": False,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_gate_requirements": [
        "decision template filled by real human",
        "decision is approved, rejected or deferred",
        "timestamp is valid",
        "accepted paths match this package",
        "accepted validation commands are present",
        "post-approval intake validates the package before any write",
    ],
}

checks = [
    {
        "id": "dry_run_ready",
        "status": "passed" if dry_run_payload.get("overall") == "project_registry_registration_dry_run_ready" else "failed",
        "detail": "Approval package consumes the registration dry-run.",
    },
    {
        "id": "draft_records_available",
        "status": "passed" if len(records) >= 3 else "failed",
        "detail": "Registry write draft contains the proposed records.",
    },
    {
        "id": "diff_preview_available",
        "status": "passed" if diff_path.is_file() and "No registry file was modified" in diff_path.read_text(encoding="utf-8") else "failed",
        "detail": "Diff preview is present and explicitly non-writing.",
    },
    {
        "id": "rollback_plan_available",
        "status": "passed" if rollback_path.is_file() and "No rollback command is executed" in rollback_path.read_text(encoding="utf-8") else "failed",
        "detail": "Rollback plan is present and explicitly non-executing.",
    },
    {
        "id": "decision_template_written",
        "status": "passed" if (artifact_root / "project-registry-registration-human-decision-template.json").is_file() else "failed",
        "detail": "A fillable human decision template is available.",
    },
    {
        "id": "approval_not_recorded",
        "status": "passed" if approval_package["human_decision_recorded"] is False else "failed",
        "detail": "Package does not synthesize human approval.",
    },
    {
        "id": "registry_write_still_blocked",
        "status": "passed" if approval_package["registry_write_allowed"] is False and approval_package["candidate_registration_allowed"] is False else "failed",
        "detail": "Package does not write registry records or register the candidate.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if approval_package["runtime_execution_allowed"] is False else "failed",
        "detail": "Package does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if approval_package["commands_executed"] == 0 and approval_package["tokens_spent"] == 0 and approval_package["remote_state_mutated"] is False else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_approval_package_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_approval_package_ready": overall == "project_registry_registration_approval_package_ready",
    "candidate_project_id": candidate_id,
    "approval_state": approval_package["approval_state"],
    "human_decision_recorded": False,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "worktree_created": False,
    "branch_changed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-107 - Project Registry Registration Approval Intake",
    "missing_files": missing_files,
    "approval_package": approval_package,
    "checks": checks,
}

(artifact_root / "project-registry-registration-approval-package.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Approval Package",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    "- Approval state: `waiting_for_human_approval`",
    "- Human decision recorded: `false`",
    "- Registry write allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Draft records: `{len(records)}`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Human decision file",
    "",
    f"- `{artifact_root / 'project-registry-registration-human-decision-template.json'}`",
    "",
    "## Evidence to review",
    "",
    f"- `{draft_path}`",
    f"- `{diff_path}`",
    f"- `{rollback_path}`",
    "",
    "## Decision options",
    "",
    "- `approved`: allow a later intake to prepare the real write gate.",
    "- `rejected`: keep the candidate unregistered.",
    "- `deferred`: keep the package waiting.",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")
(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Approval package is ready for human review.",
        "- No approval is recorded by this cut.",
        "- Registry write, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Registration dry-run checked.",
        "- Registry write draft checked.",
        "- Diff preview checked.",
        "- Rollback plan checked.",
        "- Human decision template written.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-106 packages the Project Registry registration dry-run for human approval.",
        "",
        "A human can fill the decision template in a future cut. This package does not approve, write registry records, select projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-approval-package.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_approval_package_ready",
            event_type="human_gate.registration_approval_package_ready",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-approval-package.sh",
                "mode": "read_only",
            },
            ticket="TKT-106",
            title="ARTEMIS Project Registry Registration Human Approval Package",
            exec_pack="docs/exec-packs/done/TKT-106-artemis-project-registry-registration-approval-package.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_registration_approval_package_ready" else "blocked",
            payload={
                "project_registry_registration_approval_package_ready": overall == "project_registry_registration_approval_package_ready",
                "candidate_project_id": candidate_id,
                "approval_state": approval_package["approval_state"],
                "human_decision_recorded": False,
                "registration_execution_allowed": False,
                "candidate_registration_allowed": False,
                "registry_write_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="registration_dry_run",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": "waiting_for_human_approval" if overall == "project_registry_registration_approval_package_ready" else "blocked",
                "reason": "Registry write requires a real human decision package before approval intake.",
                "options": ["approved", "rejected", "deferred"],
            },
            severity="warning",
            logs=[
                str(artifact_root / "project-registry-registration-approval-package.json"),
                str(artifact_root / "project-registry-registration-human-decision-template.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration approval package: {overall}")
    print(f"artifact_root={artifact_root}")
    print("human_decision_recorded=false")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
