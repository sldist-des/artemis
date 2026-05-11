#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

remote_source="artifacts/artemis-symphony-remote-source/run-01/remote-source.json"
artifact_root="artifacts/artemis-symphony-remote-intake/run-01"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-remote-intake.sh [--remote-source path] [--artifact-root path] [--json]

Reviews a supervised ARTEMIS Symphony remote source before any promotion to
local queue/service surfaces. It produces review evidence only and keeps all
derived tasks in Human Gate.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remote-source)
      remote_source="${2:-}"
      if [ -z "$remote_source" ]; then usage; exit 2; fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

mkdir -p "$artifact_root"

python3 - "$remote_source" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

remote_source_path = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
output_format = sys.argv[3]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


def as_bool(value):
    return bool(value) if isinstance(value, bool) else str(value).lower() == "true"


generated_at = now_utc()
artifact_root.mkdir(parents=True, exist_ok=True)
errors = []

try:
    remote_payload = json.loads(remote_source_path.read_text(encoding="utf-8"))
except FileNotFoundError:
    remote_payload = {}
    errors.append(f"missing remote source artifact: {remote_source_path}")
except json.JSONDecodeError as exc:
    remote_payload = {}
    errors.append(f"invalid remote source artifact: {exc}")

remote_overall = remote_payload.get("overall", "failed")
remote_reason = remote_payload.get("reason", "Remote source artifact unavailable.")
tasks = remote_payload.get("tasks") or []
contract = remote_payload.get("contract") or {}
items = []
review_tasks = []

if not errors and remote_overall in {"remote_source_ready", "remote_source_empty"}:
    for task in tasks:
        ticket = str(task.get("ticket") or task.get("id") or "REMOTE-UNKNOWN")
        state = str(task.get("state") or "").lower()
        exec_pack = str(task.get("exec_pack") or "")
        owner = str(task.get("owner") or "")
        risk = str(task.get("risk") or "")
        remote = task.get("remote") or {}
        remote_url = str(remote.get("url") or "")
        blockers = []
        warnings = []

        if state != "intake":
            warnings.append(f"remote task state is {state or 'unknown'}, not intake")
        if not exec_pack:
            blockers.append("missing local Exec Pack binding")
        elif not Path(exec_pack).is_file():
            blockers.append(f"Exec Pack not found: {exec_pack}")
        if not owner:
            blockers.append("missing owner")
        if risk not in {"low", "medium", "high"}:
            blockers.append("invalid risk")
        if not remote_url:
            blockers.append("missing remote issue URL")
        if as_bool(task.get("direct_dispatch_allowed")):
            blockers.append("remote task attempted to allow direct dispatch")

        status = "review_ready" if not blockers else "human_gate"
        if state == "blocked":
            status = "blocked"
        elif state in {"human", "human_gate"}:
            status = "human_gate"
        elif state == "done":
            status = "observed_done"

        item = {
            "ticket": ticket,
            "title": str(task.get("title") or ""),
            "state": state,
            "status": status,
            "owner": owner,
            "risk": risk,
            "exec_pack": exec_pack,
            "remote": remote,
            "blockers": blockers,
            "warnings": warnings,
            "review_required": status in {"review_ready", "human_gate"},
            "promotion_allowed": False,
            "direct_dispatch_allowed": False,
            "remote_writes_allowed": False,
            "commands_executed": 0,
        }
        items.append(item)

        review_tasks.append({
            "id": f"{ticket.lower()}-remote-intake",
            "ticket": ticket,
            "title": item["title"],
            "state": "human",
            "owner": owner or "Humano",
            "risk": risk if risk in {"low", "medium", "high"} else "medium",
            "summary": "Remote intake review is required before any local promotion or dispatch.",
            "exec_pack": exec_pack,
            "evidence": str(artifact_root / "REVIEW.md"),
            "tags": ["symphony", "remote-intake", "human-gate"],
            "remote": remote,
        })

summary = {
    "remote_available": not errors and remote_overall in {"remote_source_ready", "remote_source_empty"},
    "remote_source_overall": remote_overall,
    "items_total": len(items),
    "review_ready": sum(1 for item in items if item["status"] == "review_ready"),
    "human_gate": sum(1 for item in items if item["status"] == "human_gate"),
    "blocked": sum(1 for item in items if item["status"] == "blocked"),
    "observed_done": sum(1 for item in items if item["status"] == "observed_done"),
    "review_required": sum(1 for item in items if item["review_required"]),
    "promotion_allowed": 0,
    "direct_dispatch_allowed": False,
    "remote_writes_allowed": False,
    "runner_auto_execution_allowed": False,
    "commands_executed": 0,
}

if errors:
    overall = "failed"
    reason = "; ".join(errors)
elif remote_overall not in {"remote_source_ready", "remote_source_empty"}:
    overall = "human_gate"
    reason = remote_reason
elif summary["review_ready"] > 0:
    overall = "remote_intake_ready"
    reason = "Remote intake items are ready for human review before local promotion."
elif summary["items_total"] > 0:
    overall = "remote_intake_human_gate"
    reason = "Remote intake items require local binding or human decision before promotion."
else:
    overall = "remote_intake_empty"
    reason = "Remote source is available but produced no intake items."

intake_contract = {
    "remote_source_defines": "intent_and_evidence",
    "remote_intake_defines": "review_package",
    "exec_pack_defines": "execution_contract",
    "promotion": "blocked_until_explicit_human_review",
    "review_source_state": "human",
    "direct_dispatch": "blocked",
    "remote_writes": "blocked",
    "terminal_first": True,
    "human_gates_preserved": True,
    "validation_gate_required_before_execute": True,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-intake.sh",
    "mode": "read_only_remote_intake_review",
    "overall": overall,
    "reason": reason,
    "artifact_root": str(artifact_root),
    "remote_source": str(remote_source_path),
    "summary": summary,
    "contract": intake_contract,
    "remote_contract": contract,
    "items": items,
    "review_source": str(artifact_root / "review-source.json"),
    "next_cut": "TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony",
}

review_source = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-intake.sh",
    "mode": "remote_intake_human_review",
    "contract": intake_contract,
    "tasks": review_tasks,
}

write_text(artifact_root / "remote-intake.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
write_text(artifact_root / "review-source.json", json.dumps(review_source, ensure_ascii=False, indent=2) + "\n")

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Reason: {reason}",
    f"- Remote source: `{remote_overall}`.",
    f"- Items: `{summary['items_total']}`.",
    f"- Review ready: `{summary['review_ready']}`.",
    f"- Human Gate: `{summary['human_gate']}`.",
    "",
    "## Contrato",
    "",
    "- Intake remoto e pacote de revisao, nao promocao automatica.",
    "- Fonte derivada fica em `state=human`.",
    "- Promocao local permanece bloqueada ate decisao humana explicita.",
    "- Escritas remotas e dispatch direto permanecem bloqueados.",
]
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

review_lines = [
    "# REMOTE INTAKE REVIEW",
    "",
    "## Resumo",
    "",
    f"- Overall: `{overall}`.",
    f"- Items total: `{summary['items_total']}`.",
    f"- Review ready: `{summary['review_ready']}`.",
    f"- Human Gate: `{summary['human_gate']}`.",
    f"- Promotion allowed: `{summary['promotion_allowed']}`.",
    "",
    "## Itens",
    "",
]
if items:
    for item in items:
        review_lines.extend([
            f"### {item['ticket']}",
            "",
            f"- Status: `{item['status']}`.",
            f"- Title: {item['title']}",
            f"- Owner: `{item['owner'] or 'missing'}`.",
            f"- Risk: `{item['risk'] or 'missing'}`.",
            f"- Exec Pack: `{item['exec_pack'] or 'missing'}`.",
            f"- Remote URL: `{item['remote'].get('url', 'missing')}`.",
            f"- Promotion allowed: `{str(item['promotion_allowed']).lower()}`.",
            "",
        ])
        if item["blockers"]:
            review_lines.append("Blockers:")
            review_lines.extend(f"- {blocker}" for blocker in item["blockers"])
            review_lines.append("")
        if item["warnings"]:
            review_lines.append("Warnings:")
            review_lines.extend(f"- {warning}" for warning in item["warnings"])
            review_lines.append("")
else:
    review_lines.append("- Nenhum item remoto para revisar.")
write_text(artifact_root / "REVIEW.md", "\n".join(review_lines).rstrip() + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Review source state: `human`.",
    f"- Promotion allowed: `{summary['promotion_allowed']}`.",
    f"- Direct dispatch allowed: `{str(summary['direct_dispatch_allowed']).lower()}`.",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "",
    "## Comandos",
    "",
    f"- `scripts/artemis-symphony-remote-intake.sh --remote-source {remote_source_path} --artifact-root {artifact_root} --json`",
    "- `scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-remote-intake/run-01/review-source.json --json`",
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
    f"Intake remoto revisavel esta `{overall}`. Ele prepara revisao local e mantem qualquer fonte derivada em Human Gate.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony`.",
    "- Exigir decisao humana exata antes de promover item remoto para fila/service.",
    "- Manter GitHub writes bloqueados ate contrato explicito.",
    "",
    "## Nao fazer",
    "",
    "- Nao promover issue remota automaticamente para `ready`.",
    "- Nao chamar Queue, Service ou Runner a partir do intake.",
    "- Nao escrever em GitHub.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

state_to = "review" if overall in {"remote_intake_ready", "remote_intake_empty"} else ("human_gate" if "human_gate" in overall else "blocked")
severity = "info" if state_to == "review" else ("warning" if state_to == "human_gate" else "error")
gate = {"kind": "none", "status": "not_applicable"}
if state_to == "human_gate":
    gate = {
        "kind": "human",
        "status": "human_gate",
        "reason": reason,
        "options": ["bind local Exec Pack", "approve exact promotion later", "continue local-only"],
    }
elif state_to == "blocked":
    gate = {"kind": "validation", "status": "failed", "reason": reason}

events = [
    event(
        event_id="evt_tkt-051_symphony_remote_intake",
        event_type="adapter.contract_recorded",
        generated_at=generated_at,
        producer={"adapter": "symphony_remote_intake", "name": "scripts/artemis-symphony-remote-intake.sh", "mode": "read_only_remote_intake_review"},
        ticket="TKT-051",
        title="Intake remoto revisavel do ARTEMIS Symphony",
        exec_pack="docs/exec-packs/done/TKT-051-artemis-symphony-remote-intake.md",
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
            "contract": intake_contract,
            "next_cut": payload["next_cut"],
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-symphony-remote-intake.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Remote Intake: {overall}")
    print(
        "summary: "
        f"items={summary['items_total']} "
        f"review_ready={summary['review_ready']} "
        f"promotion_allowed={summary['promotion_allowed']} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall == "failed":
    sys.exit(1)
PY
