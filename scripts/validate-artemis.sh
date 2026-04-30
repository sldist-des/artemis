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

if ! grep -q "ARTEMIS Control Plane" control-plane/index.html; then
  echo "control-plane/index.html does not look like the ARTEMIS Control Plane" >&2
  exit 1
fi

echo "ARTEMIS validation passed"
