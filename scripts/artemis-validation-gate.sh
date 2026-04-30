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
run_check shell_runner technical "sh -n scripts/artemis-runner.sh"
run_check shell_validation_gate technical "sh -n scripts/artemis-validation-gate.sh"
run_check task_source technical "scripts/artemis-tasks.sh --output '$task_source_file'"
run_check dry_run technical "scripts/artemis-dry-run.sh --input '$task_source_file' --json"
run_check runner_plan technical "scripts/artemis-runner.sh --input '$runner_source_file' --ticket TKT-VALIDATE --command 'scripts/artemis-dry-run.sh --input $runner_source_file' --artifact-root '$artifact_root/runner-attempts'"
run_check required_files technical "test -f ARTEMIS_WORKFLOW.md && test -f control-plane/tasks.json && test -f scripts/artemis-runner.sh"
run_check git_diff_check technical "git diff --check"
run_check github_auth human_gate "scripts/github-readiness.sh"

python3 - "$results_file" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

results_path = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
output_format = sys.argv[3]

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
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
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

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Validation Gate: {overall}")
    print(f"passed={summary['passed']} failed={summary['failed']} human_gate={summary['human_gate']}")
    print(f"artifact={artifact_root / 'validation-gate.json'}")

if technical_failed:
    raise SystemExit(1)
PY
