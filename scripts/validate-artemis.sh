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
.impeccable.md
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
if ! grep -q '"workspace": {' /tmp/artemis-dry-run.json; then
  echo "scripts/artemis-dry-run.sh did not include workspace readiness for eligible work" >&2
  exit 1
fi

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

echo "ARTEMIS validation passed"
