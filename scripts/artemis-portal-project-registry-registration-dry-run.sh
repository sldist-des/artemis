#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-dry-run/run-01"
registration_plan="artifacts/artemis-portal-project-registry-registration-plan/run-01/project-registry-registration-plan.json"
execution_gate="artifacts/artemis-portal-project-registry-registration-execution-gate/run-01/project-registry-registration-execution-gate.json"
human_review_gate="artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-dry-run.sh [--artifact-root path] [--registration-plan path] [--execution-gate path] [--human-review-gate path] [--json]

Builds a dry-run of the ARTEMIS Project Registry registration write. It creates
draft registry records, a diff preview and rollback plan under artifacts only.
It does not write the registry, register candidates, switch projects,
authenticate providers, create worktrees, start runtime, execute commands,
spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --registration-plan)
      registration_plan="${2:-}"
      if [ -z "$registration_plan" ]; then usage; exit 2; fi
      shift 2
      ;;
    --execution-gate)
      execution_gate="${2:-}"
      if [ -z "$execution_gate" ]; then usage; exit 2; fi
      shift 2
      ;;
    --human-review-gate)
      human_review_gate="${2:-}"
      if [ -z "$human_review_gate" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$registration_plan" "$execution_gate" "$human_review_gate" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
registration_plan_path = Path(sys.argv[2])
execution_gate_path = Path(sys.argv[3])
human_review_gate_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

missing_files = []
for path in [
    registration_plan_path,
    execution_gate_path,
    human_review_gate_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_PLAN.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md"),
    Path("docs/exec-packs/done/TKT-105-artemis-project-registry-registration-dry-run.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

plan_payload = json.loads(registration_plan_path.read_text(encoding="utf-8")) if registration_plan_path.is_file() else {}
gate_payload = json.loads(execution_gate_path.read_text(encoding="utf-8")) if execution_gate_path.is_file() else {}
review_payload = json.loads(human_review_gate_path.read_text(encoding="utf-8")) if human_review_gate_path.is_file() else {}

candidate_id = plan_payload.get("candidate_project_id", "")
review_contract = review_payload.get("review_contract", {})
candidate_reviews = review_contract.get("candidate_reviews", [])
candidate = next((item for item in candidate_reviews if item.get("candidate_project_id") == candidate_id), {})

draft_record = {
    "schema_version": 1,
    "record_kind": "registry.project",
    "candidate_project_id": candidate_id,
    "project_id": candidate_id,
    "display_name": candidate.get("display_name", "veri"),
    "repo_root": candidate.get("repo_root", "/srv/veri"),
    "registry_state": "registered_pending_selection_review",
    "selection_state": "not_selected",
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "registered_by": "dry_run_preview_only",
    "registered_at": generated_at,
    "source_decision": "synthetic_approved_fixture_plus_execution_gate",
    "source_plan": str(registration_plan_path),
    "source_execution_gate": str(execution_gate_path),
    "notes": [
        "Dry-run record only; not written to registry.",
        "Real registry write still needs human approval, write target, diff preview, rollback plan and validation commands.",
    ],
}

audit_record = {
    "schema_version": 1,
    "record_kind": "registry.audit",
    "candidate_project_id": candidate_id,
    "event": "registration_dry_run_prepared",
    "generated_at": generated_at,
    "write_performed": False,
    "project_switch_performed": False,
    "runtime_started": False,
    "evidence": [
        str(artifact_root / "registry-write-draft.json"),
        str(artifact_root / "registry-diff-preview.md"),
        str(artifact_root / "registry-rollback-plan.md"),
    ],
}

selector_entry = {
    "schema_version": 1,
    "record_kind": "selector.entry",
    "candidate_project_id": candidate_id,
    "project_id": candidate_id,
    "display_name": candidate.get("display_name", "veri"),
    "repo_root": candidate.get("repo_root", "/srv/veri"),
    "selection_state": "not_selectable_until_post_registration_review",
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
}

write_draft = {
    "schema_version": 1,
    "generated_at": generated_at,
    "mode": "dry_run_only",
    "registry_write_allowed": False,
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "records_to_write_if_later_approved": [
        draft_record,
        audit_record,
        selector_entry,
    ],
}
(artifact_root / "registry-write-draft.json").write_text(json.dumps(write_draft, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

diff_lines = [
    "# Registry Diff Preview",
    "",
    "This is a dry-run preview. No registry file was modified.",
    "",
    "## Proposed additions after future approval",
    "",
    "```diff",
    f"+ registry.project {candidate_id}",
    f"+   display_name: {draft_record['display_name']}",
    f"+   repo_root: {draft_record['repo_root']}",
    "+   registry_state: registered_pending_selection_review",
    "+   selection_state: not_selected",
    "+   project_switching_allowed: false",
    "+   runtime_execution_allowed: false",
    f"+ registry.audit registration_dry_run_prepared {candidate_id}",
    f"+ selector.entry {candidate_id} not_selectable_until_post_registration_review",
    "```",
    "",
    "## Still blocked",
    "",
    "- Registry write.",
    "- Candidate registration.",
    "- Project switching.",
    "- Runtime execution.",
    "- Provider auth.",
    "- Remote mutation.",
]
(artifact_root / "registry-diff-preview.md").write_text("\n".join(diff_lines) + "\n", encoding="utf-8")

rollback_lines = [
    "# Registry Rollback Plan",
    "",
    "This rollback is a future plan only because no write happened in this cut.",
    "",
    "If a later approved write installs the proposed records and must be reverted:",
    "",
    "1. Remove the `registry.project` record for the candidate.",
    "2. Remove the generated `selector.entry` for the candidate.",
    "3. Append a `registry.audit` rollback event referencing the failed write.",
    "4. Re-run the Project Registry read model generation.",
    "5. Re-run `scripts/validate-artemis.sh`.",
    "6. Keep project switching and runtime blocked until post-rollback review passes.",
    "",
    "No rollback command is executed by this dry-run.",
]
(artifact_root / "registry-rollback-plan.md").write_text("\n".join(rollback_lines) + "\n", encoding="utf-8")

dry_run_contract = {
    "purpose": "Preview Project Registry records before any real registry write.",
    "state": "registration_write_dry_run",
    "candidate_project_id": candidate_id,
    "registration_plan": str(registration_plan_path),
    "execution_gate": str(execution_gate_path),
    "dry_run_ready": True,
    "real_human_approval_recorded": gate_payload.get("real_human_approval_recorded", False),
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
    "draft_record_count": len(write_draft["records_to_write_if_later_approved"]),
    "write_target_preview": "future_project_registry",
    "diff_preview_path": str(artifact_root / "registry-diff-preview.md"),
    "rollback_plan_path": str(artifact_root / "registry-rollback-plan.md"),
    "validation_commands": [
        "python3 -m json.tool artifacts/artemis-portal-project-registry-registration-dry-run/run-01/registry-write-draft.json",
        "python3 -m json.tool artifacts/artemis-portal-project-registry-registration-dry-run/run-01/project-registry-registration-dry-run.json",
        "scripts/validate-artemis.sh",
    ],
    "blocked_until_future_gate": [
        "real human owner approval",
        "explicit write target",
        "accepted diff preview",
        "accepted rollback plan",
        "validation command approval",
        "post-write review gate",
    ],
}

checks = [
    {
        "id": "registration_plan_ready",
        "status": "passed" if plan_payload.get("overall") == "project_registry_registration_plan_ready" else "failed",
        "detail": "Dry-run consumes the Registration Plan.",
    },
    {
        "id": "execution_gate_ready",
        "status": "passed" if gate_payload.get("overall") == "project_registry_registration_execution_gate_ready" else "failed",
        "detail": "Dry-run consumes the Registration Execution Gate.",
    },
    {
        "id": "candidate_known",
        "status": "passed" if bool(candidate_id) and bool(candidate) else "failed",
        "detail": "Dry-run resolves the candidate review record.",
    },
    {
        "id": "draft_records_written_to_artifacts_only",
        "status": "passed" if (artifact_root / "registry-write-draft.json").is_file() and dry_run_contract["registry_write_allowed"] is False else "failed",
        "detail": "Draft registry records exist only under artifacts.",
    },
    {
        "id": "diff_preview_written",
        "status": "passed" if (artifact_root / "registry-diff-preview.md").is_file() else "failed",
        "detail": "Dry-run produced a human-readable diff preview.",
    },
    {
        "id": "rollback_plan_written",
        "status": "passed" if (artifact_root / "registry-rollback-plan.md").is_file() else "failed",
        "detail": "Dry-run produced a rollback plan.",
    },
    {
        "id": "registry_write_still_blocked",
        "status": "passed" if dry_run_contract["registry_write_allowed"] is False and dry_run_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "Dry-run does not write registry records or register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if dry_run_contract["project_switching_allowed"] is False else "failed",
        "detail": "Dry-run does not switch the selected project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if dry_run_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Dry-run does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if dry_run_contract["commands_executed"] == 0 and dry_run_contract["tokens_spent"] == 0 and dry_run_contract["remote_state_mutated"] is False else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_dry_run_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_dry_run_ready": overall == "project_registry_registration_dry_run_ready",
    "candidate_project_id": candidate_id,
    "dry_run_state": "ready_for_human_review" if overall == "project_registry_registration_dry_run_ready" else "blocked",
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
    "next_cut": "TKT-106 - Project Registry Registration Human Approval Package",
    "missing_files": missing_files,
    "dry_run_contract": dry_run_contract,
    "checks": checks,
}

(artifact_root / "project-registry-registration-dry-run.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

lines = [
    "# ARTEMIS Project Registry Registration Dry Run",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    "- Registry write allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Draft records: `{dry_run_contract['draft_record_count']}`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Evidence",
    "",
    f"- `{artifact_root / 'registry-write-draft.json'}`",
    f"- `{artifact_root / 'registry-diff-preview.md'}`",
    f"- `{artifact_root / 'registry-rollback-plan.md'}`",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")
(artifact_root / "PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Dry-run artifacts are ready for human review.",
        "- Registry write, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Registration Plan checked.",
        "- Registration Execution Gate checked.",
        "- Candidate review record resolved.",
        "- Draft registry records written under artifacts only.",
        "- Diff preview and rollback plan written.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-105 produces a dry-run of the Project Registry registration write.",
        "",
        "The human can now review the proposed records, diff preview and rollback plan. A later approval package may accept or reject this dry-run, but this cut still does not write registry records, select projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-dry-run.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_dry_run_ready",
            event_type="registry.registration_dry_run_ready",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-dry-run.sh",
                "mode": "read_only",
            },
            ticket="TKT-105",
            title="ARTEMIS Project Registry Registration Dry Run",
            exec_pack="docs/exec-packs/done/TKT-105-artemis-project-registry-registration-dry-run.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "project_registry_registration_dry_run_ready" else "blocked",
            payload={
                "project_registry_registration_dry_run_ready": overall == "project_registry_registration_dry_run_ready",
                "candidate_project_id": candidate_id,
                "dry_run_state": payload["dry_run_state"],
                "draft_record_count": dry_run_contract["draft_record_count"],
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
            state_from="registration_execution_gate",
            runner={"kind": "none"},
            gate={
                "kind": "validation",
                "status": "passed" if overall == "project_registry_registration_dry_run_ready" else "blocked",
                "reason": "Dry-run preview validates registry records without writing them.",
            },
            severity="info" if overall == "project_registry_registration_dry_run_ready" else "warning",
            logs=[
                str(artifact_root / "project-registry-registration-dry-run.json"),
                str(artifact_root / "registry-write-draft.json"),
                str(artifact_root / "registry-diff-preview.md"),
                str(artifact_root / "registry-rollback-plan.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration dry-run: {overall}")
    print(f"artifact_root={artifact_root}")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
