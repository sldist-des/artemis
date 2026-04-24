#!/usr/bin/env sh
set -eu

required_files="
AGENTS.md
CLAUDE.md
ARCHITECTURE.md
AI_PROCESS.md
README.md
ARTEMIS_QUICKSTART.md
docs/invariants/core.md
docs/agents/AGENT_REGISTRY.md
docs/agents/CAPABILITY_REGISTRY.md
docs/agents/TOOL_POLICY.md
docs/agents/HANDOFF_PROTOCOL.md
docs/runbooks/github-setup.md
templates/AGENTS.md
templates/CLAUDE.md
templates/AI_PROCESS.md
templates/docs/exec-packs/TEMPLATE.md
prompts/context-curator.md
prompts/implementer.md
prompts/reviewer.md
scripts/bootstrap-artemis.sh
scripts/github-readiness.sh
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
sh -n scripts/validate-artemis.sh

echo "ARTEMIS validation passed"
