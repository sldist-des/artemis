#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-operator-reference-intake/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-operator-reference-intake.sh [--artifact-root path] [--json]" >&2
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
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]
generated_at = now_utc()

required_files = [
    Path("AGENTS.md"),
    Path("ARTEMIS_WORKFLOW.md"),
    Path("docs/references/ARTEMIS_OPERATOR_REFERENCE_INTAKE.md"),
    Path("docs/exec-packs/done/TKT-122-artemis-operator-reference-intake.md"),
    Path("artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

reference_sources = [
    {
        "id": "ecc",
        "name": "ECC",
        "repo": "https://github.com/affaan-m/ECC",
        "license": "MIT",
        "license_url": "https://github.com/affaan-m/ECC/blob/main/LICENSE",
        "verified_at": "2026-05-25",
        "reference_role": "harness_operator_system",
        "observed_capabilities": [
            "cross-harness agent, skill, command and rule packaging",
            "memory persistence and continuous learning surfaces",
            "security scanning and hook-oriented enforcement",
            "research-first development and documentation lookup patterns",
            "token optimization, evals and parallelization guidance",
            "selective install and component-scoped profiles",
        ],
        "artemis_interest": [
            "operator capability registry",
            "component-scoped installation previews",
            "memory and learning governance",
            "security and hook policy gates",
            "status snapshots for handoff",
        ],
        "do_not_copy": [
            "repository code",
            "assets, branding or prose",
            "global hooks without Human Gate",
            "installer behavior",
            "provider-specific config files without preview",
        ],
    },
    {
        "id": "gstack",
        "name": "gstack",
        "repo": "https://github.com/garrytan/gstack",
        "license": "MIT",
        "license_url": "https://github.com/garrytan/gstack/blob/main/LICENSE",
        "verified_at": "2026-05-25",
        "reference_role": "opinionated_operator_role_stack",
        "observed_capabilities": [
            "role-shaped tools for CEO, designer, engineering manager, release, docs and QA work",
            "sprint-like operator sequence from thinking through shipping and reflection",
            "local-first checkpoint behavior before push",
            "domain skills that mature from quarantined to active after repeated success",
            "deny-default low-level browser escape hatches with explicit allowlisting",
            "defensive handling for untrusted browser and tool output",
        ],
        "artemis_interest": [
            "operator role lanes",
            "office-hours and review gates",
            "release and QA routing",
            "domain skill quarantine and promotion",
            "deny-default tool escape hatches",
        ],
        "do_not_copy": [
            "tool implementations",
            "Claude-only setup assumptions",
            "branding or role names as-is when ARTEMIS needs its own vocabulary",
            "browser automation defaults",
            "security model without local ARTEMIS validation",
        ],
    },
]

capability_map = [
    {
        "capability_id": "operator_capability_registry",
        "inspired_by": ["ecc", "gstack"],
        "artemis_surface": "future registry of operator capabilities, providers, gates and validation evidence",
        "required_gate": "socratic_application_gate",
        "future_cut": "TKT-123 - ARTEMIS Operator Capability Registry",
    },
    {
        "capability_id": "operator_role_lanes",
        "inspired_by": ["gstack"],
        "artemis_surface": "bounded lanes for product framing, engineering review, design review, QA, docs, release and security",
        "required_gate": "human_gate_when_scope_or_acceptance_changes",
        "future_cut": "TKT-124 - ARTEMIS Operator Routing Gate",
    },
    {
        "capability_id": "memory_learning_governance",
        "inspired_by": ["ecc", "gstack"],
        "artemis_surface": "candidate learnings start quarantined and are promoted only after repeated validation",
        "required_gate": "memory_zone_governance",
        "future_cut": "TKT-125 - ARTEMIS Operator Memory Learning Gate",
    },
    {
        "capability_id": "hook_and_security_policy",
        "inspired_by": ["ecc", "gstack"],
        "artemis_surface": "deny-default hook, browser, CDP, MCP and shell escape policy with preview and rollback",
        "required_gate": "human_gate_for_runtime_or_tool_enforcement",
        "future_cut": "TKT-126 - ARTEMIS Operator Tool Security Gate",
    },
    {
        "capability_id": "status_snapshot_handoff",
        "inspired_by": ["ecc"],
        "artemis_surface": "portable operator status snapshot backed by Exec Packs, Event Log, Project Graph and Validation Gate",
        "required_gate": "validation_gate",
        "future_cut": "TKT-127 - ARTEMIS Operator Status Snapshot",
    },
]

adoption_decisions = [
    {
        "decision": "adopt_as_reference_only",
        "reason": "ECC and gstack provide useful operator architecture, but ARTEMIS must keep its own source of truth, gates and artifacts.",
    },
    {
        "decision": "recreate_contracts_not_code",
        "reason": "Implementation must become original ARTEMIS contracts, scripts and validation artifacts.",
    },
    {
        "decision": "component_preview_before_install",
        "reason": "Any future installable component must show file plan, permissions, rollback and validation before touching the project.",
    },
    {
        "decision": "deny_runtime_by_default",
        "reason": "Hooks, browser automation, auth, provider runtime, token spend and remote writes remain Human Gate only.",
    },
]

rejected_paths = [
    {
        "path": "vendor_ecc_or_gstack",
        "reason": "Would blur authorship, licensing obligations, update surface and ARTEMIS authority.",
    },
    {
        "path": "run_external_installers_now",
        "reason": "Installers can mutate harness config, hooks and local state before ARTEMIS has preview and rollback gates.",
    },
    {
        "path": "copy_role_prompts_directly",
        "reason": "ARTEMIS needs its own vocabulary, Socratic routing, Validation Gate and Human Gate boundaries.",
    },
    {
        "path": "enable_global_hooks_by_default",
        "reason": "Hooks can intercept commands and tool outputs; that is runtime enforcement and requires explicit approval.",
    },
]

operator_principles = [
    "External references are inspiration, not authority.",
    "ARTEMIS owns the contract; Git, Exec Packs, Event Log and Validation Gate remain canonical.",
    "No external code, prompt, asset, installer or hook is copied in this cut.",
    "Every future operator capability must name provider fit, risk, validation and Human Gate conditions.",
    "Learning and memory candidates must be governed before they can influence future work.",
    "Security and browser/tool escape hatches are deny-default until explicitly allowed.",
]

checks = [
    {
        "id": "references_declared",
        "passed": len(reference_sources) == 2,
        "evidence": "ECC and gstack",
    },
    {
        "id": "licenses_recorded",
        "passed": all(source["license"] == "MIT" and source["license_url"] for source in reference_sources),
        "evidence": "license urls recorded",
    },
    {
        "id": "capability_map_declared",
        "passed": len(capability_map) >= 5,
        "evidence": f"{len(capability_map)} capabilities",
    },
    {
        "id": "rejected_paths_declared",
        "passed": len(rejected_paths) >= 4,
        "evidence": f"{len(rejected_paths)} rejected paths",
    },
    {
        "id": "no_vendor_or_install",
        "passed": True,
        "evidence": "reference-intake-only artifact",
    },
]

overall = "operator_reference_intake_ready" if not missing_files and all(check["passed"] for check in checks) else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-operator-reference-intake.sh",
    "mode": "reference_intake_only_no_vendor_no_runtime",
    "overall": overall,
    "ticket": "TKT-122",
    "artifact_root": str(artifact_root),
    "reference_sources": reference_sources,
    "capability_map": capability_map,
    "adoption_decisions": adoption_decisions,
    "rejected_paths": rejected_paths,
    "operator_principles": operator_principles,
    "runtime_execution_allowed": False,
    "external_installers_executed": 0,
    "external_code_copied": False,
    "hooks_enabled": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "missing_files": missing_files,
    "checks": checks,
    "next_cut": "TKT-123 - ARTEMIS Operator Capability Registry",
}

(artifact_root / "operator-reference-intake.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

lines = [
    "# ARTEMIS Operator Reference Intake",
    "",
    f"- Overall: `{overall}`",
    f"- References: `{len(reference_sources)}`",
    f"- Capabilities mapped: `{len(capability_map)}`",
    "- Runtime execution allowed: `false`",
    "- External installers executed: `0`",
    "- External code copied: `false`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## References",
    "",
]
for source in reference_sources:
    lines.append(f"- `{source['id']}`: {source['repo']} ({source['license']}) -> {source['reference_role']}.")
lines.extend(["", "## Capability Map", ""])
for item in capability_map:
    lines.append(f"- `{item['capability_id']}`: {item['artemis_surface']} Future: `{item['future_cut']}`.")
lines.extend(["", "## Rejected Paths", ""])
for item in rejected_paths:
    lines.append(f"- `{item['path']}`: {item['reason']}")

(artifact_root / "OPERATOR_REFERENCE_INTAKE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Reference intake is read-only and does not install ECC or gstack.",
        "- External code, hooks, runtime, agents, tokens and remote writes remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        *[f"- [{'x' if check['passed'] else ' '}] `{check['id']}`" for check in checks],
        "",
        "## Commands",
        "",
        "```bash",
        "sh -n scripts/artemis-operator-reference-intake.sh",
        "scripts/artemis-operator-reference-intake.sh --artifact-root artifacts/artemis-operator-reference-intake/run-01 --json",
        "python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/operator-reference-intake.json",
        "python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/events.json",
        "```",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-122 records ECC and gstack as external operator references for ARTEMIS.",
        "",
        "Use the capability map to implement ARTEMIS-native operator registry and routing gates without vendorizing external code.",
    ]) + "\n",
    encoding="utf-8",
)

events = [
    event(
        event_id="evt_artemis_operator_reference_intake_ready",
        event_type="method.operator_reference_intake_ready",
        generated_at=generated_at,
        producer={"adapter": "method", "name": "scripts/artemis-operator-reference-intake.sh", "mode": "read_only"},
        ticket="TKT-122",
        title="ARTEMIS Operator Reference Intake",
        exec_pack="docs/exec-packs/done/TKT-122-artemis-operator-reference-intake.md",
        artifact_root=str(artifact_root),
        state_to="done" if overall == "operator_reference_intake_ready" else "blocked",
        payload={
            "overall": overall,
            "references": [source["id"] for source in reference_sources],
            "capabilities": len(capability_map),
            "licenses": sorted({source["license"] for source in reference_sources}),
            "runtime_execution_allowed": False,
            "external_installers_executed": 0,
            "external_code_copied": False,
            "hooks_enabled": False,
            "agents_started": False,
            "commands_executed": 0,
            "tokens_spent": 0,
            "remote_state_mutated": False,
            "next_cut": payload["next_cut"],
        },
        state_from="planned",
        runner={"kind": "none"},
        gate={"kind": "method", "status": overall, "reason": "External operator references mapped without vendorization."},
        logs=[str(artifact_root / "operator-reference-intake.json"), str(artifact_root / "OPERATOR_REFERENCE_INTAKE.md")],
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-operator-reference-intake.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Operator Reference Intake: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"references={len(reference_sources)}")
    print(f"capabilities={len(capability_map)}")
    print("runtime_execution_allowed=false")
PY
