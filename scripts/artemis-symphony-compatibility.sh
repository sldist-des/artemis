#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-symphony-compatibility/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-symphony-compatibility.sh [--artifact-root path] [--json]" >&2
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
from datetime import datetime, timezone
from pathlib import Path

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
blockers = []


def exists(path):
    return Path(path).is_file()


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except FileNotFoundError:
        blockers.append(f"missing file: {path}")
    return ""


def run(command):
    return subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, check=False)


layers = [
    {
        "layer": "policy",
        "purpose": "Workflow, agent authority and task contract.",
        "required_files": ["AGENTS.md", "ARTEMIS_WORKFLOW.md", "docs/invariants/core.md"],
        "status": "implemented",
    },
    {
        "layer": "task_source",
        "purpose": "Exec Packs and GitHub Issues adapter as task source.",
        "required_files": ["scripts/artemis-tasks.sh", "scripts/artemis-github-issues.sh", "control-plane/tasks.json"],
        "status": "implemented",
    },
    {
        "layer": "eligibility",
        "purpose": "Read-only dispatch decision before execution.",
        "required_files": ["scripts/artemis-dry-run.sh", "scripts/artemis-workspace.sh"],
        "status": "implemented",
    },
    {
        "layer": "workspace",
        "purpose": "Branch, worktree, lock and cleanup lifecycle.",
        "required_files": [
            "scripts/artemis-workspace.sh",
            "scripts/artemis-workspace-lifecycle.sh",
            "scripts/artemis-workspace-cleanup-review.sh",
        ],
        "status": "implemented",
    },
    {
        "layer": "runner",
        "purpose": "Supervised runner plus Symphony bridge, Codex and Claude adapter contracts.",
        "required_files": [
            "scripts/artemis-runner.sh",
            "scripts/artemis-symphony-bridge.sh",
            "docs/symphony/ARTEMIS_SYMPHONY_BRIDGE.md",
            "scripts/artemis-symphony-daemon.sh",
            "docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md",
            "scripts/artemis-symphony-queue.sh",
            "docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md",
            "scripts/artemis-codex-app-server.sh",
            "scripts/artemis-claude-code.sh",
        ],
        "status": "implemented_contract",
    },
    {
        "layer": "validation",
        "purpose": "Technical proof and Human Gate separation.",
        "required_files": ["scripts/validate-artemis.sh", "scripts/artemis-validation-gate.sh"],
        "status": "implemented",
    },
    {
        "layer": "evidence",
        "purpose": "Artifacts, events and handoff memory.",
        "required_files": [
            "docs/schemas/artemis-event.schema.json",
            "docs/schemas/artemis-event-log.schema.json",
            "scripts/artemis-event-log.sh",
        ],
        "status": "implemented",
    },
    {
        "layer": "control_plane",
        "purpose": "Human-visible operating surface.",
        "required_files": ["control-plane/index.html", "docs/control-plane/artemis-control-plane.md"],
        "status": "implemented_static",
    },
    {
        "layer": "daemon_kernel",
        "purpose": "Local ARTEMIS Symphony kernel before long-running daemon.",
        "required_files": ["scripts/artemis-symphony-kernel.sh", "docs/symphony/ARTEMIS_SYMPHONY_KERNEL.md"],
        "status": "implemented_read_only",
    },
    {
        "layer": "daemon_dry_run",
        "purpose": "Finite local heartbeat loop that calls the read-only kernel without runner execution.",
        "required_files": ["scripts/artemis-symphony-daemon.sh", "docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md"],
        "status": "implemented_read_only",
    },
    {
        "layer": "supervised_queue",
        "purpose": "Review-only queue derived from daemon and kernel dispatch evidence.",
        "required_files": ["scripts/artemis-symphony-queue.sh", "docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md"],
        "status": "implemented_read_only",
    },
    {
        "layer": "queue_bridge",
        "purpose": "Plan-only bridge call from one reviewed queue item with explicit terminal command.",
        "required_files": ["scripts/artemis-symphony-queue-bridge.sh", "docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md"],
        "status": "implemented_plan_only",
    },
    {
        "layer": "queue_execution",
        "purpose": "Opt-in execution from queue after Validation Gate and exact approval decision.",
        "required_files": ["scripts/artemis-symphony-queue-bridge.sh", "docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md"],
        "status": "implemented_opt_in",
    },
]

for layer in layers:
    missing = [path for path in layer["required_files"] if not exists(path)]
    layer["missing_files"] = missing
    if missing:
        blockers.append(f"{layer['layer']} missing files: {', '.join(missing)}")

spec_path = "docs/symphony/ARTEMIS_SYMPHONY_SPEC.md"
spec_text = read_text(spec_path)
required_terms = [
    "ARTEMIS Symphony",
    "State machine",
    "Workspace",
    "Runner Layer",
    "Validation Layer",
    "Human Gates",
    "TKT-049",
    "Queue Bridge",
    "Queue Execution",
]
missing_terms = [term for term in required_terms if term not in spec_text]
if missing_terms:
    blockers.append(f"ARTEMIS Symphony spec missing terms: {', '.join(missing_terms)}")

tasks_result = run(["scripts/artemis-tasks.sh"])
tasks_total = 0
tasks_done = 0
if tasks_result.returncode != 0:
    blockers.append("scripts/artemis-tasks.sh failed")
else:
    try:
        tasks_payload = json.loads(tasks_result.stdout)
        tasks = tasks_payload.get("tasks", [])
        tasks_total = len(tasks)
        tasks_done = sum(1 for task in tasks if task.get("state") == "done")
    except json.JSONDecodeError as exc:
        blockers.append(f"scripts/artemis-tasks.sh emitted invalid JSON: {exc}")

compatibility = {
    "upstream_reference": "https://github.com/openai/symphony/blob/main/SPEC.md",
    "adoption_mode": "inspired_spec_not_dependency",
    "code_copied": False,
    "daemon_implemented": True,
    "kernel_implemented": True,
    "bridge_implemented": True,
    "daemon_dry_run": True,
    "queue_implemented": True,
    "queue_bridge_implemented": True,
    "queue_execution_implemented": True,
    "terminal_first": True,
    "human_gates_preserved": True,
    "next_cut": "TKT-049 - Servico supervisionado local do ARTEMIS Symphony",
}

overall = "failed" if blockers else "spec_ready"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-compatibility.sh",
    "mode": "read_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "spec": spec_path,
    "summary": {
        "layers_total": len(layers),
        "layers_with_missing_files": sum(1 for layer in layers if layer["missing_files"]),
        "tasks_total": tasks_total,
        "tasks_done": tasks_done,
        "daemon_implemented": exists("scripts/artemis-symphony-daemon.sh"),
        "kernel_implemented": exists("scripts/artemis-symphony-kernel.sh"),
        "bridge_implemented": exists("scripts/artemis-symphony-bridge.sh"),
        "daemon_dry_run": exists("scripts/artemis-symphony-daemon.sh"),
        "queue_implemented": exists("scripts/artemis-symphony-queue.sh"),
        "queue_bridge_implemented": exists("scripts/artemis-symphony-queue-bridge.sh"),
        "queue_execution_implemented": exists("docs/symphony/ARTEMIS_SYMPHONY_QUEUE_EXECUTION.md"),
        "next_cut_defined": "TKT-049" in spec_text,
    },
    "compatibility": compatibility,
    "layers": layers,
    "blockers": blockers,
    "invariants": [
        "OpenAI Symphony is a reference, not a vendored dependency.",
        "ARTEMIS Symphony stays terminal-first.",
        "Human Gates remain explicit and non-bypassable.",
        "Control Plane remains observational, not canonical state.",
        "The implemented kernel is read-only and cannot execute agents.",
        "The implemented bridge is supervised and plan-only by default.",
        "The implemented daemon is finite dry-run and never starts runners automatically.",
        "The implemented queue is review-only and never starts bridge or runner automatically.",
        "The implemented queue bridge is plan-only by default.",
        "Queue execution requires --execute plus Validation Gate and exact approval artifacts.",
        "A long-running supervised service is not implemented yet.",
    ],
}

(artifact_root / "symphony-compatibility.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-041 definiu o ARTEMIS Symphony como especificacao propria inspirada pelo OpenAI Symphony.",
    "",
    "## Compatibilidade",
    "",
    f"- Overall: `{overall}`.",
    f"- Adoption mode: `{compatibility['adoption_mode']}`.",
    f"- Code copied: `{str(compatibility['code_copied']).lower()}`.",
    f"- Daemon implemented: `{str(compatibility['daemon_implemented']).lower()}`.",
    f"- Kernel implemented: `{str(compatibility['kernel_implemented']).lower()}`.",
    f"- Bridge implemented: `{str(compatibility['bridge_implemented']).lower()}`.",
    f"- Terminal-first: `{str(compatibility['terminal_first']).lower()}`.",
    f"- Human Gates preserved: `{str(compatibility['human_gates_preserved']).lower()}`.",
    f"- Next cut: `{compatibility['next_cut']}`.",
    "",
    "## Camadas",
    "",
]
for layer in layers:
    status_lines.extend([
        f"### {layer['layer']}",
        "",
        f"- Purpose: {layer['purpose']}",
        f"- Status: `{layer['status']}`.",
        f"- Missing files: `{len(layer['missing_files'])}`.",
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
    f"- Layers: `{len(layers)}`.",
    f"- Layers with missing files: `{payload['summary']['layers_with_missing_files']}`.",
    f"- Tasks: `{tasks_done}/{tasks_total} done`.",
    f"- Next cut defined: `{str(payload['summary']['next_cut_defined']).lower()}`.",
    "",
    "## Comandos de verificacao",
    "",
    "- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`",
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
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"ARTEMIS Symphony esta `{overall}` como especificacao propria. O kernel, a ponte, o daemon dry-run e a fila supervisionada local existem.",
    "",
    "## Proximo corte",
    "",
    "- Criar `TKT-049 - Servico supervisionado local do ARTEMIS Symphony`.",
    "- Consumir item revisado com comando explicito e ponte plan-only por padrao.",
    "- Manter Validation Gate antes de qualquer execucao real.",
    "",
    "## Nao fazer",
    "",
    "- Nao copiar codigo do OpenAI Symphony.",
    "- Nao transformar daemon dry-run em processo persistente sem supervisor explicito.",
    "- Nao automatizar push, PR, merge ou cleanup.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Compatibility: {overall}")
    print(
        "summary: "
        f"layers={len(layers)} "
        f"tasks_done={tasks_done}/{tasks_total} "
        f"next_cut_defined={str(payload['summary']['next_cut_defined']).lower()}"
    )

if blockers:
    sys.exit(1)
PY
