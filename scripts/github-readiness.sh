#!/usr/bin/env sh
set -eu

status=0

say_ok() {
  echo "ok: $1"
}

say_warn() {
  echo "warn: $1"
}

say_fail() {
  echo "fail: $1" >&2
  status=1
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say_ok "inside git worktree"
else
  say_fail "not inside git worktree"
fi

branch=$(git branch --show-current 2>/dev/null || true)
if [ "$branch" = "main" ]; then
  say_ok "current branch is main"
else
  say_fail "current branch is '$branch', expected main"
fi

if [ -z "$(git status --porcelain)" ]; then
  say_ok "working tree is clean"
else
  say_fail "working tree has uncommitted changes"
fi

if git remote get-url origin >/dev/null 2>&1; then
  say_ok "origin remote configured: $(git remote get-url origin)"
else
  say_warn "origin remote is not configured yet"
fi

if command -v gh >/dev/null 2>&1; then
  say_ok "gh is installed: $(gh --version | sed -n '1p')"
  if gh auth status >/tmp/artemis-gh-auth.out 2>&1; then
    say_ok "gh auth status passed"
  else
    say_warn "gh auth status did not pass"
    sed 's/^/  /' /tmp/artemis-gh-auth.out
  fi
else
  say_fail "gh is not installed"
fi

if [ -f ".github/workflows/ci.yml" ]; then
  say_ok "GitHub CI workflow exists"
else
  say_fail ".github/workflows/ci.yml is missing"
fi

if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
  say_ok "pull request template exists"
else
  say_fail "pull request template is missing"
fi

if [ -f ".github/ISSUE_TEMPLATE/artemis_task.yml" ]; then
  say_ok "ARTEMIS issue template exists"
else
  say_fail "ARTEMIS issue template is missing"
fi

if [ -f ".github/CODEOWNERS" ]; then
  if grep -v '^#' .github/CODEOWNERS | grep -q '@'; then
    say_ok "CODEOWNERS has active owner entries"
  else
    say_warn "CODEOWNERS has no active owner entries yet"
  fi
else
  say_fail "CODEOWNERS is missing"
fi

exit "$status"
