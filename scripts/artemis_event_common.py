from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def event(
    *,
    event_id: str,
    event_type: str,
    generated_at: str,
    producer: dict[str, Any],
    ticket: str,
    title: str,
    exec_pack: str,
    artifact_root: str,
    state_to: str,
    payload: dict[str, Any],
    state_from: str | None = None,
    runner: dict[str, Any] | None = None,
    gate: dict[str, Any] | None = None,
    severity: str = "info",
    links: dict[str, Any] | None = None,
    logs: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "event_id": event_id,
        "event_type": event_type,
        "generated_at": generated_at,
        "producer": producer,
        "subject": {
            "ticket": ticket,
            "task_id": ticket.lower(),
            "title": title,
            "exec_pack": exec_pack,
            "artifact_root": artifact_root,
        },
        "runner": runner or {"kind": "none"},
        "state": {
            "from": state_from,
            "to": state_to,
            "reason": str(payload.get("reason", "")),
        },
        "gate": gate or {"kind": "none", "status": "not_applicable"},
        "severity": severity,
        "evidence": {
            "artifact_path": artifact_root,
            "status_path": f"{artifact_root}/STATUS.md",
            "validation_path": f"{artifact_root}/VALIDATION.md",
            "handoff_path": f"{artifact_root}/HANDOFF.md",
            "logs": logs or [],
        },
        "links": links or {"correlation_id": ticket.lower()},
        "payload": payload,
    }


def event_log(*, source: str, generated_at: str, events: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "generated_at": generated_at,
        "source": source,
        "events": events,
    }


def write_event_log(path: str | Path, payload: dict[str, Any]) -> None:
    Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_json(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))
