#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-application-readiness/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-application-readiness.sh [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

python3 - "$artifact_root" "$format" <<'PY'
import json
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
blockers = []
warnings = []


def read_json(path):
    path = Path(path)
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        warnings.append(f"missing optional JSON: {path}")
    except json.JSONDecodeError as exc:
        blockers.append(f"invalid JSON at {path}: {exc}")
    return {}


def run(command):
    return subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, check=False)


required_files = [
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "ARTEMIS_QUICKSTART.md",
    "ARTEMIS_WORKFLOW.md",
    "templates/AGENTS.md",
    "templates/CLAUDE.md",
    "templates/ARCHITECTURE.md",
    "templates/AI_PROCESS.md",
    "templates/.github/PULL_REQUEST_TEMPLATE.md",
    "templates/.github/ISSUE_TEMPLATE/artemis_task.yml",
    "templates/.github/CODEOWNERS",
    "templates/docs/exec-packs/TEMPLATE.md",
    "templates/docs/invariants/core.md",
    "scripts/bootstrap-artemis.sh",
    "scripts/validate-artemis.sh",
    "scripts/artemis-validation-gate.sh",
    "scripts/artemis-post-human-approval-preflight.sh",
]

inventory = []
for file_name in required_files:
    path = Path(file_name)
    exists = path.is_file()
    inventory.append({"path": file_name, "exists": exists})
    if not exists:
        blockers.append(f"missing required application file: {file_name}")

tasks_result = run(["scripts/artemis-tasks.sh"])
tasks = {}
if tasks_result.returncode != 0:
    blockers.append("scripts/artemis-tasks.sh failed")
else:
    try:
        tasks = json.loads(tasks_result.stdout)
    except json.JSONDecodeError as exc:
        blockers.append(f"scripts/artemis-tasks.sh emitted invalid JSON: {exc}")

task_items = tasks.get("tasks", [])
task_states = Counter(item.get("state", "unknown") for item in task_items)
active_tasks = [item for item in task_items if item.get("state") != "done"]
if active_tasks:
    warnings.append(f"{len(active_tasks)} non-done Exec Pack(s) remain")

post_preflight = read_json("artifacts/artemis-post-human-approval-preflight/run-01/post-human-approval-preflight.json")
validation_gate = read_json("artifacts/artemis-validation-gate/run-01/validation-gate.json")

technical_failed = int((validation_gate.get("summary") or {}).get("failed", 0) or 0)
if technical_failed:
    blockers.append("Validation Gate has technical failures")

git_status = run(["git", "status", "--short"])
dirty_lines = [line for line in git_status.stdout.splitlines() if line.strip()]

external_gates = [
    {
        "gate": "real_cleanup_decision",
        "status": post_preflight.get("overall", "unknown"),
        "reason": "real-cleanup-decision.json still requires human decision before cleanup/preflight can advance",
        "required_human_action": "Fill artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json and rerun intake, reentry, preflight.",
    },
    {
        "gate": "github_remote",
        "status": "human_gate",
        "reason": "Remote writes, gh auth, CODEOWNERS, branch protection and PR publication require human-owned setup.",
        "required_human_action": "Authenticate gh, configure CODEOWNERS/rulesets if remote publication is desired.",
    },
]

application_steps = [
    "Rode scripts/bootstrap-artemis.sh /caminho/do/projeto.",
    "Edite AGENTS.md, ARCHITECTURE.md e AI_PROCESS.md no projeto alvo.",
    "Mantenha CLAUDE.md como adaptador fino apontando para AGENTS.md.",
    "Crie o primeiro Exec Pack em docs/exec-packs/active/.",
    "Rode lint, testes e scripts/validate-artemis.sh do projeto quando existirem.",
    "Use branch e worktree por tarefa antes de implementar com agente.",
    "Registre STATUS.md, VALIDATION.md e HANDOFF.md para toda tarefa material.",
]

application_ready = not blockers and len(task_items) >= 40 and not active_tasks
overall = "ready_with_human_gates" if application_ready else "failed"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-application-readiness.sh",
    "mode": "read_only",
    "overall": overall,
    "application_ready": application_ready,
    "artifact_root": str(artifact_root),
    "summary": {
        "tasks_total": len(task_items),
        "tasks_done": task_states.get("done", 0),
        "active_tasks": len(active_tasks),
        "validation_failed": technical_failed,
        "external_human_gates": len(external_gates),
        "dirty_items": len(dirty_lines),
    },
    "required_inventory": inventory,
    "application_steps": application_steps,
    "external_gates": external_gates,
    "blockers": blockers,
    "warnings": warnings,
    "invariants": [
        "Application readiness is read-only and does not execute cleanup.",
        "Application readiness does not authenticate GitHub or perform remote writes.",
        "Application readiness does not fill human-owned decision records.",
        "Templates are starter material and must be adapted to the target project.",
        "AGENTS.md remains canonical for shared agent guidance.",
    ],
}

(artifact_root / "application-readiness.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "O kit ARTEMIS foi consolidado como pacote local aplicavel a outros projetos.",
    "",
    "## Readiness",
    "",
    f"- Overall: `{overall}`.",
    f"- Application ready: `{str(application_ready).lower()}`.",
    f"- Tasks total: `{len(task_items)}`.",
    f"- Tasks done: `{task_states.get('done', 0)}`.",
    f"- Active tasks: `{len(active_tasks)}`.",
    f"- Validation failed: `{technical_failed}`.",
    f"- External human gates: `{len(external_gates)}`.",
    "",
    "## Passos de aplicacao",
    "",
]
for step in application_steps:
    status_lines.append(f"- {step}")

status_lines.extend([
    "",
    "## Gates humanos externos",
    "",
])
for gate in external_gates:
    status_lines.extend([
        f"### {gate['gate']}",
        "",
        f"- Status: `{gate['status']}`.",
        f"- Reason: {gate['reason']}",
        f"- Human action: {gate['required_human_action']}",
        "",
    ])

status_lines.extend([
    "## Invariantes",
    "",
])
for invariant in payload["invariants"]:
    status_lines.append(f"- {invariant}")
(artifact_root / "STATUS.md").write_text("\n".join(status_lines).rstrip() + "\n", encoding="utf-8")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Application ready: `{str(application_ready).lower()}`.",
    f"- Tasks: `{task_states.get('done', 0)}/{len(task_items)} done`.",
    f"- Validation technical failures: `{technical_failed}`.",
    "",
    "## Comandos de verificacao",
    "",
    "- `scripts/artemis-application-readiness.sh --artifact-root artifacts/artemis-application-readiness/run-01 --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
    "",
    "## Blockers",
    "",
]
if blockers:
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
else:
    validation_lines.append("- Nenhum blocker tecnico local.")

validation_lines.extend([
    "",
    "## Warnings",
    "",
])
if warnings:
    for warning in warnings:
        validation_lines.append(f"- {warning}")
else:
    validation_lines.append("- Nenhum warning local.")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"ARTEMIS esta `{overall}` para aplicacao local, com gates humanos externos preservados.",
    "",
    "## Para aplicar em um projeto",
    "",
]
for step in application_steps:
    handoff_lines.append(f"- {step}")

handoff_lines.extend([
    "",
    "## Nao fazer automaticamente",
    "",
    "- Nao preencher decisao humana real.",
    "- Nao executar cleanup real.",
    "- Nao criar push/PR remoto sem GitHub configurado pelo humano.",
    "- Nao substituir revisao humana por readiness tecnica.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Application Readiness: {overall}")
    print(
        "summary: "
        f"tasks_done={task_states.get('done', 0)}/{len(task_items)} "
        f"application_ready={str(application_ready).lower()} "
        f"external_human_gates={len(external_gates)}"
    )

if blockers:
    sys.exit(1)
PY
