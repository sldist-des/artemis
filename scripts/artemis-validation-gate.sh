#!/usr/bin/env sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-validation-gate/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-validation-gate.sh [--artifact-root path] [--json]" >&2
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

mkdir -p "$artifact_root"
log_dir="$artifact_root/check-logs"
rm -rf "$log_dir" "$artifact_root/logs" "$artifact_root/runner-attempts"
mkdir -p "$log_dir"

results_file="$artifact_root/results.tsv"
: >"$results_file"
task_source_file="$artifact_root/task-source.json"
runner_source_file="$artifact_root/runner-task-source.json"
queue_bridge_validation_gate_file="$artifact_root/queue-bridge-validation-gate-fixture.json"
queue_bridge_decision_file="$artifact_root/queue-bridge-decision-fixture.json"
remote_source_github_file="$artifact_root/remote-source-github-fixture.json"
remote_promotion_decision_file="$artifact_root/remote-promotion-decision-fixture.json"

cat >"$runner_source_file" <<'JSON'
{
  "schema_version": 1,
  "source": "scripts/artemis-validation-gate.sh",
  "tasks": [
    {
      "id": "tkt-validate",
      "ticket": "TKT-VALIDATE",
      "title": "Validate supervised runner",
      "state": "ready",
      "owner": "Codex",
      "risk": "low",
      "summary": "Synthetic task used by validation to verify runner artifacts.",
      "exec_pack": "docs/exec-packs/active/TKT-VALIDATE.md",
      "evidence": "artifacts/validate-runner/run-01/STATUS.md",
      "tags": ["exec-pack", "validation"]
    }
  ]
}
JSON

cat >"$queue_bridge_validation_gate_file" <<'JSON'
{
  "schema_version": 1,
  "overall": "passed",
  "summary": {
    "passed": 1,
    "failed": 0,
    "human_gate": 0
  },
  "checks": [
    {
      "name": "synthetic",
      "kind": "technical",
      "status": "passed",
      "exit_code": 0,
      "log": "artifacts/artemis-validation-gate/run-01/check-logs/synthetic.txt"
    }
  ]
}
JSON

cat >"$queue_bridge_decision_file" <<JSON
{
  "schema_version": 1,
  "decision": "approved",
  "ticket": "TKT-VALIDATE",
  "queue_id": "queue-001-tkt-validate",
  "command": "scripts/artemis-dry-run.sh --input $runner_source_file",
  "validation_gate": "$queue_bridge_validation_gate_file",
  "validation_human_gates_acknowledged": true,
  "decided_by": "ARTEMIS synthetic validation",
  "reason": "Exact local dry-run command approved for queue execution validation."
}
JSON

cat >"$remote_source_github_file" <<'JSON'
{
  "schema_version": 1,
  "generated_at": "2026-05-07T00:00:00Z",
  "overall": "passed",
  "reason": "Synthetic GitHub Issues artifact for remote source validation.",
  "mode": "read_only",
  "repo": "sldist-des/artemis",
  "label": "artemis",
  "limit": 50,
  "checks": {
    "gh_installed": true,
    "gh_auth_exit_code": 0,
    "codeowners": "active",
    "issue_list_exit_code": 0
  },
  "contract": {
    "issue_defines": "intent",
    "exec_pack_defines": "contract",
    "control_plane_shows": "state",
    "remote_writes": "human_gate_only"
  },
  "issues": [
    {
      "number": 950,
      "title": "TKT-950 - Validate supervised source intake",
      "state": "OPEN",
      "url": "https://github.com/sldist-des/artemis/issues/950",
      "updatedAt": "2026-05-07T00:00:00Z",
      "assignees": [{"login": "Codex"}],
      "labels": [
        {"name": "artemis"},
        {"name": "artemis:ready"},
        {"name": "exec-pack:docs/exec-packs/done/TKT-050-artemis-symphony-remote-source.md"},
        {"name": "risk:low"}
      ]
    }
  ],
  "logs": {
    "auth": "",
    "issues": ""
  }
}
JSON

cat >"$remote_promotion_decision_file" <<JSON
{
  "schema_version": 1,
  "decision": "approved",
  "ticket": "TKT-950",
  "promote_to": "TKT-950",
  "title": "Validate supervised source intake",
  "owner": "Codex",
  "risk": "low",
  "exec_pack": "docs/exec-packs/done/TKT-009-local-task-source.md",
  "evidence": "$artifact_root/symphony-promotion-check/STATUS.md",
  "command": "scripts/artemis-dry-run.sh --input $artifact_root/symphony-promotion-check/promoted-source.json",
  "validation_gate": "$queue_bridge_validation_gate_file",
  "remote_review_acknowledged": true,
  "terminal_command_acknowledged": true,
  "validation_gate_required": true,
  "decided_by": "ARTEMIS synthetic validation",
  "reason": "Exact local promotion approved for validation."
}
JSON

run_check() {
  name="$1"
  kind="$2"
  command="$3"
  log="$log_dir/$name.txt"

  printf 'running %s...\n' "$name" >&2
  set +e
  sh -c "$command" >"$log" 2>&1
  code=$?
  set -e

  if [ "$kind" = "human_gate" ]; then
    status="human_gate"
  elif [ "$code" -eq 0 ]; then
    status="passed"
  else
    status="failed"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$status" "$code" "$log" >>"$results_file"
}

run_check shell_bootstrap technical "sh -n scripts/bootstrap-artemis.sh"
run_check shell_github_readiness technical "sh -n scripts/github-readiness.sh"
run_check shell_tasks technical "sh -n scripts/artemis-tasks.sh"
run_check shell_dry_run technical "sh -n scripts/artemis-dry-run.sh"
run_check shell_workspace technical "sh -n scripts/artemis-workspace.sh"
run_check shell_workspace_lifecycle technical "sh -n scripts/artemis-workspace-lifecycle.sh"
run_check shell_workspace_cleanup_review technical "sh -n scripts/artemis-workspace-cleanup-review.sh"
run_check shell_human_cleanup_approval_contract technical "sh -n scripts/artemis-human-cleanup-approval-contract.sh"
run_check shell_human_decision_fixtures technical "sh -n scripts/artemis-human-decision-fixtures.sh"
run_check shell_real_cleanup_decision_package technical "sh -n scripts/artemis-real-cleanup-decision-package.sh"
run_check shell_human_decision_runbook_consistency technical "sh -n scripts/artemis-human-decision-runbook-consistency.sh"
run_check shell_human_decision_release_checkpoint technical "sh -n scripts/artemis-human-decision-release-checkpoint.sh"
run_check shell_human_decision_intake technical "sh -n scripts/artemis-human-decision-intake.sh"
run_check shell_human_decision_pending_gate technical "sh -n scripts/artemis-human-decision-pending-gate.sh"
run_check shell_human_decision_reentry_contract technical "sh -n scripts/artemis-human-decision-reentry-contract.sh"
run_check shell_post_human_approval_preflight technical "sh -n scripts/artemis-post-human-approval-preflight.sh"
run_check shell_application_readiness technical "sh -n scripts/artemis-application-readiness.sh"
run_check shell_symphony_compatibility technical "sh -n scripts/artemis-symphony-compatibility.sh"
run_check shell_symphony_kernel technical "sh -n scripts/artemis-symphony-kernel.sh"
run_check shell_symphony_bridge technical "sh -n scripts/artemis-symphony-bridge.sh"
run_check shell_symphony_daemon technical "sh -n scripts/artemis-symphony-daemon.sh"
run_check shell_symphony_queue technical "sh -n scripts/artemis-symphony-queue.sh"
run_check shell_symphony_queue_bridge technical "sh -n scripts/artemis-symphony-queue-bridge.sh"
run_check shell_symphony_service technical "sh -n scripts/artemis-symphony-service.sh"
run_check shell_symphony_remote_source technical "sh -n scripts/artemis-symphony-remote-source.sh"
run_check shell_symphony_remote_intake technical "sh -n scripts/artemis-symphony-remote-intake.sh"
run_check shell_symphony_remote_promotion technical "sh -n scripts/artemis-symphony-remote-promotion.sh"
run_check shell_memory_zone technical "sh -n scripts/artemis-memory-zone.sh"
run_check shell_approved_workspace_cleanup technical "sh -n scripts/artemis-approved-workspace-cleanup.sh"
run_check shell_workspace_runtime_handoff technical "sh -n scripts/artemis-workspace-runtime-handoff.sh"
run_check shell_runner technical "sh -n scripts/artemis-runner.sh"
run_check shell_validation_gate technical "sh -n scripts/artemis-validation-gate.sh"
run_check shell_github_issues technical "sh -n scripts/artemis-github-issues.sh"
run_check shell_codex_app_server technical "sh -n scripts/artemis-codex-app-server.sh"
run_check shell_claude_code technical "sh -n scripts/artemis-claude-code.sh"
run_check shell_event_log technical "sh -n scripts/artemis-event-log.sh"
run_check task_source technical "scripts/artemis-tasks.sh --output '$task_source_file'"
run_check dry_run technical "scripts/artemis-dry-run.sh --input '$task_source_file' --json"
run_check workspace_check technical "scripts/artemis-workspace.sh --input '$runner_source_file' --ticket TKT-VALIDATE --artifact-root '$artifact_root/workspace-check' --json"
run_check workspace_lifecycle technical "scripts/artemis-workspace-lifecycle.sh --artifact-root '$artifact_root/workspace-lifecycle-check' --json"
run_check workspace_cleanup_review technical "scripts/artemis-workspace-cleanup-review.sh --artifact-root '$artifact_root/workspace-cleanup-review-check' --json"
run_check human_cleanup_approval_contract technical "scripts/artemis-human-cleanup-approval-contract.sh --decision '$artifact_root/workspace-cleanup-review-check/cleanup-review.json' --artifact-root '$artifact_root/human-cleanup-approval-contract-check' --json"
run_check human_decision_fixtures technical "scripts/artemis-human-decision-fixtures.sh --artifact-root '$artifact_root/human-decision-fixtures-check' --json"
run_check real_cleanup_decision_package technical "scripts/artemis-real-cleanup-decision-package.sh --source '$artifact_root/workspace-cleanup-review-check/cleanup-review.json' --artifact-root '$artifact_root/real-cleanup-decision-package-check' --json"
run_check human_decision_runbook_consistency technical "scripts/artemis-human-decision-runbook-consistency.sh --artifact-root '$artifact_root/human-decision-runbook-consistency-check' --json"
run_check human_decision_release_checkpoint technical "scripts/artemis-human-decision-release-checkpoint.sh --artifact-root '$artifact_root/human-decision-release-checkpoint-check' --json"
run_check human_decision_intake technical "scripts/artemis-human-decision-intake.sh --decision '$artifact_root/real-cleanup-decision-package-check/real-cleanup-decision.json' --checkpoint-root '$artifact_root/human-decision-release-checkpoint-check' --artifact-root '$artifact_root/human-decision-intake-check' --json"
run_check human_decision_pending_gate technical "scripts/artemis-human-decision-pending-gate.sh --intake-root '$artifact_root/human-decision-intake-check' --decision '$artifact_root/real-cleanup-decision-package-check/real-cleanup-decision.json' --artifact-root '$artifact_root/human-decision-pending-gate-check' --json"
run_check human_decision_reentry_contract technical "scripts/artemis-human-decision-reentry-contract.sh --pending-gate-root '$artifact_root/human-decision-pending-gate-check' --intake-root '$artifact_root/human-decision-intake-check' --decision '$artifact_root/real-cleanup-decision-package-check/real-cleanup-decision.json' --artifact-root '$artifact_root/human-decision-reentry-contract-check' --json"
run_check post_human_approval_preflight technical "scripts/artemis-post-human-approval-preflight.sh --reentry-root '$artifact_root/human-decision-reentry-contract-check' --intake-root '$artifact_root/human-decision-intake-check' --decision '$artifact_root/real-cleanup-decision-package-check/real-cleanup-decision.json' --artifact-root '$artifact_root/post-human-approval-preflight-check' --json"
run_check application_readiness technical "scripts/artemis-application-readiness.sh --artifact-root '$artifact_root/application-readiness-check' --json"
run_check symphony_compatibility technical "scripts/artemis-symphony-compatibility.sh --artifact-root '$artifact_root/symphony-compatibility-check' --json"
run_check symphony_kernel technical "scripts/artemis-symphony-kernel.sh --input '$runner_source_file' --artifact-root '$artifact_root/symphony-kernel-check' --max-concurrency 1 --json"
run_check symphony_bridge technical "scripts/artemis-symphony-bridge.sh --input '$runner_source_file' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/symphony-bridge-check' --max-concurrency 1 --json"
run_check symphony_daemon technical "scripts/artemis-symphony-daemon.sh --input '$runner_source_file' --artifact-root '$artifact_root/symphony-daemon-check' --ticks 2 --interval 0 --max-concurrency 1 --json"
run_check symphony_queue technical "scripts/artemis-symphony-queue.sh --daemon '$artifact_root/symphony-daemon-check/symphony-daemon.json' --artifact-root '$artifact_root/symphony-queue-check' --json"
run_check symphony_queue_bridge technical "scripts/artemis-symphony-queue-bridge.sh --queue '$artifact_root/symphony-queue-check/symphony-queue.json' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/symphony-queue-bridge-check' --json"
run_check symphony_queue_execution technical "scripts/artemis-symphony-queue-bridge.sh --queue '$artifact_root/symphony-queue-check/symphony-queue.json' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/symphony-queue-execution-check' --execute --validation-gate '$queue_bridge_validation_gate_file' --decision '$queue_bridge_decision_file' --json"
run_check symphony_service technical "scripts/artemis-symphony-service.sh --input '$runner_source_file' --artifact-root '$artifact_root/symphony-service-check' --ticks 1 --interval 0 --max-concurrency 1 --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --json"
run_check symphony_remote_source technical "scripts/artemis-symphony-remote-source.sh --github-artifact '$remote_source_github_file' --artifact-root '$artifact_root/symphony-remote-source-check' --json"
run_check symphony_remote_intake technical "scripts/artemis-symphony-remote-intake.sh --remote-source '$artifact_root/symphony-remote-source-check/remote-source.json' --artifact-root '$artifact_root/symphony-remote-intake-check' --json"
run_check symphony_remote_promotion technical "scripts/artemis-symphony-remote-promotion.sh --remote-intake '$artifact_root/symphony-remote-intake-check/remote-intake.json' --decision '$remote_promotion_decision_file' --artifact-root '$artifact_root/symphony-promotion-check' --json"
run_check memory_zone technical "scripts/artemis-memory-zone.sh --artifact-root '$artifact_root/memory-zone-check' --json"
run_check approved_workspace_cleanup technical "scripts/artemis-approved-workspace-cleanup.sh --decision '$artifact_root/workspace-cleanup-review-check/cleanup-review.json' --artifact-root '$artifact_root/approved-workspace-cleanup-check' --json"
run_check workspace_runtime_handoff technical "scripts/artemis-workspace-runtime-handoff.sh --lifecycle '$artifact_root/workspace-lifecycle-check/workspace-lifecycle.json' --cleanup '$artifact_root/approved-workspace-cleanup-check/approved-cleanup.json' --approval-contract '$artifact_root/human-cleanup-approval-contract-check/cleanup-approval-contract.json' --artifact-root '$artifact_root/workspace-runtime-handoff-check' --json"
run_check runner_plan technical "scripts/artemis-runner.sh --input '$runner_source_file' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/runner-attempts'"
run_check runner_events technical "events_file=\$(find '$artifact_root/runner-attempts/attempts' -name events.json -type f -print -quit); test -n \"\$events_file\" && grep -q '\"event_type\": \"runner.attempt_planned\"' \"\$events_file\" && grep -q '\"event_type\": \"runner.attempt_completed\"' \"\$events_file\""
run_check required_files technical "test -f ARTEMIS_WORKFLOW.md && test -f ARTEMIS_APPLY.md && test -f control-plane/tasks.json && test -f scripts/artemis-workspace.sh && test -f scripts/artemis-runner.sh && test -f scripts/artemis-application-readiness.sh && test -f scripts/artemis-symphony-kernel.sh && test -f scripts/artemis-symphony-bridge.sh && test -f scripts/artemis-symphony-daemon.sh && test -f scripts/artemis-symphony-queue.sh && test -f scripts/artemis-symphony-queue-bridge.sh && test -f scripts/artemis-symphony-service.sh && test -f scripts/artemis-symphony-remote-source.sh && test -f scripts/artemis-symphony-remote-intake.sh && test -f scripts/artemis-symphony-remote-promotion.sh && test -f scripts/artemis-memory-zone.sh && test -f docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md && test -f docs/symphony/ARTEMIS_SYMPHONY_SERVICE.md && test -f docs/symphony/ARTEMIS_SYMPHONY_REMOTE_SOURCE.md && test -f docs/symphony/ARTEMIS_SYMPHONY_REMOTE_INTAKE.md && test -f docs/symphony/ARTEMIS_SYMPHONY_REMOTE_PROMOTION.md && test -f docs/memory/ARTEMIS_MEMORY_ZONE.md"
run_check git_diff_check technical "git diff --check"
run_check codex_app_server technical "scripts/artemis-codex-app-server.sh --artifact-root '$artifact_root/codex-app-server-check' --json"
run_check claude_code technical "scripts/artemis-claude-code.sh --artifact-root '$artifact_root/claude-code-check' --json"
run_check event_log technical "scripts/artemis-event-log.sh --artifact-root '$artifact_root/event-log-check' --json"
run_check github_issues human_gate "scripts/artemis-github-issues.sh --artifact-root '$artifact_root/github-issues-check' --json"
run_check canonical_events technical "test -f '$artifact_root/codex-app-server-check/events.json' && test -f '$artifact_root/claude-code-check/events.json' && test -f '$artifact_root/github-issues-check/events.json'"
run_check github_auth human_gate "scripts/github-readiness.sh"

python3 - "$results_file" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from scripts.artemis_event_common import event, event_log, write_event_log

results_path = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

checks = []
for line in results_path.read_text(encoding="utf-8").splitlines():
    name, kind, status, code, log = line.split("\t")
    checks.append({
        "name": name,
        "kind": kind,
        "status": status,
        "exit_code": int(code),
        "log": log,
    })

technical_failed = [item for item in checks if item["kind"] == "technical" and item["status"] != "passed"]
human_gates = [item for item in checks if item["kind"] == "human_gate"]
summary = {
    "passed": sum(1 for item in checks if item["status"] == "passed"),
    "failed": len(technical_failed),
    "human_gate": len(human_gates),
}
overall = "failed" if technical_failed else ("human_gate" if human_gates else "passed")

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "summary": summary,
    "checks": checks,
}

(artifact_root / "validation-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# VALIDATION GATE RESULT",
    "",
    f"- Overall: {overall}",
    f"- Passed: {summary['passed']}",
    f"- Failed: {summary['failed']}",
    f"- Human Gate: {summary['human_gate']}",
    "",
    "## Checks",
    "",
]
for item in checks:
    lines.append(f"- {item['name']}: {item['status']} (exit {item['exit_code']}) -> `{item['log']}`")

(artifact_root / "VALIDATION_GATE.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

event_payload = {
    "overall": overall,
    "summary": summary,
    "checks": checks,
    "reason": "Validation Gate completed with structured technical and Human Gate results.",
}
events = [
    event(
        event_id="evt_validation_gate_current",
        event_type="validation.completed",
        generated_at=generated_at,
        producer={"adapter": "validation_gate", "name": "scripts/artemis-validation-gate.sh", "mode": "read_only"},
        ticket="TASK",
        title="ARTEMIS Validation Gate",
        exec_pack="ARTEMIS_WORKFLOW.md",
        artifact_root=str(artifact_root),
        state_from="validating",
        state_to="human_gate" if overall == "human_gate" else overall,
        runner={"kind": "none"},
        gate={"kind": "validation", "status": overall, "reason": "Validation Gate result."},
        severity="warning" if overall == "human_gate" else ("error" if overall == "failed" else "info"),
        logs=[item["log"] for item in checks],
        payload=event_payload,
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-validation-gate.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Validation Gate: {overall}")
    print(f"passed={summary['passed']} failed={summary['failed']} human_gate={summary['human_gate']}")
    print(f"artifact={artifact_root / 'validation-gate.json'}")

if technical_failed:
    raise SystemExit(1)
PY
