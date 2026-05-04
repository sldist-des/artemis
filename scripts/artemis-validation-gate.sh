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
run_check runner_plan technical "scripts/artemis-runner.sh --input '$runner_source_file' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/runner-attempts'"
run_check runner_events technical "events_file=\$(find '$artifact_root/runner-attempts/attempts' -name events.json -type f -print -quit); test -n \"\$events_file\" && grep -q '\"event_type\": \"runner.attempt_planned\"' \"\$events_file\" && grep -q '\"event_type\": \"runner.attempt_completed\"' \"\$events_file\""
run_check required_files technical "test -f ARTEMIS_WORKFLOW.md && test -f control-plane/tasks.json && test -f scripts/artemis-workspace.sh && test -f scripts/artemis-runner.sh"
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
