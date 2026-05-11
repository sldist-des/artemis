#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-symphony-remote-source/run-01"
github_artifact=""
label="artemis"
limit="50"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-remote-source.sh [--artifact-root path] [--github-artifact path] [--label label] [--limit n] [--json]

Builds a supervised ARTEMIS Symphony remote source from the read-only GitHub
Issues adapter. The output is evidence/intake only; it never writes remotely and
never authorizes runner execution.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --github-artifact)
      github_artifact="${2:-}"
      if [ -z "$github_artifact" ]; then usage; exit 2; fi
      shift 2
      ;;
    --label)
      label="${2:-}"
      if [ -z "$label" ]; then usage; exit 2; fi
      shift 2
      ;;
    --limit)
      limit="${2:-}"
      if [ -z "$limit" ]; then usage; exit 2; fi
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

case "$limit" in
  ''|*[!0-9]*)
    echo "--limit must be a non-negative integer" >&2
    exit 2
    ;;
esac

mkdir -p "$artifact_root"

if [ -z "$github_artifact" ]; then
  mkdir -p "$artifact_root/github"
  set +e
  scripts/artemis-github-issues.sh \
    --artifact-root "$artifact_root/github" \
    --label "$label" \
    --limit "$limit" \
    --json >"$artifact_root/github.stdout.json" 2>"$artifact_root/github.stderr.txt"
  github_status=$?
  set -e
  if [ "$github_status" -eq 0 ] && [ -f "$artifact_root/github/github-issues.json" ]; then
    github_artifact="$artifact_root/github/github-issues.json"
  elif [ -s "$artifact_root/github.stdout.json" ]; then
    github_artifact="$artifact_root/github.stdout.json"
  else
    github_artifact="$artifact_root/github/github-issues.json"
  fi
fi

python3 - "$artifact_root" "$github_artifact" "$label" "$limit" "$format" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

artifact_root = Path(sys.argv[1])
github_artifact = Path(sys.argv[2])
label = sys.argv[3]
limit = int(sys.argv[4])
output_format = sys.argv[5]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


def label_names(issue):
    names = []
    for label_item in issue.get("labels") or []:
        if isinstance(label_item, dict):
            name = str(label_item.get("name") or "").strip()
        else:
            name = str(label_item).strip()
        if name:
            names.append(name)
    return names


def first_assignee(issue):
    assignees = issue.get("assignees") or []
    if not assignees:
        return "Humano"
    first = assignees[0]
    if isinstance(first, dict):
        return str(first.get("login") or first.get("name") or "Humano")
    return str(first)


def issue_ticket(issue):
    title = str(issue.get("title") or "")
    match = re.search(r"\bTKT-\d+\b", title, re.IGNORECASE)
    if match:
        return match.group(0).upper()
    number = issue.get("number")
    return f"REMOTE-{number}" if number is not None else "REMOTE-UNKNOWN"


def issue_risk(labels):
    for name in labels:
        lower = name.lower()
        if lower in {"risk:low", "artemis:risk:low"}:
            return "low"
        if lower in {"risk:medium", "artemis:risk:medium"}:
            return "medium"
        if lower in {"risk:high", "artemis:risk:high"}:
            return "high"
    return "medium"


def exec_pack_from_labels(labels):
    prefixes = ("exec-pack:", "artemis:exec-pack:")
    for name in labels:
        lower = name.lower()
        for prefix in prefixes:
            if lower.startswith(prefix):
                return name[len(prefix):].replace("__", "/")
    return ""


def mapped_state(issue, labels, exec_pack):
    lowered = {name.lower() for name in labels}
    gh_state = str(issue.get("state") or "").lower()
    if gh_state == "closed" or "artemis:done" in lowered:
        return "done"
    if "artemis:blocked" in lowered:
        return "blocked"
    if "artemis:human-gate" in lowered:
        return "human"
    if "artemis:ready" in lowered and exec_pack:
        return "intake"
    if "artemis:intake" in lowered:
        return "intake"
    return "human"


generated_at = now_utc()
artifact_root.mkdir(parents=True, exist_ok=True)
errors = []

try:
    github_payload = json.loads(github_artifact.read_text(encoding="utf-8"))
except FileNotFoundError:
    github_payload = {}
    errors.append(f"missing GitHub Issues artifact: {github_artifact}")
except json.JSONDecodeError as exc:
    github_payload = {}
    errors.append(f"invalid GitHub Issues artifact: {exc}")

github_overall = github_payload.get("overall", "failed")
github_reason = github_payload.get("reason", "GitHub Issues artifact unavailable.")
repo = github_payload.get("repo", "")
issues = github_payload.get("issues") or []
tasks = []
source_items = []

if not errors and github_overall == "passed":
    for issue in issues:
        labels = label_names(issue)
        exec_pack = exec_pack_from_labels(labels)
        ticket = issue_ticket(issue)
        state = mapped_state(issue, labels, exec_pack)
        issue_url = str(issue.get("url") or "")
        title = str(issue.get("title") or ticket)
        summary = "Issue imported as supervised intake. Local Exec Pack remains the execution contract."
        if not exec_pack:
            summary = "Issue requires local Exec Pack binding before any dispatch review."
        evidence = str(artifact_root / "STATUS.md")
        task = {
            "id": ticket.lower(),
            "ticket": ticket,
            "title": title,
            "state": state,
            "owner": first_assignee(issue),
            "risk": issue_risk(labels),
            "summary": summary,
            "exec_pack": exec_pack,
            "evidence": evidence,
            "tags": ["symphony", "intake", "remote-source"],
            "remote": {
                "provider": "github_issues",
                "repo": repo,
                "number": issue.get("number"),
                "url": issue_url,
                "updated_at": issue.get("updatedAt"),
                "labels": labels,
            },
            "direct_dispatch_allowed": False,
        }
        if state in {"human", "blocked"}:
            task["tags"].append("human-gate")
        tasks.append(task)
        source_items.append({
            "ticket": ticket,
            "state": state,
            "issue": issue_url,
            "exec_pack_bound": bool(exec_pack),
        })

summary = {
    "remote_available": not errors and github_overall == "passed",
    "remote_issues": len(issues) if not errors else 0,
    "tasks_generated": len(tasks),
    "intake": sum(1 for task in tasks if task["state"] == "intake"),
    "human_gate": sum(1 for task in tasks if task["state"] == "human"),
    "blocked": sum(1 for task in tasks if task["state"] == "blocked"),
    "done": sum(1 for task in tasks if task["state"] == "done"),
    "commands_executed": 0,
    "remote_writes_allowed": False,
    "runner_auto_execution_allowed": False,
    "direct_dispatch_allowed": False,
}

if errors:
    overall = "failed"
    reason = "; ".join(errors)
elif github_overall != "passed":
    overall = "human_gate"
    reason = github_reason
elif tasks:
    overall = "remote_source_ready"
    reason = "Remote issues were normalized as supervised ARTEMIS intake evidence."
else:
    overall = "remote_source_empty"
    reason = "Remote source is available but has no issues for the selected label."

contract = {
    "remote_source_defines": "intent_and_evidence",
    "exec_pack_defines": "execution_contract",
    "control_plane_shows": "state",
    "remote_writes": "blocked_by_default",
    "direct_dispatch": "blocked_by_default",
    "terminal_first": True,
    "human_gates_preserved": True,
    "validation_gate_required_before_execute": True,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-source.sh",
    "mode": "read_only_supervised_intake",
    "overall": overall,
    "reason": reason,
    "artifact_root": str(artifact_root),
    "github_artifact": str(github_artifact),
    "label": label,
    "limit": limit,
    "repo": repo,
    "summary": summary,
    "contract": contract,
    "source_items": source_items,
    "tasks": tasks,
    "github": {
        "overall": github_overall,
        "reason": github_reason,
        "checks": github_payload.get("checks", {}),
        "contract": github_payload.get("contract", {}),
    },
    "next_cut": "TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony",
}

task_source = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-source.sh",
    "mode": "remote_supervised_intake",
    "contract": contract,
    "tasks": tasks,
}

write_text(artifact_root / "remote-source.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
write_text(artifact_root / "task-source.json", json.dumps(task_source, ensure_ascii=False, indent=2) + "\n")

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Reason: {reason}",
    f"- Repo: `{repo or 'unresolved'}`.",
    f"- Issues: `{summary['remote_issues']}`.",
    f"- Tasks generated: `{summary['tasks_generated']}`.",
    f"- Intake: `{summary['intake']}`.",
    "",
    "## Contrato",
    "",
    "- Fonte remota define intencao e evidencia.",
    "- Exec Pack local define contrato de execucao.",
    "- Escritas remotas permanecem bloqueadas.",
    "- Dispatch direto permanece bloqueado.",
    "- Terminal-first, Human Gates e Validation Gate continuam obrigatorios.",
]
if tasks:
    status_lines.extend(["", "## Itens", ""])
    for item in source_items:
        status_lines.append(
            f"- `{item['ticket']}`: `{item['state']}`, exec_pack_bound=`{str(item['exec_pack_bound']).lower()}`."
        )
write_text(artifact_root / "STATUS.md", "\n".join(status_lines).rstrip() + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- GitHub adapter: `{github_overall}`.",
    f"- Tasks generated: `{summary['tasks_generated']}`.",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`.",
    f"- Runner auto execution allowed: `{str(summary['runner_auto_execution_allowed']).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "",
    "## Comandos",
    "",
    f"- `scripts/artemis-symphony-remote-source.sh --artifact-root {artifact_root} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
]
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Fonte remota supervisionada esta `{overall}`. Ela gera intake e evidencia local, nao autoridade de execucao.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`.",
    "- Revisar itens remotos antes de promover para fila/service.",
    "- Exigir Exec Pack local e decisao humana quando houver escrita remota, PR, merge ou deploy.",
    "",
    "## Nao fazer",
    "",
    "- Nao executar runner automaticamente a partir de issue.",
    "- Nao escrever labels, comentarios, PRs ou branches remotos.",
    "- Nao substituir Exec Pack por metadados remotos.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

state_to = "review" if overall in {"remote_source_ready", "remote_source_empty"} else ("human_gate" if overall == "human_gate" else "blocked")
severity = "info" if state_to == "review" else ("warning" if state_to == "human_gate" else "error")
gate = {"kind": "none", "status": "not_applicable"}
if state_to == "human_gate":
    gate = {
        "kind": "human",
        "status": "human_gate",
        "reason": reason,
        "options": ["authenticate gh", "bind local Exec Pack", "continue local-only"],
    }
elif state_to == "blocked":
    gate = {"kind": "validation", "status": "failed", "reason": reason}

events = [
    event(
        event_id="evt_tkt-050_symphony_remote_source",
        event_type="adapter.contract_recorded",
        generated_at=generated_at,
        producer={"adapter": "symphony_remote_source", "name": "scripts/artemis-symphony-remote-source.sh", "mode": "read_only_supervised_intake"},
        ticket="TKT-050",
        title="Fonte remota supervisionada do ARTEMIS Symphony",
        exec_pack="docs/exec-packs/done/TKT-050-artemis-symphony-remote-source.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to=state_to,
        runner={"kind": "none", "commands_executed": 0},
        gate=gate,
        severity=severity,
        payload={
            "overall": overall,
            "reason": reason,
            "summary": summary,
            "contract": contract,
            "next_cut": payload["next_cut"],
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-symphony-remote-source.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Remote Source: {overall}")
    print(
        "summary: "
        f"issues={summary['remote_issues']} "
        f"tasks_generated={summary['tasks_generated']} "
        f"remote_writes_allowed={str(summary['remote_writes_allowed']).lower()} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall == "failed":
    sys.exit(1)
PY
