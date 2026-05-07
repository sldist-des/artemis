#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-memory-zone/run-01"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-memory-zone.sh [--artifact-root path] [--json]

Records the ARTEMIS Human-AI Memory Zone contract. This is a read-only
architecture cut: it does not install Tolaria, CocoIndex, databases, embeddings,
or background indexers.
EOF
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
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


generated_at = now_utc()
artifact_root.mkdir(parents=True, exist_ok=True)

required_files = [
    "docs/memory/ARTEMIS_MEMORY_ZONE.md",
    "docs/symphony/ARTEMIS_SYMPHONY_SPEC.md",
    "AGENTS.md",
    "ARTEMIS_WORKFLOW.md",
]
missing_files = [path for path in required_files if not Path(path).is_file()]

sources = [
    {
        "name": "Tolaria",
        "url": "https://github.com/refactoringhq/tolaria",
        "role": "human_ai_vault_reference",
        "adopt": ["files_first", "git_first", "offline_first", "markdown_frontmatter", "ai_first_not_ai_only"],
        "do_not_adopt_blindly": ["desktop_runtime_coupling", "AGPL_code_copy"],
    },
    {
        "name": "CocoIndex",
        "url": "https://github.com/cocoindex-io/cocoindex",
        "role": "incremental_context_index_reference",
        "adopt": ["incremental_processing", "lineage", "freshness", "semantic_and_graph_indexes"],
        "do_not_adopt_blindly": ["new_runtime_dependency_without_decision", "implicit_embedding_costs"],
    },
]

zones = [
    {
        "zone": "human_vault",
        "purpose": "Notas, decisoes, runbooks e contexto editaveis por humanos e agentes.",
        "format": "markdown_with_frontmatter",
        "authority": "human_editable_git_versioned",
        "runtime": "future_tolaria_compatible_vault",
    },
    {
        "zone": "project_memory",
        "purpose": "Estado operacional do projeto, decisoes, gates, exec packs e handoffs.",
        "format": "artemis_artifacts_and_event_log",
        "authority": "artifacts_are_evidence_git_is_memory",
        "runtime": "current_repo",
    },
    {
        "zone": "derived_index",
        "purpose": "Indice incremental para busca semantica, grafo, freshness e lineage.",
        "format": "future_cocoindex_dataflow",
        "authority": "derived_read_model_not_source_of_truth",
        "runtime": "future_optional_indexer",
    },
]

invariants = [
    "Memory Zone is source-of-context, not execution authority.",
    "Markdown/Git artifacts remain portable and inspectable.",
    "Derived indexes can be rebuilt and never replace source files.",
    "Public reference code may be studied for architecture and tradeoffs, but ARTEMIS implementation must be original.",
    "Secrets and credentials are excluded from memory and indexes by default.",
    "Agents may propose memory updates, but Human Gates govern sensitive knowledge changes.",
    "Costs from embeddings, indexing and agent queries must be budgeted before runtime use.",
]

summary = {
    "sources_total": len(sources),
    "zones_total": len(zones),
    "missing_files": len(missing_files),
    "dependencies_installed": 0,
    "indexes_built": 0,
    "embeddings_created": 0,
    "commands_executed": 0,
    "remote_writes_allowed": False,
    "runtime_started": False,
    "reference_code_study_allowed": True,
    "code_copied": False,
    "vendorization_allowed_without_human_gate": False,
}

overall = "memory_zone_ready" if not missing_files else "failed"
reason = "Human-AI Memory Zone contract is ready." if not missing_files else "Missing required files: " + ", ".join(missing_files)

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-memory-zone.sh",
    "mode": "read_only_memory_contract",
    "overall": overall,
    "reason": reason,
    "artifact_root": str(artifact_root),
    "summary": summary,
    "sources": sources,
    "zones": zones,
    "invariants": invariants,
    "contracts": {
        "tolaria": "reference_for_human_ai_markdown_vault",
        "cocoindex": "reference_for_incremental_derived_context_index",
        "source_of_truth": "git_versioned_markdown_and_artifacts",
        "derived_index": "rebuildable_read_model",
        "project_operations_graph": "future_consumer_of_memory_zone",
        "dependency_policy": "no_new_dependency_without_explicit_decision",
        "reference_study_policy": "study_public_code_for_learning_then_recreate_original_artemis_implementation",
    },
    "next_cut": "TKT-054 - Project Operations Graph do ARTEMIS Symphony",
}

write_text(artifact_root / "memory-zone.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

memory_lines = [
    "# MEMORY ZONE",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Reason: {reason}",
    "",
    "## Camadas",
    "",
]
for zone in zones:
    memory_lines.extend([
        f"### {zone['zone']}",
        "",
        f"- Purpose: {zone['purpose']}",
        f"- Format: `{zone['format']}`.",
        f"- Authority: `{zone['authority']}`.",
        f"- Runtime: `{zone['runtime']}`.",
        "",
    ])
memory_lines.extend([
    "## Referencias",
    "",
])
for source in sources:
    memory_lines.append(f"- {source['name']}: {source['url']} (`{source['role']}`).")
write_text(artifact_root / "MEMORY_ZONE.md", "\n".join(memory_lines).rstrip() + "\n")

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Sources: `{summary['sources_total']}`.",
    f"- Zones: `{summary['zones_total']}`.",
    f"- Missing files: `{summary['missing_files']}`.",
    f"- Dependencies installed: `{summary['dependencies_installed']}`.",
    f"- Indexes built: `{summary['indexes_built']}`.",
    f"- Embeddings created: `{summary['embeddings_created']}`.",
    f"- Runtime started: `{str(summary['runtime_started']).lower()}`.",
    "",
    "## Invariantes",
    "",
]
status_lines.extend(f"- {item}" for item in invariants)
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Required files missing: `{summary['missing_files']}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`.",
    "",
    "## Comandos",
    "",
    f"- `scripts/artemis-memory-zone.sh --artifact-root {artifact_root} --json`",
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
    f"Memory Zone esta `{overall}` como contrato read-only. Ela conecta memoria humana, evidencia ARTEMIS e indice incremental futuro.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-054 - Project Operations Graph do ARTEMIS Symphony`.",
    "- Usar Memory Zone como fonte de contexto e o indice derivado como read model.",
    "",
    "## Nao fazer",
    "",
    "- Nao copiar codigo AGPL do Tolaria.",
    "- Nao instalar CocoIndex, Postgres, embeddings ou indexador sem decisao explicita.",
    "- Nao tratar indice derivado como fonte de verdade.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

events = [
    event(
        event_id="evt_tkt-053_memory_zone",
        event_type="adapter.contract_recorded",
        generated_at=generated_at,
        producer={"adapter": "memory_zone", "name": "scripts/artemis-memory-zone.sh", "mode": "read_only"},
        ticket="TKT-053",
        title="Memory Zone humano-AI do ARTEMIS Symphony",
        exec_pack="docs/exec-packs/done/TKT-053-artemis-memory-zone.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="done" if overall == "memory_zone_ready" else "blocked",
        runner={"kind": "none"},
        severity="info" if overall == "memory_zone_ready" else "error",
        payload={
            "overall": overall,
            "reason": reason,
            "summary": summary,
            "next_cut": payload["next_cut"],
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-memory-zone.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Memory Zone: {overall}")
    print(
        "summary: "
        f"sources={summary['sources_total']} "
        f"zones={summary['zones_total']} "
        f"dependencies_installed={summary['dependencies_installed']}"
    )

if overall == "failed":
    raise SystemExit(1)
PY
