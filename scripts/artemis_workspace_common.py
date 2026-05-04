from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import Any


def slug(value: str, *, fallback: str = "task", max_length: int = 48) -> str:
    normalized = re.sub(r"[^A-Za-z0-9_.-]+", "-", value.lower()).strip("-")
    normalized = re.sub(r"-+", "-", normalized)
    return (normalized or fallback)[:max_length].strip("-") or fallback


def normalize_artifact_root(evidence: str, ticket: str) -> str:
    value = str(evidence or "").strip()
    if value.endswith("/STATUS.md"):
        value = value[: -len("/STATUS.md")]
    elif value.endswith(".md"):
        value = os.path.dirname(value)
    if not value or not value.startswith("artifacts/"):
        value = f"artifacts/{slug(ticket)}/run-01"
    return value.rstrip("/")


def _git(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def _check(name: str, status: str, reason: str, **extra: Any) -> dict[str, Any]:
    payload: dict[str, Any] = {"name": name, "status": status, "reason": reason}
    payload.update(extra)
    return payload


def plan_workspace(task: dict[str, Any], *, repo_root: str | Path | None = None) -> dict[str, Any]:
    root = Path(repo_root or Path.cwd())
    repo_name = root.name or "repo"

    ticket = str(task.get("ticket") or task.get("id") or "TASK")
    title = str(task.get("title") or "task")
    state = str(task.get("state") or "").lower()
    owner = str(task.get("owner") or "")
    risk = str(task.get("risk") or "medium").lower()
    exec_pack = str(task.get("exec_pack") or "")
    evidence = str(task.get("evidence") or "")

    safe_ticket = slug(ticket)
    title_slug = slug(title, fallback="task", max_length=36)
    branch = f"artemis/{safe_ticket}-{title_slug}"
    worktree_path = f"../{repo_name}-artemis-worktrees/{safe_ticket}"
    lock_path = f".artemis/locks/{safe_ticket}.lock"
    artifact_root = normalize_artifact_root(evidence, safe_ticket)

    checks: list[dict[str, Any]] = []
    checks.append(
        _check(
            "task_state",
            "passed" if state in {"ready", "context", "intake"} else "blocked",
            f"state={state or 'unknown'}",
        )
    )
    checks.append(
        _check(
            "owner",
            "passed" if owner else "blocked",
            "writer owner is declared" if owner else "writer owner is missing",
        )
    )
    checks.append(
        _check(
            "risk",
            "passed" if risk in {"low", "medium", "high"} else "blocked",
            f"risk={risk or 'unknown'}",
        )
    )
    checks.append(
        _check(
            "exec_pack",
            "passed" if exec_pack else "blocked",
            "Exec Pack is declared" if exec_pack else "Exec Pack is missing",
            path=exec_pack,
        )
    )
    if exec_pack:
        checks.append(
            _check(
                "exec_pack_file",
                "passed" if (root / exec_pack).is_file() else "warning",
                "Exec Pack file exists" if (root / exec_pack).is_file() else "Exec Pack file is not present locally",
                path=exec_pack,
            )
        )
    checks.append(
        _check(
            "artifact_root",
            "passed" if artifact_root.startswith("artifacts/") else "blocked",
            f"artifact_root={artifact_root}",
            path=artifact_root,
        )
    )

    lock_exists = (root / lock_path).exists()
    checks.append(
        _check(
            "writer_lock",
            "human_gate" if lock_exists else "passed",
            "existing lock requires owner confirmation" if lock_exists else "no existing writer lock",
            path=lock_path,
        )
    )

    worktree_exists = (root / worktree_path).exists()
    checks.append(
        _check(
            "worktree_path",
            "human_gate" if worktree_exists else "passed",
            "planned worktree path already exists" if worktree_exists else "planned worktree path is free",
            path=worktree_path,
        )
    )

    branch_ref = f"refs/heads/{branch}"
    branch_exists = _git(root, "show-ref", "--verify", "--quiet", branch_ref).returncode == 0
    checks.append(
        _check(
            "branch",
            "warning" if branch_exists else "passed",
            "branch already exists and must be inspected before reuse" if branch_exists else "planned branch is new",
            name_ref=branch,
        )
    )

    worktree_list = _git(root, "worktree", "list", "--porcelain")
    branch_in_worktree = f"branch {branch_ref}" in worktree_list.stdout
    checks.append(
        _check(
            "branch_worktree_occupancy",
            "human_gate" if branch_in_worktree else "passed",
            "planned branch is already checked out in a worktree" if branch_in_worktree else "planned branch is not checked out elsewhere",
            name_ref=branch,
        )
    )

    status = _git(root, "status", "--porcelain")
    dirty_count = len([line for line in status.stdout.splitlines() if line.strip()])
    checks.append(
        _check(
            "current_worktree_dirty",
            "warning" if dirty_count else "passed",
            f"current worktree has {dirty_count} pending item(s)" if dirty_count else "current worktree is clean",
            dirty_count=dirty_count,
        )
    )

    readiness = "ready"
    reason = "Workspace can be planned without creating a worktree."
    if any(item["status"] == "blocked" for item in checks):
        readiness = "blocked"
        reason = next(item["reason"] for item in checks if item["status"] == "blocked")
    elif any(item["status"] == "human_gate" for item in checks):
        readiness = "human_gate"
        reason = next(item["reason"] for item in checks if item["status"] == "human_gate")

    workspace_mode = "materialized" if lock_exists or worktree_exists else "planned"
    cleanup_state = "active" if lock_exists or worktree_exists else "not_created"

    return {
        "ticket": ticket,
        "task_id": safe_ticket,
        "title": title,
        "readiness": readiness,
        "reason": reason,
        "workspace": {
            "mode": workspace_mode,
            "branch": branch,
            "worktree_path": worktree_path,
            "lock_path": lock_path,
            "artifact_root": artifact_root,
            "writer": owner or "unassigned",
            "cleanup_state": cleanup_state,
        },
        "checks": checks,
    }


def summarize(plans: list[dict[str, Any]]) -> dict[str, int]:
    return {
        "ready": sum(1 for item in plans if item["readiness"] == "ready"),
        "blocked": sum(1 for item in plans if item["readiness"] == "blocked"),
        "human_gate": sum(1 for item in plans if item["readiness"] == "human_gate"),
    }
