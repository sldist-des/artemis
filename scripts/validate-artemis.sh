#!/usr/bin/env sh
set -eu

required_files="
AGENTS.md
CLAUDE.md
ARCHITECTURE.md
AI_PROCESS.md
README.md
ARTEMIS_QUICKSTART.md
ARTEMIS_WORKFLOW.md
ARTEMIS_APPLY.md
.impeccable.md
docs/symphony/ARTEMIS_SYMPHONY_SPEC.md
docs/symphony/ARTEMIS_SYMPHONY_KERNEL.md
docs/symphony/ARTEMIS_SYMPHONY_BRIDGE.md
docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md
docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md
docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md
docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md
docs/symphony/ARTEMIS_SYMPHONY_SERVICE.md
docs/symphony/ARTEMIS_SYMPHONY_REMOTE_SOURCE.md
docs/symphony/ARTEMIS_SYMPHONY_REMOTE_INTAKE.md
docs/symphony/ARTEMIS_SYMPHONY_REMOTE_PROMOTION.md
docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md
docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH_VIEW.md
docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md
docs/symphony/ARTEMIS_SYMPHONY_GUIDED_COLLABORATION.md
docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md
docs/memory/ARTEMIS_MEMORY_ZONE.md
docs/invariants/core.md
docs/agents/AGENT_REGISTRY.md
docs/agents/CAPABILITY_REGISTRY.md
docs/agents/TOOL_POLICY.md
docs/agents/HANDOFF_PROTOCOL.md
docs/control-plane/artemis-control-plane.md
docs/principles/artemis-principles.md
docs/runbooks/github-setup.md
docs/schemas/artemis-event.schema.json
docs/schemas/artemis-event-log.schema.json
docs/workspaces/artemis-workspace-cleanup-review.md
control-plane/index.html
control-plane/tasks.json
templates/AGENTS.md
templates/CLAUDE.md
templates/AI_PROCESS.md
templates/docs/exec-packs/TEMPLATE.md
prompts/context-curator.md
prompts/implementer.md
prompts/reviewer.md
scripts/bootstrap-artemis.sh
scripts/github-readiness.sh
scripts/artemis-tasks.sh
scripts/artemis-dry-run.sh
scripts/artemis-workspace.sh
scripts/artemis-workspace-lifecycle.sh
scripts/artemis-workspace-cleanup-review.sh
scripts/artemis-human-cleanup-approval-contract.sh
scripts/artemis-human-decision-fixtures.sh
scripts/artemis-real-cleanup-decision-package.sh
scripts/artemis-human-decision-runbook-consistency.sh
scripts/artemis-human-decision-release-checkpoint.sh
scripts/artemis-human-decision-intake.sh
scripts/artemis-human-decision-pending-gate.sh
scripts/artemis-human-decision-reentry-contract.sh
scripts/artemis-post-human-approval-preflight.sh
scripts/artemis-application-readiness.sh
scripts/artemis-symphony-compatibility.sh
scripts/artemis-symphony-kernel.sh
scripts/artemis-symphony-bridge.sh
scripts/artemis-symphony-daemon.sh
scripts/artemis-symphony-queue.sh
scripts/artemis-symphony-queue-bridge.sh
scripts/artemis-symphony-service.sh
scripts/artemis-symphony-remote-source.sh
scripts/artemis-symphony-remote-intake.sh
scripts/artemis-symphony-remote-promotion.sh
scripts/artemis-memory-zone.sh
scripts/artemis-project-graph.sh
scripts/artemis-project-graph-view.sh
scripts/artemis-project-brief.sh
scripts/artemis-guided-collaboration.sh
scripts/artemis-agent-launch-contract.sh
scripts/artemis-agent-runtime-dry-run.sh
scripts/artemis-agent-runtime-approval-gate.sh
scripts/artemis-agent-runtime-decision-intake.sh
scripts/artemis-agent-runtime-launcher-preflight.sh
scripts/artemis-approved-workspace-cleanup.sh
scripts/artemis-workspace-runtime-handoff.sh
scripts/artemis-runner.sh
scripts/artemis-validation-gate.sh
scripts/artemis-github-issues.sh
scripts/artemis-codex-app-server.sh
scripts/artemis-claude-code.sh
scripts/artemis-event-log.sh
scripts/artemis_event_common.py
scripts/artemis_workspace_common.py
"

for file in $required_files; do
  if [ ! -f "$file" ]; then
    echo "missing required file: $file" >&2
    exit 1
  fi
done

required_dirs="
docs/exec-packs/active
docs/exec-packs/backlog
docs/exec-packs/done
artifacts
.github/ISSUE_TEMPLATE
.github/workflows
"

for dir in $required_dirs; do
  if [ ! -d "$dir" ]; then
    echo "missing required directory: $dir" >&2
    exit 1
  fi
done

deprecated_exec_path="docs/exec-"plans

if grep -R "$deprecated_exec_path" . \
  --exclude-dir=.git \
  --exclude-dir=.omx \
  --exclude-dir=artifacts >/tmp/artemis-exec-plans.matches 2>/dev/null; then
  echo "found deprecated exec plans path reference:" >&2
  cat /tmp/artemis-exec-plans.matches >&2
  exit 1
fi

placeholder_owner="@""owner"

if grep -R "$placeholder_owner" . \
  --exclude-dir=.git \
  --exclude-dir=.omx \
  --exclude-dir=templates \
  --exclude-dir=artifacts >/tmp/artemis-owner.matches 2>/dev/null; then
  echo "found active owner placeholder outside templates/artifacts:" >&2
  cat /tmp/artemis-owner.matches >&2
  exit 1
fi

sh -n scripts/bootstrap-artemis.sh
sh -n scripts/github-readiness.sh
sh -n scripts/artemis-tasks.sh
sh -n scripts/artemis-dry-run.sh
sh -n scripts/artemis-workspace.sh
sh -n scripts/artemis-workspace-lifecycle.sh
sh -n scripts/artemis-workspace-cleanup-review.sh
sh -n scripts/artemis-human-cleanup-approval-contract.sh
sh -n scripts/artemis-human-decision-fixtures.sh
sh -n scripts/artemis-real-cleanup-decision-package.sh
sh -n scripts/artemis-human-decision-runbook-consistency.sh
sh -n scripts/artemis-human-decision-release-checkpoint.sh
sh -n scripts/artemis-human-decision-intake.sh
sh -n scripts/artemis-human-decision-pending-gate.sh
sh -n scripts/artemis-human-decision-reentry-contract.sh
sh -n scripts/artemis-post-human-approval-preflight.sh
sh -n scripts/artemis-application-readiness.sh
sh -n scripts/artemis-symphony-compatibility.sh
sh -n scripts/artemis-symphony-kernel.sh
sh -n scripts/artemis-symphony-bridge.sh
sh -n scripts/artemis-symphony-daemon.sh
sh -n scripts/artemis-symphony-queue.sh
sh -n scripts/artemis-symphony-queue-bridge.sh
sh -n scripts/artemis-symphony-service.sh
sh -n scripts/artemis-symphony-remote-source.sh
sh -n scripts/artemis-symphony-remote-intake.sh
sh -n scripts/artemis-symphony-remote-promotion.sh
sh -n scripts/artemis-memory-zone.sh
sh -n scripts/artemis-project-graph.sh
sh -n scripts/artemis-project-graph-view.sh
sh -n scripts/artemis-project-brief.sh
sh -n scripts/artemis-guided-collaboration.sh
sh -n scripts/artemis-agent-launch-contract.sh
sh -n scripts/artemis-agent-runtime-dry-run.sh
sh -n scripts/artemis-agent-runtime-approval-gate.sh
sh -n scripts/artemis-agent-runtime-decision-intake.sh
sh -n scripts/artemis-agent-runtime-launcher-preflight.sh
sh -n scripts/artemis-approved-workspace-cleanup.sh
sh -n scripts/artemis-workspace-runtime-handoff.sh
sh -n scripts/artemis-runner.sh
sh -n scripts/artemis-validation-gate.sh
sh -n scripts/artemis-github-issues.sh
sh -n scripts/artemis-codex-app-server.sh
sh -n scripts/artemis-claude-code.sh
sh -n scripts/artemis-event-log.sh
sh -n scripts/validate-artemis.sh

scripts/artemis-tasks.sh >/tmp/artemis-tasks.json
if ! grep -q '"tasks": \[' /tmp/artemis-tasks.json; then
  echo "scripts/artemis-tasks.sh did not emit the expected tasks JSON" >&2
  exit 1
fi

if ! grep -q '"ticket": "TKT-' control-plane/tasks.json; then
  echo "control-plane/tasks.json does not contain ARTEMIS tasks" >&2
  exit 1
fi

scripts/artemis-dry-run.sh --json >/tmp/artemis-dry-run.json
if ! grep -q '"decisions": \[' /tmp/artemis-dry-run.json; then
  echo "scripts/artemis-dry-run.sh did not emit dry-run decisions" >&2
  exit 1
fi
python3 - /tmp/artemis-dry-run.json <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary = payload.get("summary", {})
eligible = int(summary.get("eligible", 0))
done = int(summary.get("done", 0))
decisions = payload.get("decisions", [])

if eligible > 0 and not any("workspace" in item for item in decisions):
    raise SystemExit("scripts/artemis-dry-run.sh did not include workspace readiness for eligible work")
if eligible == 0 and done <= 0:
    raise SystemExit("scripts/artemis-dry-run.sh has no eligible work and no completed tasks")
PY

cat >/tmp/artemis-runner-task-source.json <<'JSON'
{
  "schema_version": 1,
  "source": "scripts/validate-artemis.sh",
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
scripts/artemis-workspace.sh --input /tmp/artemis-runner-task-source.json --ticket TKT-VALIDATE --json >/tmp/artemis-workspace.json
if ! grep -q '"readiness": "ready"' /tmp/artemis-workspace.json; then
  echo "scripts/artemis-workspace.sh did not report ready workspace readiness" >&2
  exit 1
fi
scripts/artemis-workspace-lifecycle.sh --artifact-root /tmp/artemis-workspace-lifecycle --json >/tmp/artemis-workspace-lifecycle.json
if ! grep -q '"locks":' /tmp/artemis-workspace-lifecycle.json; then
  echo "scripts/artemis-workspace-lifecycle.sh did not emit lifecycle summary" >&2
  exit 1
fi
if ! test -f /tmp/artemis-workspace-lifecycle/WORKSPACE_LIFECYCLE.md; then
  echo "scripts/artemis-workspace-lifecycle.sh did not write lifecycle artifact" >&2
  exit 1
fi
scripts/artemis-workspace-cleanup-review.sh --artifact-root /tmp/artemis-workspace-cleanup-review --json >/tmp/artemis-workspace-cleanup-review.json
if ! grep -q '"cleanup_allowed_by_script": false' /tmp/artemis-workspace-cleanup-review.json; then
  echo "scripts/artemis-workspace-cleanup-review.sh did not preserve manual cleanup gate" >&2
  exit 1
fi
if ! test -f /tmp/artemis-workspace-cleanup-review/DECISION_TEMPLATE.md; then
  echo "scripts/artemis-workspace-cleanup-review.sh did not write decision template" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-workspace-cleanup-review/cleanup-review.json --artifact-root /tmp/artemis-human-cleanup-approval-contract --json >/tmp/artemis-human-cleanup-approval-contract.json
if ! grep -q '"valid_decisions":' /tmp/artemis-human-cleanup-approval-contract.json; then
  echo "scripts/artemis-human-cleanup-approval-contract.sh did not emit approval contract" >&2
  exit 1
fi
if ! grep -q '"overall": "human_gate"' /tmp/artemis-human-cleanup-approval-contract.json; then
  echo "scripts/artemis-human-cleanup-approval-contract.sh did not preserve pending Human Gate" >&2
  exit 1
fi
if ! test -f /tmp/artemis-human-cleanup-approval-contract/CLEANUP_APPROVAL_CONTRACT.md; then
  echo "scripts/artemis-human-cleanup-approval-contract.sh did not write contract artifact" >&2
  exit 1
fi
python3 - /tmp/artemis-workspace-cleanup-review/cleanup-review.json /tmp/artemis-approved-cleanup-decision.json <<'PY'
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
payload = json.loads(source.read_text(encoding="utf-8"))
for review in payload.get("reviews", []):
    review["decision_record"] = {
        "decision": "approved",
        "decided_by": "ARTEMIS validation",
        "decided_at": "2026-01-01T00:00:00Z",
        "reason": "Synthetic validation approval for dry-run contract checks.",
        "approved_commands": list(review.get("commands_after_approval") or []),
    }
target.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-approved-cleanup-decision.json --artifact-root /tmp/artemis-human-cleanup-approval-contract-approved --json >/tmp/artemis-human-cleanup-approval-contract-approved.json
if ! grep -q '"approved_ready": 3' /tmp/artemis-human-cleanup-approval-contract-approved.json; then
  echo "scripts/artemis-human-cleanup-approval-contract.sh did not accept exact approved commands" >&2
  exit 1
fi
scripts/artemis-human-decision-fixtures.sh --artifact-root /tmp/artemis-human-decision-fixtures --json >/tmp/artemis-human-decision-fixtures.json
if ! grep -q '"fixtures": 5' /tmp/artemis-human-decision-fixtures.json; then
  echo "scripts/artemis-human-decision-fixtures.sh did not emit five fixtures" >&2
  exit 1
fi
if ! grep -q '"execute_allowed": 0' /tmp/artemis-human-decision-fixtures.json; then
  echo "scripts/artemis-human-decision-fixtures.sh produced executable fixtures" >&2
  exit 1
fi
if ! test -f /tmp/artemis-human-decision-fixtures/HUMAN_DECISION_FIXTURES.md; then
  echo "scripts/artemis-human-decision-fixtures.sh did not write fixtures documentation" >&2
  exit 1
fi
if grep -R '../veri-artemis-worktrees' /tmp/artemis-human-decision-fixtures >/tmp/artemis-fixture-real-worktrees.matches 2>/dev/null; then
  echo "scripts/artemis-human-decision-fixtures.sh referenced real worktrees:" >&2
  cat /tmp/artemis-fixture-real-worktrees.matches >&2
  exit 1
fi
for fixture in approved-exact deferred rejected invalid-partial-approval invalid-missing-metadata; do
  if ! test -f "/tmp/artemis-human-decision-fixtures/fixtures/$fixture.json"; then
    echo "scripts/artemis-human-decision-fixtures.sh did not write fixture: $fixture" >&2
    exit 1
  fi
done
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/approved-exact.json --json >/tmp/artemis-fixture-approved-contract.json
if ! grep -q '"approved_ready": 1' /tmp/artemis-fixture-approved-contract.json; then
  echo "approved-exact fixture did not validate as approved_ready" >&2
  exit 1
fi
scripts/artemis-approved-workspace-cleanup.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/approved-exact.json --json >/tmp/artemis-fixture-approved-cleanup.json
if ! grep -q '"ready_to_execute": 1' /tmp/artemis-fixture-approved-cleanup.json; then
  echo "approved-exact fixture did not reach ready_to_execute in dry-run" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-fixture-approved-cleanup.json; then
  echo "approved-exact fixture executed commands during dry-run" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/deferred.json --json >/tmp/artemis-fixture-deferred-contract.json
if ! grep -q '"deferred": 1' /tmp/artemis-fixture-deferred-contract.json; then
  echo "deferred fixture did not validate as deferred" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/rejected.json --json >/tmp/artemis-fixture-rejected-contract.json
if ! grep -q '"rejected": 1' /tmp/artemis-fixture-rejected-contract.json; then
  echo "rejected fixture did not validate as rejected" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/invalid-partial-approval.json --json >/tmp/artemis-fixture-invalid-partial-contract.json
if ! grep -q '"invalid": 1' /tmp/artemis-fixture-invalid-partial-contract.json; then
  echo "invalid-partial-approval fixture did not validate as invalid" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-human-decision-fixtures/fixtures/invalid-missing-metadata.json --json >/tmp/artemis-fixture-invalid-missing-contract.json
if ! grep -q '"invalid": 1' /tmp/artemis-fixture-invalid-missing-contract.json; then
  echo "invalid-missing-metadata fixture did not validate as invalid" >&2
  exit 1
fi
scripts/artemis-real-cleanup-decision-package.sh --source /tmp/artemis-workspace-cleanup-review/cleanup-review.json --artifact-root /tmp/artemis-real-cleanup-decision-package --json >/tmp/artemis-real-cleanup-decision-package.json
if ! grep -q '"pending": 3' /tmp/artemis-real-cleanup-decision-package.json; then
  echo "scripts/artemis-real-cleanup-decision-package.sh did not emit three pending decisions" >&2
  exit 1
fi
if ! grep -q '"execute_allowed": 0' /tmp/artemis-real-cleanup-decision-package.json; then
  echo "scripts/artemis-real-cleanup-decision-package.sh produced executable decisions" >&2
  exit 1
fi
if ! test -f /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json; then
  echo "scripts/artemis-real-cleanup-decision-package.sh did not write the fillable decision JSON" >&2
  exit 1
fi
if ! test -f /tmp/artemis-real-cleanup-decision-package/REAL_CLEANUP_DECISION_PACKAGE.md; then
  echo "scripts/artemis-real-cleanup-decision-package.sh did not write package documentation" >&2
  exit 1
fi
scripts/artemis-human-cleanup-approval-contract.sh --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --json >/tmp/artemis-real-cleanup-decision-contract.json
if ! grep -q '"pending": 3' /tmp/artemis-real-cleanup-decision-contract.json; then
  echo "real cleanup decision package did not validate as three pending decisions" >&2
  exit 1
fi
if ! grep -q '"execution_allowed": 0' /tmp/artemis-real-cleanup-decision-contract.json; then
  echo "real cleanup decision package allowed execution before human approval" >&2
  exit 1
fi
scripts/artemis-approved-workspace-cleanup.sh --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --json >/tmp/artemis-real-cleanup-decision-dry-run.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-real-cleanup-decision-dry-run.json; then
  echo "real cleanup decision package did not stop at Human Gate" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-real-cleanup-decision-dry-run.json; then
  echo "real cleanup decision package executed commands during dry-run" >&2
  exit 1
fi
if [ -d artifacts/artemis-assisted-human-decision-runbook/run-01 ]; then
  scripts/artemis-human-decision-runbook-consistency.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --runbook-root artifacts/artemis-assisted-human-decision-runbook/run-01 --artifact-root /tmp/artemis-human-decision-runbook-consistency --json >/tmp/artemis-human-decision-runbook-consistency.json
  if ! grep -q '"overall": "passed"' /tmp/artemis-human-decision-runbook-consistency.json; then
    echo "scripts/artemis-human-decision-runbook-consistency.sh did not pass" >&2
    exit 1
  fi
  if ! grep -q '"commands_checked": 9' /tmp/artemis-human-decision-runbook-consistency.json; then
    echo "runbook consistency did not check all cleanup commands" >&2
    exit 1
  fi
  if ! grep -q '"evidence_checked": 18' /tmp/artemis-human-decision-runbook-consistency.json; then
    echo "runbook consistency did not check all evidence entries" >&2
    exit 1
  fi
fi
if [ -d artifacts/artemis-human-decision-release-checkpoint/run-01 ]; then
  scripts/artemis-human-decision-release-checkpoint.sh --artifact-root /tmp/artemis-human-decision-release-checkpoint --json >/tmp/artemis-human-decision-release-checkpoint.json
  if ! grep -q '"overall": "passed"' /tmp/artemis-human-decision-release-checkpoint.json; then
    echo "scripts/artemis-human-decision-release-checkpoint.sh did not pass" >&2
    exit 1
  fi
  if ! grep -q '"cleanup_execution_allowed": false' /tmp/artemis-human-decision-release-checkpoint.json; then
    echo "human decision release checkpoint allowed cleanup execution" >&2
    exit 1
  fi
  if ! grep -q '"pending": 3' /tmp/artemis-human-decision-release-checkpoint.json; then
    echo "human decision release checkpoint did not preserve three pending decisions" >&2
    exit 1
  fi
fi
scripts/artemis-human-decision-intake.sh --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --checkpoint-root artifacts/artemis-human-decision-release-checkpoint/run-01 --artifact-root /tmp/artemis-human-decision-intake --json >/tmp/artemis-human-decision-intake.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-human-decision-intake.json; then
  echo "scripts/artemis-human-decision-intake.sh did not stop pending decision at Human Gate" >&2
  exit 1
fi
if ! grep -q '"pending": 3' /tmp/artemis-human-decision-intake.json; then
  echo "human decision intake did not preserve three pending decisions" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-human-decision-intake.json; then
  echo "human decision intake executed cleanup commands" >&2
  exit 1
fi
if ! grep -q '"cleanup_execution_allowed": false' /tmp/artemis-human-decision-intake.json; then
  echo "human decision intake allowed cleanup execution" >&2
  exit 1
fi
scripts/artemis-human-decision-pending-gate.sh --intake-root /tmp/artemis-human-decision-intake --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --artifact-root /tmp/artemis-human-decision-pending-gate --json >/tmp/artemis-human-decision-pending-gate.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-human-decision-pending-gate.json; then
  echo "scripts/artemis-human-decision-pending-gate.sh did not register Human Gate" >&2
  exit 1
fi
if ! grep -q '"pending": 3' /tmp/artemis-human-decision-pending-gate.json; then
  echo "human decision pending gate did not preserve three pending decisions" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-human-decision-pending-gate.json; then
  echo "human decision pending gate detected executed commands" >&2
  exit 1
fi
if ! grep -q '"cleanup_execution_allowed": false' /tmp/artemis-human-decision-pending-gate.json; then
  echo "human decision pending gate allowed cleanup execution" >&2
  exit 1
fi
scripts/artemis-human-decision-reentry-contract.sh --pending-gate-root /tmp/artemis-human-decision-pending-gate --intake-root /tmp/artemis-human-decision-intake --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --artifact-root /tmp/artemis-human-decision-reentry-contract --json >/tmp/artemis-human-decision-reentry-contract.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-human-decision-reentry-contract.json; then
  echo "scripts/artemis-human-decision-reentry-contract.sh did not keep pending decisions in Human Gate" >&2
  exit 1
fi
if ! grep -q '"pending": 3' /tmp/artemis-human-decision-reentry-contract.json; then
  echo "human decision reentry contract did not preserve three pending decisions" >&2
  exit 1
fi
if ! grep -q '"preflight_allowed": false' /tmp/artemis-human-decision-reentry-contract.json; then
  echo "human decision reentry contract allowed preflight before approval" >&2
  exit 1
fi
if ! grep -q '"cleanup_execution_allowed": false' /tmp/artemis-human-decision-reentry-contract.json; then
  echo "human decision reentry contract allowed cleanup execution" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-human-decision-reentry-contract.json; then
  echo "human decision reentry contract detected executed commands" >&2
  exit 1
fi
scripts/artemis-post-human-approval-preflight.sh --reentry-root /tmp/artemis-human-decision-reentry-contract --intake-root /tmp/artemis-human-decision-intake --decision /tmp/artemis-real-cleanup-decision-package/real-cleanup-decision.json --artifact-root /tmp/artemis-post-human-approval-preflight --json >/tmp/artemis-post-human-approval-preflight.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-post-human-approval-preflight.json; then
  echo "scripts/artemis-post-human-approval-preflight.sh did not stop pending decisions at Human Gate" >&2
  exit 1
fi
if ! grep -q '"pending": 3' /tmp/artemis-post-human-approval-preflight.json; then
  echo "post-human approval preflight did not preserve three pending decisions" >&2
  exit 1
fi
if ! grep -q '"supervised_preflight_allowed": false' /tmp/artemis-post-human-approval-preflight.json; then
  echo "post-human approval preflight allowed preflight before approval" >&2
  exit 1
fi
if ! grep -q '"cleanup_execution_allowed": false' /tmp/artemis-post-human-approval-preflight.json; then
  echo "post-human approval preflight allowed cleanup execution" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-post-human-approval-preflight.json; then
  echo "post-human approval preflight detected executed commands" >&2
  exit 1
fi
scripts/artemis-application-readiness.sh --artifact-root /tmp/artemis-application-readiness --json >/tmp/artemis-application-readiness.json
if ! grep -q '"overall": "ready_with_human_gates"' /tmp/artemis-application-readiness.json; then
  echo "scripts/artemis-application-readiness.sh did not report ready_with_human_gates" >&2
  exit 1
fi
if ! grep -q '"application_ready": true' /tmp/artemis-application-readiness.json; then
  echo "scripts/artemis-application-readiness.sh did not report application_ready=true" >&2
  exit 1
fi
if ! grep -q '"active_tasks": 0' /tmp/artemis-application-readiness.json; then
  echo "application readiness did not preserve zero active tasks" >&2
  exit 1
fi
scripts/artemis-symphony-compatibility.sh --artifact-root /tmp/artemis-symphony-compatibility --json >/tmp/artemis-symphony-compatibility.json
if ! grep -q '"overall": "spec_ready"' /tmp/artemis-symphony-compatibility.json; then
  echo "scripts/artemis-symphony-compatibility.sh did not report spec_ready" >&2
  exit 1
fi
if ! grep -q '"adoption_mode": "inspired_spec_not_dependency"' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not preserve inspired-spec adoption mode" >&2
  exit 1
fi
if ! grep -q '"code_copied": false' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not preserve no-code-copy invariant" >&2
  exit 1
fi
if ! grep -q '"next_cut_defined": true' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not define next cut" >&2
  exit 1
fi
if ! grep -q '"kernel_implemented": true' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not detect the read-only kernel" >&2
  exit 1
fi
if ! grep -q '"daemon_implemented": true' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not detect the daemon dry-run" >&2
  exit 1
fi
if ! grep -q '"daemon_dry_run": true' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not preserve daemon dry-run mode" >&2
  exit 1
fi
if ! grep -q '"queue_implemented": true' /tmp/artemis-symphony-compatibility.json; then
  echo "ARTEMIS Symphony compatibility did not detect the supervised queue" >&2
  exit 1
fi
cat >/tmp/artemis-symphony-kernel-source.json <<'JSON'
{
  "schema_version": 1,
  "source": "scripts/validate-artemis.sh",
  "tasks": [
    {
      "id": "tkt-validate-a",
      "ticket": "TKT-901",
      "title": "Validate Symphony dispatch slot A",
      "state": "ready",
      "owner": "Codex",
      "risk": "low",
      "summary": "Synthetic task used to prove read-only kernel dispatch planning.",
      "exec_pack": "docs/exec-packs/active/TKT-901.md",
      "evidence": "artifacts/validate-symphony-a/run-01/STATUS.md",
      "tags": ["exec-pack", "validation"]
    },
    {
      "id": "tkt-validate-b",
      "ticket": "TKT-902",
      "title": "Validate Symphony dispatch slot B",
      "state": "ready",
      "owner": "Codex",
      "risk": "low",
      "summary": "Synthetic task used to prove bounded read-only kernel dispatch planning.",
      "exec_pack": "docs/exec-packs/active/TKT-902.md",
      "evidence": "artifacts/validate-symphony-b/run-01/STATUS.md",
      "tags": ["exec-pack", "validation"]
    }
  ]
}
JSON
scripts/artemis-symphony-kernel.sh --input /tmp/artemis-symphony-kernel-source.json --artifact-root /tmp/artemis-symphony-kernel --max-concurrency 2 --json >/tmp/artemis-symphony-kernel.json
if ! grep -q '"overall": "dispatch_plan_ready"' /tmp/artemis-symphony-kernel.json; then
  echo "scripts/artemis-symphony-kernel.sh did not produce a dispatch plan" >&2
  exit 1
fi
if ! grep -q '"selected_for_dispatch": 2' /tmp/artemis-symphony-kernel.json; then
  echo "ARTEMIS Symphony kernel did not select both eligible synthetic tasks" >&2
  exit 1
fi
if ! grep -q '"max_concurrency": 2' /tmp/artemis-symphony-kernel.json; then
  echo "ARTEMIS Symphony kernel did not preserve configured concurrency" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-kernel.json; then
  echo "ARTEMIS Symphony kernel executed commands during read-only planning" >&2
  exit 1
fi
if ! grep -q '"runner_execution_allowed": false' /tmp/artemis-symphony-kernel.json; then
  echo "ARTEMIS Symphony kernel allowed runner execution in read-only mode" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-kernel/STATUS.md; then
  echo "scripts/artemis-symphony-kernel.sh did not write STATUS.md" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-kernel/events.json; then
  echo "scripts/artemis-symphony-kernel.sh did not write events.json" >&2
  exit 1
fi
scripts/artemis-symphony-bridge.sh --input /tmp/artemis-symphony-kernel-source.json --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-bridge --max-concurrency 2 --json >/tmp/artemis-symphony-bridge.json
if ! grep -q '"overall": "runner_plan_ready"' /tmp/artemis-symphony-bridge.json; then
  echo "scripts/artemis-symphony-bridge.sh did not create a supervised runner plan" >&2
  exit 1
fi
if ! grep -q '"ticket_in_dispatch_plan": true' /tmp/artemis-symphony-bridge.json; then
  echo "ARTEMIS Symphony bridge did not require dispatch-plan membership" >&2
  exit 1
fi
if ! grep -q '"runner_planned": true' /tmp/artemis-symphony-bridge.json; then
  echo "ARTEMIS Symphony bridge did not plan a runner attempt" >&2
  exit 1
fi
if ! grep -q '"execute_requested": false' /tmp/artemis-symphony-bridge.json; then
  echo "ARTEMIS Symphony bridge did not stay plan-only by default" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-bridge.json; then
  echo "ARTEMIS Symphony bridge executed commands without --execute" >&2
  exit 1
fi
if ! grep -q '"automatic_daemon": false' /tmp/artemis-symphony-bridge.json; then
  echo "ARTEMIS Symphony bridge reported daemon behavior" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-bridge/STATUS.md; then
  echo "scripts/artemis-symphony-bridge.sh did not write STATUS.md" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-bridge/events.json; then
  echo "scripts/artemis-symphony-bridge.sh did not write events.json" >&2
  exit 1
fi
set +e
scripts/artemis-symphony-bridge.sh --input /tmp/artemis-symphony-kernel-source.json --ticket TKT-999 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-bridge-missing --max-concurrency 2 --json >/tmp/artemis-symphony-bridge-missing.json
bridge_missing_code=$?
set -e
if [ "$bridge_missing_code" -eq 0 ]; then
  echo "ARTEMIS Symphony bridge accepted a ticket outside dispatch_plan" >&2
  exit 1
fi
if ! grep -q '"overall": "not_dispatchable"' /tmp/artemis-symphony-bridge-missing.json; then
  echo "ARTEMIS Symphony bridge did not report not_dispatchable for missing ticket" >&2
  exit 1
fi
if ! grep -q '"ticket_in_dispatch_plan": false' /tmp/artemis-symphony-bridge-missing.json; then
  echo "ARTEMIS Symphony bridge did not preserve dispatch-plan membership failure" >&2
  exit 1
fi
if ! grep -q '"runner_planned": false' /tmp/artemis-symphony-bridge-missing.json; then
  echo "ARTEMIS Symphony bridge planned a runner attempt for a missing ticket" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-bridge-missing.json; then
  echo "ARTEMIS Symphony bridge executed commands for a missing ticket" >&2
  exit 1
fi
scripts/artemis-symphony-daemon.sh --input /tmp/artemis-symphony-kernel-source.json --artifact-root /tmp/artemis-symphony-daemon --ticks 2 --interval 0 --max-concurrency 2 --json >/tmp/artemis-symphony-daemon.json
if ! grep -q '"overall": "heartbeat_ready"' /tmp/artemis-symphony-daemon.json; then
  echo "scripts/artemis-symphony-daemon.sh did not report heartbeat_ready" >&2
  exit 1
fi
if ! grep -q '"ticks_completed": 2' /tmp/artemis-symphony-daemon.json; then
  echo "ARTEMIS Symphony daemon dry-run did not complete both ticks" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-daemon.json; then
  echo "ARTEMIS Symphony daemon dry-run executed commands" >&2
  exit 1
fi
if ! grep -q '"runner_auto_execution_allowed": false' /tmp/artemis-symphony-daemon.json; then
  echo "ARTEMIS Symphony daemon dry-run allowed runner auto execution" >&2
  exit 1
fi
if ! grep -q '"bridge_called": false' /tmp/artemis-symphony-daemon.json; then
  echo "ARTEMIS Symphony daemon dry-run called the bridge" >&2
  exit 1
fi
if ! grep -q '"long_running_process_started": false' /tmp/artemis-symphony-daemon.json; then
  echo "ARTEMIS Symphony daemon dry-run started a long-running process" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-daemon/heartbeat.json; then
  echo "scripts/artemis-symphony-daemon.sh did not write heartbeat.json" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-daemon/heartbeat.jsonl; then
  echo "scripts/artemis-symphony-daemon.sh did not write heartbeat.jsonl" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-daemon/events.json; then
  echo "scripts/artemis-symphony-daemon.sh did not write events.json" >&2
  exit 1
fi
scripts/artemis-symphony-queue.sh --daemon /tmp/artemis-symphony-daemon/symphony-daemon.json --artifact-root /tmp/artemis-symphony-queue --json >/tmp/artemis-symphony-queue.json
if ! grep -q '"overall": "queue_ready"' /tmp/artemis-symphony-queue.json; then
  echo "scripts/artemis-symphony-queue.sh did not report queue_ready" >&2
  exit 1
fi
if ! grep -q '"queue_items": 2' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue did not materialize both dispatch items" >&2
  exit 1
fi
if ! grep -q '"review_required": 2' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue did not require review for both items" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue executed commands" >&2
  exit 1
fi
if ! grep -q '"bridge_called": false' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue called the bridge" >&2
  exit 1
fi
if ! grep -q '"runner_called": false' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue called the runner" >&2
  exit 1
fi
if ! grep -q '"terminal_override_required": true' /tmp/artemis-symphony-queue.json; then
  echo "ARTEMIS Symphony queue did not require terminal override" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-queue/symphony-queue.json; then
  echo "scripts/artemis-symphony-queue.sh did not write symphony-queue.json" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-queue/events.json; then
  echo "scripts/artemis-symphony-queue.sh did not write events.json" >&2
  exit 1
fi
scripts/artemis-symphony-queue-bridge.sh --queue /tmp/artemis-symphony-queue/symphony-queue.json --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-queue-bridge --json >/tmp/artemis-symphony-queue-bridge.json
if ! grep -q '"overall": "bridge_plan_ready"' /tmp/artemis-symphony-queue-bridge.json; then
  echo "scripts/artemis-symphony-queue-bridge.sh did not report bridge_plan_ready" >&2
  exit 1
fi
if ! grep -q '"queue_item_found": true' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge did not consume a queue item" >&2
  exit 1
fi
if ! grep -q '"bridge_planned": true' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge did not plan bridge execution" >&2
  exit 1
fi
if ! grep -q '"execute_requested": false' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge requested execution" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge executed commands" >&2
  exit 1
fi
if ! grep -q '"runner_executed": false' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge reported runner execution" >&2
  exit 1
fi
if ! grep -q '"validation_gate_required_before_execute": true' /tmp/artemis-symphony-queue-bridge.json; then
  echo "ARTEMIS Symphony queue bridge did not require Validation Gate before execution" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-queue-bridge/queue-bridge.json; then
  echo "scripts/artemis-symphony-queue-bridge.sh did not write queue-bridge.json" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-queue-bridge/events.json; then
  echo "scripts/artemis-symphony-queue-bridge.sh did not write events.json" >&2
  exit 1
fi
cat >/tmp/artemis-symphony-queue-bridge-validation-gate.json <<'JSON'
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
      "log": "/tmp/artemis-symphony-queue-bridge-validation.log"
    }
  ]
}
JSON
cat >/tmp/artemis-symphony-queue-bridge-decision.json <<'JSON'
{
  "schema_version": 1,
  "decision": "approved",
  "ticket": "TKT-901",
  "queue_id": "queue-001-tkt-901",
  "command": "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json",
  "validation_gate": "/tmp/artemis-symphony-queue-bridge-validation-gate.json",
  "validation_human_gates_acknowledged": true,
  "decided_by": "ARTEMIS synthetic validation",
  "reason": "Exact local dry-run command approved for queue execution validation."
}
JSON
scripts/artemis-symphony-queue-bridge.sh --queue /tmp/artemis-symphony-queue/symphony-queue.json --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-queue-bridge-execute --execute --validation-gate /tmp/artemis-symphony-queue-bridge-validation-gate.json --decision /tmp/artemis-symphony-queue-bridge-decision.json --json >/tmp/artemis-symphony-queue-bridge-execute.json
if ! grep -q '"overall": "runner_executed"' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "scripts/artemis-symphony-queue-bridge.sh did not report runner_executed with exact approval" >&2
  exit 1
fi
if ! grep -q '"execute_requested": true' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "ARTEMIS Symphony queue bridge did not preserve execute_requested=true" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 1' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "ARTEMIS Symphony queue bridge did not execute the approved synthetic command" >&2
  exit 1
fi
if ! grep -q '"runner_executed": true' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "ARTEMIS Symphony queue bridge did not report runner_executed=true" >&2
  exit 1
fi
if ! grep -q '"validation_gate_passed": true' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "ARTEMIS Symphony queue bridge did not require a passing Validation Gate" >&2
  exit 1
fi
if ! grep -q '"approval_exact": true' /tmp/artemis-symphony-queue-bridge-execute.json; then
  echo "ARTEMIS Symphony queue bridge did not require exact approval" >&2
  exit 1
fi
scripts/artemis-symphony-service.sh --input /tmp/artemis-symphony-kernel-source.json --artifact-root /tmp/artemis-symphony-service --ticks 1 --interval 0 --max-concurrency 2 --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --json >/tmp/artemis-symphony-service.json
if ! grep -q '"overall": "service_bridge_plan_ready"' /tmp/artemis-symphony-service.json; then
  echo "scripts/artemis-symphony-service.sh did not report service_bridge_plan_ready" >&2
  exit 1
fi
if ! grep -q '"queue_bridge_requested": true' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service did not preserve queue_bridge_requested=true" >&2
  exit 1
fi
if ! grep -q '"queue_bridge_plan_ready": true' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service did not produce a plan-only queue bridge" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service executed commands" >&2
  exit 1
fi
if ! grep -q '"execute_supported_by_service": false' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service reported service-level execution support" >&2
  exit 1
fi
if ! grep -q '"runner_auto_execution_allowed": false' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service allowed runner auto execution" >&2
  exit 1
fi
if ! grep -q '"long_running_process_started": false' /tmp/artemis-symphony-service.json; then
  echo "ARTEMIS Symphony service started a long-running process" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-service/symphony-service.json; then
  echo "scripts/artemis-symphony-service.sh did not write symphony-service.json" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-service/events.json; then
  echo "scripts/artemis-symphony-service.sh did not write events.json" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-service/queue-bridge/queue-bridge.json; then
  echo "scripts/artemis-symphony-service.sh did not write queue bridge evidence" >&2
  exit 1
fi
if scripts/artemis-symphony-queue-bridge.sh --queue /tmp/artemis-symphony-queue/symphony-queue.json --ticket TKT-901 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-queue-bridge-execute-blocked --execute --validation-gate /tmp/artemis-symphony-queue-bridge-validation-gate.json --json >/tmp/artemis-symphony-queue-bridge-execute-blocked.json 2>/tmp/artemis-symphony-queue-bridge-execute-blocked.stderr; then
  echo "ARTEMIS Symphony queue bridge should reject --execute without decision" >&2
  exit 1
fi
if scripts/artemis-symphony-queue-bridge.sh --queue /tmp/artemis-symphony-queue/symphony-queue.json --ticket TKT-999 --command "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-kernel-source.json" --artifact-root /tmp/artemis-symphony-queue-bridge-missing --json >/tmp/artemis-symphony-queue-bridge-missing.json 2>/tmp/artemis-symphony-queue-bridge-missing.stderr; then
  echo "ARTEMIS Symphony queue bridge should reject missing queue tickets" >&2
  exit 1
fi
if ! grep -q '"overall": "not_in_queue"' /tmp/artemis-symphony-queue-bridge-missing.json; then
  echo "ARTEMIS Symphony queue bridge missing-ticket artifact did not report not_in_queue" >&2
  exit 1
fi
if ! grep -q '"queue_item_found": false' /tmp/artemis-symphony-queue-bridge-missing.json; then
  echo "ARTEMIS Symphony queue bridge missing-ticket artifact did not preserve queue evidence" >&2
  exit 1
fi
scripts/artemis-approved-workspace-cleanup.sh --decision /tmp/artemis-workspace-cleanup-review/cleanup-review.json --artifact-root /tmp/artemis-approved-workspace-cleanup --json >/tmp/artemis-approved-workspace-cleanup.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-approved-workspace-cleanup.json; then
  echo "scripts/artemis-approved-workspace-cleanup.sh did not stop pending decisions at Human Gate" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-approved-workspace-cleanup.json; then
  echo "scripts/artemis-approved-workspace-cleanup.sh executed commands during dry-run" >&2
  exit 1
fi
scripts/artemis-approved-workspace-cleanup.sh --decision /tmp/artemis-approved-cleanup-decision.json --artifact-root /tmp/artemis-approved-workspace-cleanup-approved --json >/tmp/artemis-approved-workspace-cleanup-approved.json
if ! grep -q '"ready_to_execute": 3' /tmp/artemis-approved-workspace-cleanup-approved.json; then
  echo "scripts/artemis-approved-workspace-cleanup.sh did not mark exact approved commands ready in dry-run" >&2
  exit 1
fi
if ! grep -q '"executed_commands": 0' /tmp/artemis-approved-workspace-cleanup-approved.json; then
  echo "scripts/artemis-approved-workspace-cleanup.sh executed exact approvals during dry-run" >&2
  exit 1
fi
scripts/artemis-workspace-runtime-handoff.sh --lifecycle /tmp/artemis-workspace-lifecycle/workspace-lifecycle.json --cleanup /tmp/artemis-approved-workspace-cleanup/approved-cleanup.json --artifact-root /tmp/artemis-workspace-runtime-handoff --json >/tmp/artemis-workspace-runtime-handoff.json
if ! grep -q '"pending":' /tmp/artemis-workspace-runtime-handoff.json; then
  echo "scripts/artemis-workspace-runtime-handoff.sh did not emit runtime handoff summary" >&2
  exit 1
fi
if ! test -f /tmp/artemis-workspace-runtime-handoff/RUNTIME_HANDOFF.md; then
  echo "scripts/artemis-workspace-runtime-handoff.sh did not write runtime handoff artifact" >&2
  exit 1
fi
python3 - /tmp/artemis-workspace-cleanup-review/cleanup-review.json /tmp/artemis-decision-states-cleanup.json /tmp/artemis-decision-states-contract.json <<'PY'
import json
import sys
from pathlib import Path

reviews = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["reviews"]
states = ["approved_ready", "deferred", "rejected"]
cleanup_results = []
contract_results = []
for review, state in zip(reviews, states):
    ticket = review["ticket"]
    status = "ready_to_execute" if state == "approved_ready" else "human_gate"
    cleanup_results.append({
        "ticket": ticket,
        "status": status,
        "contract_status": state,
        "execute_requested": False,
        "executed": False,
        "blockers": [] if state == "approved_ready" else [f"decision is {state}, not approved for cleanup execution"],
        "expected_commands": review.get("commands_after_approval", []),
        "approved_commands": review.get("commands_after_approval", []) if state == "approved_ready" else [],
        "command_results": [],
    })
    contract_results.append({
        "ticket": ticket,
        "decision": "approved" if state == "approved_ready" else state,
        "contract_state": state,
        "execution_allowed": state == "approved_ready",
        "required_fields": ["decided_by", "decided_at", "reason"],
        "expected_commands": review.get("commands_after_approval", []),
        "approved_commands": review.get("commands_after_approval", []) if state == "approved_ready" else [],
        "blockers": [],
        "warnings": [],
    })

Path(sys.argv[2]).write_text(json.dumps({
    "schema_version": 1,
    "generated_at": "2026-01-01T00:00:00Z",
    "source": "scripts/validate-artemis.sh",
    "mode": "dry_run",
    "overall": "human_gate",
    "summary": {
        "reviewed": len(cleanup_results),
        "ready_to_execute": 1,
        "human_gate": 2,
        "failed": 0,
        "executed_commands": 0,
    },
    "results": cleanup_results,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

Path(sys.argv[3]).write_text(json.dumps({
    "schema_version": 1,
    "generated_at": "2026-01-01T00:00:00Z",
    "source": "scripts/validate-artemis.sh",
    "mode": "read_only",
    "overall": "passed",
    "summary": {
        "reviewed": len(contract_results),
        "pending": 0,
        "approved_ready": 1,
        "deferred": 1,
        "rejected": 1,
        "invalid": 0,
        "execution_allowed": 1,
    },
    "results": contract_results,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
scripts/artemis-workspace-runtime-handoff.sh --lifecycle /tmp/artemis-workspace-lifecycle/workspace-lifecycle.json --cleanup /tmp/artemis-decision-states-cleanup.json --approval-contract /tmp/artemis-decision-states-contract.json --artifact-root /tmp/artemis-workspace-runtime-handoff-states --json >/tmp/artemis-workspace-runtime-handoff-states.json
if ! grep -q '"approved_ready": 1' /tmp/artemis-workspace-runtime-handoff-states.json; then
  echo "scripts/artemis-workspace-runtime-handoff.sh did not emit approved_ready state" >&2
  exit 1
fi
if ! grep -q '"deferred": 1' /tmp/artemis-workspace-runtime-handoff-states.json; then
  echo "scripts/artemis-workspace-runtime-handoff.sh did not emit deferred state" >&2
  exit 1
fi
if ! grep -q '"rejected": 1' /tmp/artemis-workspace-runtime-handoff-states.json; then
  echo "scripts/artemis-workspace-runtime-handoff.sh did not emit rejected state" >&2
  exit 1
fi
scripts/artemis-runner.sh --input /tmp/artemis-runner-task-source.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input /tmp/artemis-runner-task-source.json" --artifact-root /tmp/artemis-runner-validation >/tmp/artemis-runner.out
if ! grep -q '/tmp/artemis-runner-validation/attempts/' /tmp/artemis-runner.out; then
  echo "scripts/artemis-runner.sh did not create a supervised attempt artifact" >&2
  exit 1
fi
if ! find /tmp/artemis-runner-validation/attempts -name workspace.json -type f | grep -q workspace.json; then
  echo "scripts/artemis-runner.sh did not record workspace readiness in the attempt" >&2
  exit 1
fi
runner_events=$(find /tmp/artemis-runner-validation/attempts -name events.json -type f -print -quit)
if [ -z "$runner_events" ]; then
  echo "scripts/artemis-runner.sh did not record canonical runner events" >&2
  exit 1
fi
if ! grep -q '"event_type": "runner.attempt_planned"' "$runner_events"; then
  echo "scripts/artemis-runner.sh did not emit runner.attempt_planned" >&2
  exit 1
fi
if ! grep -q '"event_type": "runner.attempt_completed"' "$runner_events"; then
  echo "scripts/artemis-runner.sh did not emit runner.attempt_completed" >&2
  exit 1
fi

scripts/artemis-validation-gate.sh --artifact-root /tmp/artemis-validation-gate --json >/tmp/artemis-validation-gate.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-validation-gate.json; then
  echo "scripts/artemis-validation-gate.sh did not report the expected Human Gate status" >&2
  exit 1
fi
if ! grep -q '"event_type": "validation.completed"' /tmp/artemis-validation-gate/events.json; then
  echo "scripts/artemis-validation-gate.sh did not emit canonical events" >&2
  exit 1
fi
if ! find /tmp/artemis-validation-gate/runner-attempts -name events.json -type f -print -quit | grep -q events.json; then
  echo "scripts/artemis-validation-gate.sh did not preserve runner attempt events" >&2
  exit 1
fi

scripts/artemis-github-issues.sh --artifact-root /tmp/artemis-github-issues --json >/tmp/artemis-github-issues.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-github-issues.json; then
  echo "scripts/artemis-github-issues.sh did not report the expected Human Gate status" >&2
  exit 1
fi
if ! grep -q '"event_type": "runner.readiness_checked"' /tmp/artemis-github-issues/events.json; then
  echo "scripts/artemis-github-issues.sh did not emit canonical events" >&2
  exit 1
fi

cat >/tmp/artemis-symphony-remote-source-github.json <<'JSON'
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
scripts/artemis-symphony-remote-source.sh --github-artifact /tmp/artemis-symphony-remote-source-github.json --artifact-root /tmp/artemis-symphony-remote-source --json >/tmp/artemis-symphony-remote-source.json
if ! grep -q '"overall": "remote_source_ready"' /tmp/artemis-symphony-remote-source.json; then
  echo "scripts/artemis-symphony-remote-source.sh did not report remote_source_ready for synthetic issue artifact" >&2
  exit 1
fi
if ! grep -q '"tasks_generated": 1' /tmp/artemis-symphony-remote-source.json; then
  echo "ARTEMIS Symphony remote source did not generate a supervised task source" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-symphony-remote-source.json; then
  echo "ARTEMIS Symphony remote source allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"direct_dispatch_allowed": false' /tmp/artemis-symphony-remote-source.json; then
  echo "ARTEMIS Symphony remote source allowed direct dispatch" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-remote-source.json; then
  echo "ARTEMIS Symphony remote source executed commands" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-remote-source/task-source.json; then
  echo "scripts/artemis-symphony-remote-source.sh did not write task-source.json" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-symphony-remote-source/events.json; then
  echo "scripts/artemis-symphony-remote-source.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-symphony-remote-intake.sh --remote-source /tmp/artemis-symphony-remote-source/remote-source.json --artifact-root /tmp/artemis-symphony-remote-intake --json >/tmp/artemis-symphony-remote-intake.json
if ! grep -q '"overall": "remote_intake_ready"' /tmp/artemis-symphony-remote-intake.json; then
  echo "scripts/artemis-symphony-remote-intake.sh did not report remote_intake_ready for synthetic source" >&2
  exit 1
fi
if ! grep -q '"review_ready": 1' /tmp/artemis-symphony-remote-intake.json; then
  echo "ARTEMIS Symphony remote intake did not mark the synthetic item review_ready" >&2
  exit 1
fi
if ! grep -q '"promotion_allowed": 0' /tmp/artemis-symphony-remote-intake.json; then
  echo "ARTEMIS Symphony remote intake allowed promotion before human review" >&2
  exit 1
fi
if ! grep -q '"direct_dispatch_allowed": false' /tmp/artemis-symphony-remote-intake.json; then
  echo "ARTEMIS Symphony remote intake allowed direct dispatch" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-remote-intake.json; then
  echo "ARTEMIS Symphony remote intake executed commands" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-remote-intake/review-source.json; then
  echo "scripts/artemis-symphony-remote-intake.sh did not write review-source.json" >&2
  exit 1
fi
scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-remote-intake/review-source.json --json >/tmp/artemis-symphony-remote-intake-dry-run.json
if ! grep -q '"eligible": 0' /tmp/artemis-symphony-remote-intake-dry-run.json; then
  echo "remote intake review-source produced eligible dispatch work" >&2
  exit 1
fi
if ! grep -q '"human_gate": 1' /tmp/artemis-symphony-remote-intake-dry-run.json; then
  echo "remote intake review-source did not stay in Human Gate" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-symphony-remote-intake/events.json; then
  echo "scripts/artemis-symphony-remote-intake.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-symphony-remote-promotion.sh --remote-intake /tmp/artemis-symphony-remote-intake/remote-intake.json --artifact-root /tmp/artemis-symphony-promotion-no-decision --json >/tmp/artemis-symphony-promotion-no-decision.json
if ! grep -q '"overall": "remote_promotion_human_gate"' /tmp/artemis-symphony-promotion-no-decision.json; then
  echo "scripts/artemis-symphony-remote-promotion.sh did not keep missing decision in Human Gate" >&2
  exit 1
fi
cat >/tmp/artemis-symphony-promotion-validation-gate.json <<'JSON'
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
      "log": "/tmp/artemis-symphony-promotion-validation-gate.log"
    }
  ]
}
JSON
cat >/tmp/artemis-symphony-promotion-decision.json <<'JSON'
{
  "schema_version": 1,
  "decision": "approved",
  "ticket": "TKT-950",
  "promote_to": "TKT-950",
  "title": "Validate supervised source intake",
  "owner": "Codex",
  "risk": "low",
  "exec_pack": "docs/exec-packs/done/TKT-009-local-task-source.md",
  "evidence": "/tmp/artemis-symphony-promotion/STATUS.md",
  "command": "scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-promotion/promoted-source.json",
  "validation_gate": "/tmp/artemis-symphony-promotion-validation-gate.json",
  "remote_review_acknowledged": true,
  "terminal_command_acknowledged": true,
  "validation_gate_required": true,
  "decided_by": "ARTEMIS synthetic validation",
  "reason": "Exact local promotion approved for validation."
}
JSON
scripts/artemis-symphony-remote-promotion.sh --remote-intake /tmp/artemis-symphony-remote-intake/remote-intake.json --decision /tmp/artemis-symphony-promotion-decision.json --artifact-root /tmp/artemis-symphony-promotion --json >/tmp/artemis-symphony-promotion.json
if ! grep -q '"overall": "remote_promotion_ready"' /tmp/artemis-symphony-promotion.json; then
  echo "scripts/artemis-symphony-remote-promotion.sh did not report remote_promotion_ready for exact decision" >&2
  exit 1
fi
if ! grep -q '"promoted": 1' /tmp/artemis-symphony-promotion.json; then
  echo "ARTEMIS Symphony remote promotion did not promote the synthetic item" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-symphony-promotion.json; then
  echo "ARTEMIS Symphony remote promotion allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"direct_dispatch_allowed": false' /tmp/artemis-symphony-promotion.json; then
  echo "ARTEMIS Symphony remote promotion allowed direct dispatch" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-symphony-promotion.json; then
  echo "ARTEMIS Symphony remote promotion executed commands" >&2
  exit 1
fi
if ! test -f /tmp/artemis-symphony-promotion/promoted-source.json; then
  echo "scripts/artemis-symphony-remote-promotion.sh did not write promoted-source.json" >&2
  exit 1
fi
scripts/artemis-dry-run.sh --input /tmp/artemis-symphony-promotion/promoted-source.json --json >/tmp/artemis-symphony-promotion-dry-run.json
if ! grep -q '"eligible": 1' /tmp/artemis-symphony-promotion-dry-run.json; then
  echo "remote promotion promoted-source was not eligible as a local task source" >&2
  exit 1
fi
if ! grep -q '"event_type": "approval.resolved"' /tmp/artemis-symphony-promotion/events.json; then
  echo "scripts/artemis-symphony-remote-promotion.sh did not emit canonical approval event" >&2
  exit 1
fi
scripts/artemis-memory-zone.sh --artifact-root /tmp/artemis-memory-zone --json >/tmp/artemis-memory-zone.json
if ! grep -q '"overall": "memory_zone_ready"' /tmp/artemis-memory-zone.json; then
  echo "scripts/artemis-memory-zone.sh did not report memory_zone_ready" >&2
  exit 1
fi
if ! grep -q '"dependencies_installed": 0' /tmp/artemis-memory-zone.json; then
  echo "ARTEMIS Memory Zone installed dependencies during contract validation" >&2
  exit 1
fi
if ! grep -q '"indexes_built": 0' /tmp/artemis-memory-zone.json; then
  echo "ARTEMIS Memory Zone built indexes during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"embeddings_created": 0' /tmp/artemis-memory-zone.json; then
  echo "ARTEMIS Memory Zone created embeddings during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-memory-zone/events.json; then
  echo "scripts/artemis-memory-zone.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-project-graph.sh --artifact-root /tmp/artemis-project-graph --json >/tmp/artemis-project-graph.json
if ! grep -q '"overall": "project_graph_ready"' /tmp/artemis-project-graph.json; then
  echo "scripts/artemis-project-graph.sh did not report project_graph_ready" >&2
  exit 1
fi
if ! grep -q '"graph_database_started": false' /tmp/artemis-project-graph.json; then
  echo "ARTEMIS Project Graph started a graph database during contract validation" >&2
  exit 1
fi
if ! grep -q '"dependencies_installed": 0' /tmp/artemis-project-graph.json; then
  echo "ARTEMIS Project Graph installed dependencies during contract validation" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-project-graph.json; then
  echo "ARTEMIS Project Graph executed commands during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-project-graph/events.json; then
  echo "scripts/artemis-project-graph.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-project-graph-view.sh --artifact-root /tmp/artemis-project-graph-view --json >/tmp/artemis-project-graph-view.json
if ! grep -q '"overall": "project_graph_view_ready"' /tmp/artemis-project-graph-view.json; then
  echo "scripts/artemis-project-graph-view.sh did not report project_graph_view_ready" >&2
  exit 1
fi
if ! grep -q '"runtime_started": false' /tmp/artemis-project-graph-view.json; then
  echo "ARTEMIS Project Graph View started runtime during contract validation" >&2
  exit 1
fi
if ! grep -q '"dependencies_installed": 0' /tmp/artemis-project-graph-view.json; then
  echo "ARTEMIS Project Graph View installed dependencies during contract validation" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-project-graph-view.json; then
  echo "ARTEMIS Project Graph View executed commands during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-project-graph-view/events.json; then
  echo "scripts/artemis-project-graph-view.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-project-brief.sh --artifact-root /tmp/artemis-project-brief --json >/tmp/artemis-project-brief.json
if ! grep -q '"overall": "human_project_brief_ready"' /tmp/artemis-project-brief.json; then
  echo "scripts/artemis-project-brief.sh did not report human_project_brief_ready" >&2
  exit 1
fi
if ! grep -q '"runtime_started": false' /tmp/artemis-project-brief.json; then
  echo "ARTEMIS Project Brief started runtime during contract validation" >&2
  exit 1
fi
if ! grep -q '"dependencies_installed": 0' /tmp/artemis-project-brief.json; then
  echo "ARTEMIS Project Brief installed dependencies during contract validation" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-project-brief.json; then
  echo "ARTEMIS Project Brief executed commands during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-project-brief/events.json; then
  echo "scripts/artemis-project-brief.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-guided-collaboration.sh --artifact-root /tmp/artemis-guided-collaboration --json >/tmp/artemis-guided-collaboration.json
if ! grep -q '"overall": "guided_collaboration_ready"' /tmp/artemis-guided-collaboration.json; then
  echo "scripts/artemis-guided-collaboration.sh did not report guided_collaboration_ready" >&2
  exit 1
fi
if ! grep -q '"runtime_started": false' /tmp/artemis-guided-collaboration.json; then
  echo "ARTEMIS Guided Collaboration started runtime during contract validation" >&2
  exit 1
fi
if ! grep -q '"agents_started": 0' /tmp/artemis-guided-collaboration.json; then
  echo "ARTEMIS Guided Collaboration started agents during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-guided-collaboration.json; then
  echo "ARTEMIS Guided Collaboration allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-guided-collaboration.json; then
  echo "ARTEMIS Guided Collaboration executed commands during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-guided-collaboration/events.json; then
  echo "scripts/artemis-guided-collaboration.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-agent-launch-contract.sh --artifact-root /tmp/artemis-agent-launch-contract --json >/tmp/artemis-agent-launch-contract.json
if ! grep -q '"overall": "agent_launch_contract_ready"' /tmp/artemis-agent-launch-contract.json; then
  echo "scripts/artemis-agent-launch-contract.sh did not report agent_launch_contract_ready" >&2
  exit 1
fi
if ! grep -q '"execute_default": false' /tmp/artemis-agent-launch-contract.json; then
  echo "ARTEMIS Agent Launch Contract did not keep execute=false by default" >&2
  exit 1
fi
if ! grep -q '"runtime_started": false' /tmp/artemis-agent-launch-contract.json; then
  echo "ARTEMIS Agent Launch Contract started runtime during contract validation" >&2
  exit 1
fi
if ! grep -q '"agents_started": 0' /tmp/artemis-agent-launch-contract.json; then
  echo "ARTEMIS Agent Launch Contract started agents during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-agent-launch-contract.json; then
  echo "ARTEMIS Agent Launch Contract allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-agent-launch-contract.json; then
  echo "ARTEMIS Agent Launch Contract executed commands during read-only contract validation" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-agent-launch-contract/events.json; then
  echo "scripts/artemis-agent-launch-contract.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-agent-runtime-dry-run.sh --artifact-root /tmp/artemis-agent-runtime-dry-run --json >/tmp/artemis-agent-runtime-dry-run.json
if ! grep -q '"overall": "agent_runtime_dry_run_ready"' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "scripts/artemis-agent-runtime-dry-run.sh did not report agent_runtime_dry_run_ready" >&2
  exit 1
fi
if ! grep -q '"execute": false' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run did not keep execute=false" >&2
  exit 1
fi
if ! grep -q '"runtime_started": false' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run started runtime" >&2
  exit 1
fi
if ! grep -q '"agents_started": 0' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run started agents" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run executed commands" >&2
  exit 1
fi
if ! grep -q '"paid_tokens_authorized": 0' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run authorized paid tokens" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-agent-runtime-dry-run.json; then
  echo "ARTEMIS Agent Runtime Dry-Run allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"event_type": "runner.attempt_planned"' /tmp/artemis-agent-runtime-dry-run/events.json; then
  echo "scripts/artemis-agent-runtime-dry-run.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-agent-runtime-approval-gate.sh --artifact-root /tmp/artemis-agent-runtime-approval-gate --dry-run /tmp/artemis-agent-runtime-dry-run/runtime-dry-run.json --json >/tmp/artemis-agent-runtime-approval-gate.json
if ! grep -q '"overall": "agent_runtime_approval_gate_ready"' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "scripts/artemis-agent-runtime-approval-gate.sh did not report agent_runtime_approval_gate_ready" >&2
  exit 1
fi
if ! grep -q '"decision": "pending"' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate did not preserve pending decision" >&2
  exit 1
fi
if ! grep -q '"runtime_execution_allowed": false' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate allowed runtime execution" >&2
  exit 1
fi
if ! grep -q '"execute": false' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate did not keep execute=false" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate executed commands" >&2
  exit 1
fi
if ! grep -q '"paid_tokens_authorized": 0' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate authorized paid tokens" >&2
  exit 1
fi
if ! grep -q '"remote_writes_allowed": false' /tmp/artemis-agent-runtime-approval-gate.json; then
  echo "ARTEMIS Agent Runtime Approval Gate allowed remote writes" >&2
  exit 1
fi
if ! grep -q '"event_type": "approval.requested"' /tmp/artemis-agent-runtime-approval-gate/events.json; then
  echo "scripts/artemis-agent-runtime-approval-gate.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-agent-runtime-decision-intake.sh --artifact-root /tmp/artemis-agent-runtime-decision-intake --approval-gate /tmp/artemis-agent-runtime-approval-gate/runtime-approval-gate.json --decision /tmp/artemis-agent-runtime-approval-gate/runtime-approval-decision.json --json >/tmp/artemis-agent-runtime-decision-intake.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-agent-runtime-decision-intake.json; then
  echo "scripts/artemis-agent-runtime-decision-intake.sh did not preserve pending Human Gate" >&2
  exit 1
fi
if ! grep -q '"intake_state": "pending"' /tmp/artemis-agent-runtime-decision-intake.json; then
  echo "ARTEMIS Agent Runtime Decision Intake did not classify pending decision" >&2
  exit 1
fi
if ! grep -q '"launcher_preflight_allowed": false' /tmp/artemis-agent-runtime-decision-intake.json; then
  echo "ARTEMIS Agent Runtime Decision Intake allowed launcher preflight without approved_ready" >&2
  exit 1
fi
if ! grep -q '"runtime_execution_allowed": false' /tmp/artemis-agent-runtime-decision-intake.json; then
  echo "ARTEMIS Agent Runtime Decision Intake allowed runtime execution" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-agent-runtime-decision-intake.json; then
  echo "ARTEMIS Agent Runtime Decision Intake executed commands" >&2
  exit 1
fi
if ! grep -q '"event_type": "approval.intake_recorded"' /tmp/artemis-agent-runtime-decision-intake/events.json; then
  echo "scripts/artemis-agent-runtime-decision-intake.sh did not emit canonical events" >&2
  exit 1
fi
scripts/artemis-agent-runtime-launcher-preflight.sh --artifact-root /tmp/artemis-agent-runtime-launcher-preflight --decision-intake /tmp/artemis-agent-runtime-decision-intake/runtime-decision-intake.json --json >/tmp/artemis-agent-runtime-launcher-preflight.json
if ! grep -q '"overall": "human_gate"' /tmp/artemis-agent-runtime-launcher-preflight.json; then
  echo "scripts/artemis-agent-runtime-launcher-preflight.sh did not preserve pending Human Gate" >&2
  exit 1
fi
if ! grep -q '"preflight_state": "waiting_for_approved_ready"' /tmp/artemis-agent-runtime-launcher-preflight.json; then
  echo "ARTEMIS Agent Runtime Launcher Preflight did not wait for approved_ready" >&2
  exit 1
fi
if ! grep -q '"launcher_execution_allowed": false' /tmp/artemis-agent-runtime-launcher-preflight.json; then
  echo "ARTEMIS Agent Runtime Launcher Preflight allowed launcher execution" >&2
  exit 1
fi
if ! grep -q '"runtime_execution_allowed": false' /tmp/artemis-agent-runtime-launcher-preflight.json; then
  echo "ARTEMIS Agent Runtime Launcher Preflight allowed runtime execution" >&2
  exit 1
fi
if ! grep -q '"commands_executed": 0' /tmp/artemis-agent-runtime-launcher-preflight.json; then
  echo "ARTEMIS Agent Runtime Launcher Preflight executed commands" >&2
  exit 1
fi
if ! grep -q '"event_type": "runner.preflight_recorded"' /tmp/artemis-agent-runtime-launcher-preflight/events.json; then
  echo "scripts/artemis-agent-runtime-launcher-preflight.sh did not emit canonical events" >&2
  exit 1
fi

scripts/artemis-codex-app-server.sh --artifact-root /tmp/artemis-codex-app-server --json >/tmp/artemis-codex-app-server.json
if ! grep -q '"overall": "passed"' /tmp/artemis-codex-app-server.json; then
  echo "scripts/artemis-codex-app-server.sh did not report the expected passed status" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-codex-app-server/events.json; then
  echo "scripts/artemis-codex-app-server.sh did not emit canonical events" >&2
  exit 1
fi

scripts/artemis-claude-code.sh --artifact-root /tmp/artemis-claude-code --json >/tmp/artemis-claude-code.json
if ! grep -q '"overall": "passed"' /tmp/artemis-claude-code.json; then
  echo "scripts/artemis-claude-code.sh did not report the expected passed status" >&2
  exit 1
fi
if ! grep -q '"event_type": "adapter.contract_recorded"' /tmp/artemis-claude-code/events.json; then
  echo "scripts/artemis-claude-code.sh did not emit canonical events" >&2
  exit 1
fi

scripts/artemis-event-log.sh --artifact-root /tmp/artemis-event-log --json >/tmp/artemis-event-log.json
if ! grep -q '"event_type": "validation.completed"' /tmp/artemis-event-log.json; then
  echo "scripts/artemis-event-log.sh did not emit expected validation event" >&2
  exit 1
fi

if ! grep -q "ARTEMIS Control Plane" control-plane/index.html; then
  echo "control-plane/index.html does not look like the ARTEMIS Control Plane" >&2
  exit 1
fi
if ! grep -q 'id="symphony-evidence"' control-plane/index.html; then
  echo "control-plane/index.html does not expose ARTEMIS Symphony evidence" >&2
  exit 1
fi
if ! grep -q "runner_plan_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony bridge runner plan" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-bridge/run-01/symphony-bridge.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony bridge artifact" >&2
  exit 1
fi
if ! grep -q "20260507T180318Z-26-tkt-903" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony runner attempt" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony daemon artifact" >&2
  exit 1
fi
if ! grep -q "heartbeat_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony daemon heartbeat" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-queue/run-01/symphony-queue.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony queue artifact" >&2
  exit 1
fi
if ! grep -q "queue_empty" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony queue state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-queue-bridge/run-01/queue-bridge.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony queue bridge artifact" >&2
  exit 1
fi
if ! grep -q "bridge_plan_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony queue bridge state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-queue-execution/run-01/queue-bridge.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony queue execution artifact" >&2
  exit 1
fi
if ! grep -q "runner_executed" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony queue execution state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-service/run-01/symphony-service.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony service artifact" >&2
  exit 1
fi
if ! grep -q "service_bridge_plan_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony service state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-remote-source/run-01/remote-source.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony remote source artifact" >&2
  exit 1
fi
if ! grep -q "remote_source_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony remote source state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony remote intake artifact" >&2
  exit 1
fi
if ! grep -q "remote_intake_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony remote intake state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-symphony-promotion/run-01/remote-promotion.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the Symphony remote promotion artifact" >&2
  exit 1
fi
if ! grep -q "remote_promotion_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the Symphony remote promotion state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-memory-zone/run-01/memory-zone.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the ARTEMIS Memory Zone artifact" >&2
  exit 1
fi
if ! grep -q "memory_zone_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Memory Zone state" >&2
  exit 1
fi
if ! grep -q "artifacts/artemis-project-graph/run-01/project-graph.json" control-plane/index.html; then
  echo "control-plane/index.html does not link the ARTEMIS Project Graph artifact" >&2
  exit 1
fi
if ! grep -q "project_graph_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Project Graph state" >&2
  exit 1
fi
if ! grep -q "project-graph-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Project Graph section" >&2
  exit 1
fi
if ! grep -q "renderProjectGraph" control-plane/index.html; then
  echo "control-plane/index.html does not include the Project Graph renderer" >&2
  exit 1
fi
if ! grep -q "project_graph_view_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Project Graph View state" >&2
  exit 1
fi
if ! grep -q "project-brief-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Project Brief section" >&2
  exit 1
fi
if ! grep -q "renderProjectBrief" control-plane/index.html; then
  echo "control-plane/index.html does not include the Project Brief renderer" >&2
  exit 1
fi
if ! grep -q "human_project_brief_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Project Brief state" >&2
  exit 1
fi
if ! grep -q "guided-collaboration-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Guided Collaboration section" >&2
  exit 1
fi
if ! grep -q "renderGuidedCollaboration" control-plane/index.html; then
  echo "control-plane/index.html does not include the Guided Collaboration renderer" >&2
  exit 1
fi
if ! grep -q "guided_collaboration_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Guided Collaboration state" >&2
  exit 1
fi
if ! grep -q "agent-launch-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Agent Launch Contract section" >&2
  exit 1
fi
if ! grep -q "renderAgentLaunchContract" control-plane/index.html; then
  echo "control-plane/index.html does not include the Agent Launch Contract renderer" >&2
  exit 1
fi
if ! grep -q "agent_launch_contract_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Agent Launch Contract state" >&2
  exit 1
fi
if ! grep -q "agent-runtime-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Agent Runtime Dry-Run section" >&2
  exit 1
fi
if ! grep -q "renderAgentRuntimeDryRun" control-plane/index.html; then
  echo "control-plane/index.html does not include the Agent Runtime Dry-Run renderer" >&2
  exit 1
fi
if ! grep -q "agent_runtime_dry_run_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Agent Runtime Dry-Run state" >&2
  exit 1
fi
if ! grep -q "agent-runtime-approval-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Agent Runtime Approval Gate section" >&2
  exit 1
fi
if ! grep -q "renderAgentRuntimeApprovalGate" control-plane/index.html; then
  echo "control-plane/index.html does not include the Agent Runtime Approval Gate renderer" >&2
  exit 1
fi
if ! grep -q "agent_runtime_approval_gate_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Agent Runtime Approval Gate state" >&2
  exit 1
fi
if ! grep -q "agent-runtime-decision-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Agent Runtime Decision Intake section" >&2
  exit 1
fi
if ! grep -q "renderAgentRuntimeDecisionIntake" control-plane/index.html; then
  echo "control-plane/index.html does not include the Agent Runtime Decision Intake renderer" >&2
  exit 1
fi
if ! grep -q "human_gate" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Agent Runtime Decision Intake state" >&2
  exit 1
fi
if ! grep -q "agent-runtime-launcher-preflight-section" control-plane/index.html; then
  echo "control-plane/index.html does not render the ARTEMIS Agent Runtime Launcher Preflight section" >&2
  exit 1
fi
if ! grep -q "renderAgentRuntimeLauncherPreflight" control-plane/index.html; then
  echo "control-plane/index.html does not include the Agent Runtime Launcher Preflight renderer" >&2
  exit 1
fi
if ! grep -q "waiting_for_approved_ready" control-plane/index.html; then
  echo "control-plane/index.html does not show the ARTEMIS Agent Runtime Launcher Preflight state" >&2
  exit 1
fi

echo "ARTEMIS validation passed"
