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
scripts/artemis-runner.sh
scripts/artemis-validation-gate.sh
scripts/artemis-github-issues.sh
scripts/artemis-codex-app-server.sh
scripts/artemis-claude-code.sh
scripts/artemis-event-log.sh
scripts/artemis_event_common.py
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
scripts/artemis-runner.sh --input /tmp/artemis-runner-task-source.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input /tmp/artemis-runner-task-source.json" --artifact-root /tmp/artemis-runner-validation >/tmp/artemis-runner.out
if ! grep -q '/tmp/artemis-runner-validation/attempts/' /tmp/artemis-runner.out; then
  echo "scripts/artemis-runner.sh did not create a supervised attempt artifact" >&2
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
