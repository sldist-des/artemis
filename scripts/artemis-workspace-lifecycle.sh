#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
format="text"

usage() {
  echo "usage: scripts/artemis-workspace-lifecycle.sh [--artifact-root path] [--json]" >&2
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

payload=$(python3 - <<'PY'
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

root = Path.cwd()
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def git(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def rel(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(root))
    except ValueError:
        return str(path)


def parse_worktrees() -> list[dict[str, str]]:
    result = git("worktree", "list", "--porcelain")
    entries: list[dict[str, str]] = []
    current: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if not line.strip():
            if current:
                entries.append(current)
                current = {}
            continue
        key, _, value = line.partition(" ")
        if key == "worktree" and current:
            entries.append(current)
            current = {}
        current[key] = value
    if current:
        entries.append(current)
    return entries


def worktree_status(path: Path) -> dict[str, object]:
    result = subprocess.run(
        ["git", "-C", str(path), "status", "--porcelain"],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    return {
        "exit_code": result.returncode,
        "dirty_count": len(lines) if result.returncode == 0 else None,
        "dirty": bool(lines) if result.returncode == 0 else None,
        "error": result.stderr.strip(),
    }


def branch_exists(branch: str) -> bool:
    return git("show-ref", "--verify", "--quiet", f"refs/heads/{branch}").returncode == 0


def branch_merged(branch: str) -> bool | None:
    if not branch_exists(branch):
        return None
    return git("merge-base", "--is-ancestor", branch, "HEAD").returncode == 0


worktrees = parse_worktrees()
worktree_by_branch = {
    item.get("branch", "").removeprefix("refs/heads/"): item
    for item in worktrees
    if item.get("branch")
}
worktree_by_path = {str(Path(item["worktree"]).resolve()): item for item in worktrees if item.get("worktree")}

locks = []
lock_dir = root / ".artemis" / "locks"
for lock_path in sorted(lock_dir.glob("*.lock")) if lock_dir.is_dir() else []:
    try:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
        parse_error = ""
    except (OSError, json.JSONDecodeError) as exc:
        lock = {}
        parse_error = str(exc)

    ticket = str(lock.get("ticket") or lock_path.stem.upper())
    branch = str(lock.get("branch") or "")
    worktree_path_raw = str(lock.get("worktree_path") or "")
    worktree_path = (root / worktree_path_raw).resolve() if worktree_path_raw else Path()
    artifact_root = str(lock.get("artifact_root") or "")
    artifact_path = root / artifact_root if artifact_root else Path()

    branch_present = branch_exists(branch) if branch else False
    branch_is_merged = branch_merged(branch) if branch else None
    worktree_present = worktree_path.is_dir() if worktree_path_raw else False
    worktree_entry = worktree_by_branch.get(branch) or worktree_by_path.get(str(worktree_path))
    artifact_present = artifact_path.is_dir() if artifact_root else False
    status_present = (artifact_path / "STATUS.md").is_file() if artifact_root else False
    status = worktree_status(worktree_path) if worktree_present else {
        "exit_code": None,
        "dirty_count": None,
        "dirty": None,
        "error": "",
    }

    reasons: list[str] = []
    review_checks = [
        not parse_error,
        branch_present,
        worktree_present,
        bool(worktree_entry),
        artifact_present,
        status_present,
        status.get("dirty") is False,
        branch_is_merged is True,
    ]
    if parse_error:
        reasons.append("lock file could not be parsed")
    if not branch_present:
        reasons.append("branch is missing locally")
    if not worktree_present:
        reasons.append("worktree path is missing")
    if not worktree_entry:
        reasons.append("worktree is not registered by git")
    if not artifact_present:
        reasons.append("artifact root is missing")
    if not status_present:
        reasons.append("artifact root has no STATUS.md")
    if status.get("dirty") is True:
        reasons.append("worktree has pending changes")
    if branch_present and branch_is_merged is False:
        reasons.append("branch is not merged into current main worktree HEAD")

    if all(review_checks):
        lifecycle_state = "review_ready"
        cleanup_decision = "human_review_before_cleanup"
        reasons = ["branch is merged, worktree is clean, lock and artifacts are present"]
    elif parse_error or not branch_present or not worktree_present or status.get("dirty") is True:
        lifecycle_state = "decision_required"
        cleanup_decision = "inspect_before_cleanup"
    else:
        lifecycle_state = "active"
        cleanup_decision = "keep_workspace"
        if not reasons:
            reasons = ["workspace still appears active"]

    locks.append({
        "ticket": ticket,
        "title": lock.get("title", ""),
        "writer": lock.get("writer", ""),
        "lock_path": rel(lock_path),
        "lock_parse_error": parse_error,
        "branch": branch,
        "branch_exists": branch_present,
        "branch_merged_into_head": branch_is_merged,
        "worktree_path": worktree_path_raw,
        "worktree_exists": worktree_present,
        "worktree_registered": bool(worktree_entry),
        "worktree_head": worktree_entry.get("HEAD") if worktree_entry else None,
        "artifact_root": artifact_root,
        "artifact_root_exists": artifact_present,
        "status_md_exists": status_present,
        "dirty": status.get("dirty"),
        "dirty_count": status.get("dirty_count"),
        "lifecycle_state": lifecycle_state,
        "cleanup_decision": cleanup_decision,
        "reason": "; ".join(reasons),
    })

artemis_worktrees = [
    {
        "path": item.get("worktree"),
        "branch": item.get("branch", "").removeprefix("refs/heads/"),
        "head": item.get("HEAD"),
    }
    for item in worktrees
    if "artemis" in item.get("worktree", "") or "artemis/" in item.get("branch", "")
]

summary = {
    "locks": len(locks),
    "worktrees": len(artemis_worktrees),
    "active": sum(1 for item in locks if item["lifecycle_state"] == "active"),
    "review_ready": sum(1 for item in locks if item["lifecycle_state"] == "review_ready"),
    "decision_required": sum(1 for item in locks if item["lifecycle_state"] == "decision_required"),
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-workspace-lifecycle.sh",
    "mode": "read_only",
    "summary": summary,
    "locks": locks,
    "artemis_worktrees": artemis_worktrees,
    "review_criteria": [
        "Never remove a worktree or lock automatically.",
        "Review-ready means branch is already merged into current HEAD, worktree is clean, lock exists, and artifact STATUS.md exists.",
        "Decision-required means missing metadata, missing branch/worktree, dirty worktree, or unreadable lock.",
        "Active means the workspace should stay available until its branch and handoff are reviewed.",
    ],
}

print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/workspace-lifecycle.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "workspace-lifecycle.json").read_text(encoding="utf-8"))
summary = payload["summary"]

lines = [
    "# ARTEMIS WORKSPACE LIFECYCLE INVENTORY",
    "",
    f"- Generated at: {payload['generated_at']}",
    f"- Mode: `{payload['mode']}`",
    f"- Locks: {summary['locks']}",
    f"- ARTEMIS worktrees: {summary['worktrees']}",
    f"- Active: {summary['active']}",
    f"- Review ready: {summary['review_ready']}",
    f"- Decision required: {summary['decision_required']}",
    "",
    "## Workspaces",
    "",
]

for item in payload["locks"]:
    lines.extend([
        f"### {item['ticket']} - {item['lifecycle_state']}",
        "",
        f"- Title: {item['title']}",
        f"- Writer: {item['writer']}",
        f"- Branch: `{item['branch']}` (exists: {item['branch_exists']}, merged into HEAD: {item['branch_merged_into_head']})",
        f"- Worktree: `{item['worktree_path']}` (exists: {item['worktree_exists']}, registered: {item['worktree_registered']})",
        f"- Lock: `{item['lock_path']}`",
        f"- Artifact root: `{item['artifact_root']}` (exists: {item['artifact_root_exists']}, STATUS.md: {item['status_md_exists']})",
        f"- Dirty count: {item['dirty_count']}",
        f"- Cleanup decision: `{item['cleanup_decision']}`",
        f"- Reason: {item['reason']}",
        "",
    ])

lines.extend([
    "## Review Criteria",
    "",
])
for criterion in payload["review_criteria"]:
    lines.append(f"- {criterion}")

(root / "WORKSPACE_LIFECYCLE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
summary = payload["summary"]
print("ARTEMIS Workspace Lifecycle Inventory")
print(
    "summary: "
    f"locks={summary['locks']} "
    f"worktrees={summary['worktrees']} "
    f"active={summary['active']} "
    f"review_ready={summary['review_ready']} "
    f"decision_required={summary['decision_required']}"
)
print("")
for item in payload["locks"]:
    print(f"- {item['ticket']} [{item['lifecycle_state']}]")
    print(f"  branch: {item['branch']} (exists={item['branch_exists']}, merged={item['branch_merged_into_head']})")
    print(f"  worktree: {item['worktree_path']} (exists={item['worktree_exists']}, registered={item['worktree_registered']})")
    print(f"  artifact_root: {item['artifact_root']} (status={item['status_md_exists']})")
    print(f"  cleanup_decision: {item['cleanup_decision']}")
    print(f"  reason: {item['reason']}")
PY
fi
