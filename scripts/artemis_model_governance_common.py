import json
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log


REGISTRY_CONFIG = Path("config/artemis-model-registry.json")


MODES = {
    "registry": {
        "ticket": "TKT-110",
        "title": "ARTEMIS Model/API Governance Registry",
        "overall": "model_api_governance_registry_ready",
        "artifact": "model-api-governance-registry.json",
        "doc": "MODEL_API_GOVERNANCE_REGISTRY.md",
        "event_id": "evt_model_api_governance_registry_ready",
        "event_type": "model_governance.registry_ready",
        "exec_pack": "docs/exec-packs/done/TKT-110-artemis-model-api-governance-registry.md",
        "next_cut": "TKT-111 - Provider Capability Probes",
    },
    "probes": {
        "ticket": "TKT-111",
        "title": "ARTEMIS Provider Capability Probes",
        "overall": "provider_capability_probes_ready",
        "artifact": "provider-capability-probes.json",
        "doc": "PROVIDER_CAPABILITY_PROBES.md",
        "event_id": "evt_provider_capability_probes_ready",
        "event_type": "model_governance.capability_probes_ready",
        "exec_pack": "docs/exec-packs/done/TKT-111-artemis-provider-capability-probes.md",
        "next_cut": "TKT-112 - Model Migration Gate",
    },
    "migration": {
        "ticket": "TKT-112",
        "title": "ARTEMIS Model Migration Gate",
        "overall": "model_migration_gate_ready",
        "artifact": "model-migration-gate.json",
        "doc": "MODEL_MIGRATION_GATE.md",
        "event_id": "evt_model_migration_gate_ready",
        "event_type": "model_governance.migration_gate_ready",
        "exec_pack": "docs/exec-packs/done/TKT-112-artemis-model-migration-gate.md",
        "next_cut": "TKT-113 - Provider Operational Evals",
    },
    "evals": {
        "ticket": "TKT-113",
        "title": "ARTEMIS Provider Operational Evals",
        "overall": "provider_operational_evals_ready",
        "artifact": "provider-operational-evals.json",
        "doc": "PROVIDER_OPERATIONAL_EVALS.md",
        "event_id": "evt_provider_operational_evals_ready",
        "event_type": "model_governance.operational_evals_ready",
        "exec_pack": "docs/exec-packs/done/TKT-113-artemis-provider-operational-evals.md",
        "next_cut": "TKT-114 - Token Budget Policy",
    },
    "budget": {
        "ticket": "TKT-114",
        "title": "ARTEMIS Token Budget Policy",
        "overall": "model_token_budget_policy_ready",
        "artifact": "model-token-budget-policy.json",
        "doc": "MODEL_TOKEN_BUDGET_POLICY.md",
        "event_id": "evt_model_token_budget_policy_ready",
        "event_type": "model_governance.token_budget_policy_ready",
        "exec_pack": "docs/exec-packs/done/TKT-114-artemis-token-budget-policy.md",
        "next_cut": "TKT-115 - Model/API Documentation Radar",
    },
    "docs_radar": {
        "ticket": "TKT-115",
        "title": "ARTEMIS Model/API Documentation Radar",
        "overall": "model_api_documentation_radar_ready",
        "artifact": "model-api-documentation-radar.json",
        "doc": "MODEL_API_DOCUMENTATION_RADAR.md",
        "event_id": "evt_model_api_documentation_radar_ready",
        "event_type": "model_governance.documentation_radar_ready",
        "exec_pack": "docs/exec-packs/done/TKT-115-artemis-model-api-documentation-radar.md",
        "next_cut": "TKT-116 - Model/API Change Intake",
    },
    "change_intake": {
        "ticket": "TKT-116",
        "title": "ARTEMIS Model/API Change Intake",
        "overall": "model_api_change_intake_ready",
        "artifact": "model-api-change-intake.json",
        "doc": "MODEL_API_CHANGE_INTAKE.md",
        "event_id": "evt_model_api_change_intake_ready",
        "event_type": "model_governance.change_intake_ready",
        "exec_pack": "docs/exec-packs/done/TKT-116-artemis-model-api-change-intake.md",
        "next_cut": "TKT-117 - Model/API Review Fixture",
    },
}


def read_json(path, default=None):
    if default is None:
        default = {}
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        return default


def write_json(path, payload):
    Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def provider_ids(registry):
    return [item.get("provider_id", "unknown") for item in registry.get("providers", [])]


def common_safety():
    return {
        "runtime_auth_executed": False,
        "provider_api_calls_executed": 0,
        "agents_started": False,
        "provider_runtime_commands_executed": 0,
        "tokens_spent": 0,
        "secret_values_recorded": False,
        "remote_state_mutated": False,
    }


def markdown_lines(title, payload, extra_lines=None):
    lines = [
        f"# {title}",
        "",
        "## Resultado",
        "",
        f"- Overall: `{payload['overall']}`",
        f"- Providers: `{payload.get('providers_total', 0)}`",
        f"- Capability roles: `{payload.get('capability_roles_total', 0)}`",
        f"- Runtime auth executed: `{str(payload['runtime_auth_executed']).lower()}`",
        f"- Provider API calls executed: `{payload['provider_api_calls_executed']}`",
        f"- Agents started: `{str(payload['agents_started']).lower()}`",
        f"- Tokens spent: `{payload['tokens_spent']}`",
        f"- Remote state mutated: `{str(payload['remote_state_mutated']).lower()}`",
        f"- Next cut: `{payload['next_cut']}`",
        "",
        "## Invariantes",
        "",
    ]
    lines.extend(f"- {item}" for item in payload.get("invariants", []))
    if extra_lines:
        lines.extend(["", *extra_lines])
    return "\n".join(lines).rstrip() + "\n"


def write_standard_artifacts(artifact_root, meta, payload, doc_extra=None):
    artifact_root.mkdir(parents=True, exist_ok=True)
    write_json(artifact_root / meta["artifact"], payload)
    (artifact_root / meta["doc"]).write_text(markdown_lines(meta["title"], payload, doc_extra), encoding="utf-8")
    (artifact_root / "STATUS.md").write_text(
        "\n".join([
            "# Status",
            "",
            f"- Overall: `{payload['overall']}`",
            f"- State: `{payload.get('state', 'ready')}`",
            f"- Next cut: `{payload['next_cut']}`",
        ]) + "\n",
        encoding="utf-8",
    )
    (artifact_root / "VALIDATION.md").write_text(
        "\n".join([
            "# Validation",
            "",
            "- Registry/config inputs parsed.",
            "- Runtime API calls blocked.",
            "- Secrets, provider auth, agents, tokens and remote writes blocked.",
            "- JSON artifact emitted for validation.",
        ]) + "\n",
        encoding="utf-8",
    )
    (artifact_root / "HANDOFF.md").write_text(
        "\n".join([
            "# Handoff",
            "",
            f"{meta['ticket']} records {meta['title']}.",
            "",
            "The cut is ready when the JSON artifact reports the expected overall state and all runtime side effects remain blocked.",
        ]) + "\n",
        encoding="utf-8",
    )
    events = event_log(
        source="scripts/artemis_model_governance_common.py",
        generated_at=payload["generated_at"],
        events=[
            event(
                event_id=meta["event_id"],
                event_type=meta["event_type"],
                generated_at=payload["generated_at"],
                producer={"adapter": "model_governance", "name": meta["title"], "mode": "read_only"},
                ticket=meta["ticket"],
                title=meta["title"],
                exec_pack=meta["exec_pack"],
                artifact_root=str(artifact_root),
                state_to="done",
                payload={
                    "overall": payload["overall"],
                    "providers_total": payload.get("providers_total", 0),
                    "capability_roles_total": payload.get("capability_roles_total", 0),
                    "runtime_auth_executed": payload["runtime_auth_executed"],
                    "provider_api_calls_executed": payload["provider_api_calls_executed"],
                    "agents_started": payload["agents_started"],
                    "tokens_spent": payload["tokens_spent"],
                    "remote_state_mutated": payload["remote_state_mutated"],
                    "next_cut": payload["next_cut"],
                },
                state_from="ready",
                runner={"kind": "none"},
                gate={"kind": "none", "status": payload["overall"], "reason": "Read-only governance artifact."},
                logs=[str(artifact_root / meta["artifact"]), str(artifact_root / meta["doc"])],
            )
        ],
    )
    write_event_log(artifact_root / "events.json", events)


def base_payload(meta, registry):
    payload = {
        "schema_version": 1,
        "generated_at": now_utc(),
        "overall": meta["overall"],
        "state": "ready",
        "providers_total": len(registry.get("providers", [])),
        "capability_roles_total": len(registry.get("capability_roles", [])),
        "provider_ids": provider_ids(registry),
        "next_cut": meta["next_cut"],
        "invariants": [
            "Model names are runtime bindings, not method authority.",
            "Capability roles remain the routing contract.",
            "Official docs refresh is required before default model/API changes.",
            "Human Gate is required before changing default provider routing.",
            "No provider auth, API call, runtime agent, token spend or remote mutation is allowed in this cut.",
        ],
    }
    payload.update(common_safety())
    return payload


def build_registry(artifact_root):
    meta = MODES["registry"]
    registry = read_json(REGISTRY_CONFIG, {})
    payload = base_payload(meta, registry)
    payload.update({
        "registry_ready": True,
        "registry_config": str(REGISTRY_CONFIG),
        "policy": registry.get("policy", {}),
        "capability_roles": registry.get("capability_roles", []),
        "providers": registry.get("providers", []),
        "migration_rules": registry.get("migration_rules", []),
        "missing_files": [str(path) for path in [
            REGISTRY_CONFIG,
            Path("docs/models/ARTEMIS_MODEL_API_GOVERNANCE.md"),
            Path(meta["exec_pack"]),
        ] if not path.is_file()],
    })
    if payload["missing_files"]:
        payload["overall"] = "blocked"
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Capability Roles",
        "",
        *[f"- `{item.get('role_id')}`: {item.get('purpose')}" for item in registry.get("capability_roles", [])],
    ])
    return payload


def run_version_probe(command, args):
    exe = shutil.which(command)
    if not exe:
        return {"command": command, "installed": False, "version_probe_status": "not_found", "version": ""}
    try:
        result = subprocess.run(
            [exe, *args],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=4,
        )
        output = (result.stdout or "").strip().splitlines()
        version_lines = [line for line in output if line and not line.upper().startswith("WARNING:")]
        return {
            "command": command,
            "installed": True,
            "path": exe,
            "version_probe_status": "ok" if result.returncode == 0 else "non_zero_exit",
            "returncode": result.returncode,
            "version": version_lines[0][:200] if version_lines else (output[0][:200] if output else ""),
        }
    except Exception as exc:
        return {
            "command": command,
            "installed": True,
            "path": exe,
            "version_probe_status": "error",
            "version": "",
            "error": str(exc)[:200],
        }


def build_probes(artifact_root):
    meta = MODES["probes"]
    registry = read_json(REGISTRY_CONFIG, {})
    payload = base_payload(meta, registry)
    probes = []
    attempted = 0
    for provider in registry.get("providers", []):
        local_probe = provider.get("local_probe", {})
        candidates = local_probe.get("command_candidates", [])
        args = local_probe.get("version_args", ["--version"])
        results = [run_version_probe(command, args) for command in candidates]
        attempted += sum(1 for item in results if item.get("installed"))
        detected = next((item for item in results if item.get("installed")), None)
        probes.append({
            "provider_id": provider.get("provider_id"),
            "status": "detected" if detected else "not_installed",
            "selected_command": detected.get("command") if detected else "",
            "version": detected.get("version") if detected else "",
            "results": results,
            "supports": provider.get("supports", {}),
            "capability_bindings": provider.get("capability_bindings", {}),
        })
    payload.update({
        "capability_probes_ready": True,
        "local_version_probe_count": attempted,
        "provider_probes": probes,
        "auth_required": False,
        "api_required": False,
    })
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Probes",
        "",
        *[f"- `{item['provider_id']}`: {item['status']} {item.get('version', '')}".rstrip() for item in probes],
    ])
    return payload


def build_migration(artifact_root):
    meta = MODES["migration"]
    registry = read_json(REGISTRY_CONFIG, {})
    probes = read_json("artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json", {})
    payload = base_payload(meta, registry)
    payload.update({
        "migration_gate_ready": True,
        "migration_gate_state": "waiting_for_external_model_review",
        "migration_allowed": False,
        "default_model_change_allowed": False,
        "external_docs_refresh_required": True,
        "local_probes_required": True,
        "operational_evals_required": True,
        "budget_impact_required": True,
        "human_decision_required": True,
        "provider_probe_overview": probes.get("provider_probes", []),
        "decision_template": {
            "decision": "pending",
            "provider_id": "",
            "capability_role": "",
            "current_binding": "",
            "candidate_binding": "",
            "official_docs_checked_at": "",
            "risk": "unknown",
            "budget_impact": "unknown",
            "eval_artifact": "",
            "approved_by": "",
            "rationale": "",
        },
    })
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Gate",
        "",
        "- Default state: `waiting_for_external_model_review`",
        "- Migration allowed: `false`",
        "- Human decision required: `true`",
    ])
    return payload


def build_evals(artifact_root):
    meta = MODES["evals"]
    registry = read_json(REGISTRY_CONFIG, {})
    migration = read_json("artifacts/artemis-model-migration-gate/run-01/model-migration-gate.json", {})
    payload = base_payload(meta, registry)
    evals = [
        {"eval_id": "repo_map", "purpose": "Map project files and constraints without edits.", "required_evidence": ["file_map", "risk_notes"]},
        {"eval_id": "plan_quality", "purpose": "Create a bounded ARTEMIS plan with gates and tests.", "required_evidence": ["exec_pack", "acceptance_criteria"]},
        {"eval_id": "patch_safety", "purpose": "Apply a tiny reversible patch in a sandbox fixture.", "required_evidence": ["diff", "rollback"]},
        {"eval_id": "validation_handoff", "purpose": "Run validation command set and produce handoff.", "required_evidence": ["validation_log", "handoff"]},
        {"eval_id": "budget_respect", "purpose": "Stop before exceeding token/cost policy.", "required_evidence": ["ledger_entry", "limit_state"]},
        {"eval_id": "subagent_boundary", "purpose": "Respect delegated scope and report blockers upward.", "required_evidence": ["scope_report", "blocker_report"]},
    ]
    payload.update({
        "operational_evals_ready": True,
        "evals_runtime_executed": False,
        "evals_total": len(evals),
        "eval_suite": evals,
        "promotion_rule": "A model/API binding can become default only after required evals pass and the migration gate records human approval.",
        "migration_gate_state": migration.get("migration_gate_state", "not_available"),
    })
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Eval Suite",
        "",
        *[f"- `{item['eval_id']}`: {item['purpose']}" for item in evals],
    ])
    return payload


def build_budget(artifact_root):
    meta = MODES["budget"]
    registry = read_json(REGISTRY_CONFIG, {})
    evals = read_json("artifacts/artemis-provider-operational-evals/run-01/provider-operational-evals.json", {})
    payload = base_payload(meta, registry)
    budget_classes = [
        {"budget_class": "fast_probe", "max_agents": 1, "max_wall_time_minutes": 20, "max_total_tokens": 50000, "human_gate_above_cost_units": 5},
        {"budget_class": "verification_slice", "max_agents": 2, "max_wall_time_minutes": 45, "max_total_tokens": 150000, "human_gate_above_cost_units": 10},
        {"budget_class": "standard_slice", "max_agents": 2, "max_wall_time_minutes": 90, "max_total_tokens": 250000, "human_gate_above_cost_units": 20},
        {"budget_class": "frontier_guarded", "max_agents": 2, "max_wall_time_minutes": 180, "max_total_tokens": 420000, "human_gate_above_cost_units": 40},
        {"budget_class": "supervised_async", "max_agents": 4, "max_wall_time_minutes": 240, "max_total_tokens": 600000, "human_gate_above_cost_units": 25},
    ]
    payload.update({
        "token_budget_policy_ready": True,
        "budget_classes": budget_classes,
        "spend_authorized": False,
        "runtime_execution_allowed": False,
        "hard_stop_required": True,
        "ledger_required_before_runtime": True,
        "evals_total": evals.get("evals_total", 0),
        "policy_rule": "Every provider-backed run must bind capability_role -> provider binding -> budget_class before runtime launch.",
    })
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Budget Classes",
        "",
        *[f"- `{item['budget_class']}`: max `{item['max_total_tokens']}` tokens" for item in budget_classes],
    ])
    return payload


def build_docs_radar(artifact_root):
    meta = MODES["docs_radar"]
    registry = read_json(REGISTRY_CONFIG, {})
    migration = read_json("artifacts/artemis-model-migration-gate/run-01/model-migration-gate.json", {})
    provider_source_catalog = {
        "official_openai_codex_docs": {
            "owner": "OpenAI",
            "source_kind": "official_docs",
            "url": "https://developers.openai.com/codex",
            "scope": ["codex_cli", "codex_app_server", "subagents", "model_routing"],
            "review_required": True,
        },
        "repo_AGENTS_model_contract": {
            "owner": "ARTEMIS",
            "source_kind": "repo_contract",
            "url": "AGENTS.md",
            "scope": ["repo_model_contract", "role_routing", "agent_defaults"],
            "review_required": True,
        },
        "local_codex_cli_version": {
            "owner": "local_runtime",
            "source_kind": "local_probe",
            "url": "artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json",
            "scope": ["cli_version"],
            "review_required": True,
        },
        "official_claude_code_docs": {
            "owner": "Anthropic",
            "source_kind": "official_docs",
            "url": "https://code.claude.com/docs",
            "scope": ["claude_code_cli", "claude_code_sdk", "subagents"],
            "review_required": True,
        },
        "local_claude_cli_version": {
            "owner": "local_runtime",
            "source_kind": "local_probe",
            "url": "artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json",
            "scope": ["cli_version"],
            "review_required": True,
        },
        "provider_sdk_release_notes": {
            "owner": "provider",
            "source_kind": "release_notes",
            "url": "provider_official_release_notes",
            "scope": ["sdk_changes", "deprecations", "pricing_or_limits"],
            "review_required": True,
        },
        "official_antigravity_cli_docs": {
            "owner": "Google",
            "source_kind": "official_docs",
            "url": "https://antigravity.google/docs/cli-using",
            "scope": ["antigravity_cli", "agent_manager", "subagents"],
            "review_required": True,
        },
        "local_antigravity_cli_version": {
            "owner": "local_runtime",
            "source_kind": "local_probe",
            "url": "artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json",
            "scope": ["cli_version"],
            "review_required": True,
        },
    }
    provider_docs = []
    source_ids_seen = set()
    for provider in registry.get("providers", []):
        source_ids = provider.get("refresh_sources", [])
        source_ids_seen.update(source_ids)
        provider_docs.append({
            "provider_id": provider.get("provider_id"),
            "provider_status": provider.get("status", "unknown"),
            "required_sources": [
                {
                    "source_id": source_id,
                    **provider_source_catalog.get(source_id, {
                        "owner": "unknown",
                        "source_kind": "unknown",
                        "url": "unknown",
                        "scope": [],
                        "review_required": True,
                    }),
                    "last_reviewed_at": "",
                    "review_state": "pending",
                    "evidence_artifact": "",
                }
                for source_id in source_ids
            ],
        })
    unknown_sources = sorted(source_ids_seen - set(provider_source_catalog))
    payload = base_payload(meta, registry)
    payload.update({
        "documentation_radar_ready": True,
        "docs_radar_state": "waiting_for_official_docs_review",
        "external_fetch_executed": False,
        "official_docs_reviewed": False,
        "docs_current_confirmed": False,
        "migration_allowed": False,
        "default_model_change_allowed": False,
        "unknown_refresh_sources": unknown_sources,
        "required_source_count": sum(len(item["required_sources"]) for item in provider_docs),
        "provider_documentation": provider_docs,
        "review_policy": {
            "max_age_days_before_migration": 14,
            "official_docs_required": True,
            "release_notes_required_when_sdk_or_cli_changes": True,
            "local_probe_required": True,
            "human_review_required": True,
            "review_artifact_required": True,
        },
        "review_record_template": {
            "provider_id": "",
            "source_id": "",
            "reviewed_by": "",
            "reviewed_at": "",
            "source_url": "",
            "observed_change": "",
            "impact": "unknown",
            "migration_gate_recommendation": "hold",
            "evidence_artifact": "",
        },
        "migration_gate_state": migration.get("migration_gate_state", "not_available"),
    })
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Radar State",
        "",
        "- Documentation radar state: `waiting_for_official_docs_review`",
        "- External fetch executed: `false`",
        "- Migration allowed: `false`",
        "",
        "## Required Sources",
        "",
        *[f"- `{source_id}`: {provider_source_catalog.get(source_id, {}).get('url', 'unknown')}" for source_id in sorted(source_ids_seen)],
    ])
    return payload


def build_change_intake(artifact_root):
    meta = MODES["change_intake"]
    artifact_root.mkdir(parents=True, exist_ok=True)
    registry = read_json(REGISTRY_CONFIG, {})
    docs_radar = read_json("artifacts/artemis-model-api-documentation-radar/run-01/model-api-documentation-radar.json", {})
    provider_ids_set = set(provider_ids(registry))
    capability_roles = {item.get("role_id") for item in registry.get("capability_roles", [])}
    docs_ready_for_intake = (
        docs_radar.get("overall") == "model_api_documentation_radar_ready"
        and docs_radar.get("docs_radar_state") == "waiting_for_official_docs_review"
        and docs_radar.get("external_fetch_executed") is False
        and docs_radar.get("migration_allowed") is False
    )
    request_template = {
        "schema_version": 1,
        "change_request_id": "",
        "requested_by": "",
        "requested_at": "",
        "provider_id": "",
        "capability_role": "",
        "change_kind": "model_binding_update",
        "current_binding": "",
        "candidate_binding": "",
        "reason": "",
        "official_docs_review_artifacts": [],
        "local_probe_artifact": "artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json",
        "operational_eval_artifact": "",
        "budget_impact_artifact": "",
        "rollback_plan": "",
        "decision": "pending",
        "decision_options": ["pending", "accepted_for_review", "rejected", "deferred"],
    }
    blockers = [
        "official_docs_review_not_recorded",
        "operational_evals_not_executed",
        "budget_impact_not_recorded",
        "human_change_decision_missing",
    ]
    payload = base_payload(meta, registry)
    payload.update({
        "change_intake_ready": True,
        "change_intake_state": "waiting_for_docs_review_evidence",
        "docs_radar_ready": docs_ready_for_intake,
        "docs_current_confirmed": docs_radar.get("docs_current_confirmed", False),
        "official_docs_reviewed": docs_radar.get("official_docs_reviewed", False),
        "request_recorded": False,
        "change_request_valid": False,
        "change_review_allowed": False,
        "migration_allowed": False,
        "default_model_change_allowed": False,
        "runtime_execution_allowed": False,
        "spend_authorized": False,
        "provider_ids_allowed": sorted(provider_ids_set),
        "capability_roles_allowed": sorted(role for role in capability_roles if role),
        "request_template": request_template,
        "blockers": blockers,
        "required_evidence": [
            "official_docs_review_artifacts",
            "local_probe_artifact",
            "operational_eval_artifact",
            "budget_impact_artifact",
            "rollback_plan",
            "human_change_decision",
        ],
        "intake_rules": [
            "A change request can enter review only after official docs review evidence exists.",
            "Provider and capability role must exist in the model registry.",
            "Operational eval and budget impact evidence are mandatory before migration gate approval.",
            "This intake records intent only; it never changes defaults or runtime bindings.",
        ],
    })
    write_json(artifact_root / "model-api-change-request-template.json", request_template)
    write_standard_artifacts(artifact_root, meta, payload, [
        "## Intake State",
        "",
        "- Change intake state: `waiting_for_docs_review_evidence`",
        "- Request recorded: `false`",
        "- Change review allowed: `false`",
        "- Migration allowed: `false`",
        "",
        "## Blockers",
        "",
        *[f"- `{item}`" for item in blockers],
    ])
    return payload


BUILDERS = {
    "registry": build_registry,
    "probes": build_probes,
    "migration": build_migration,
    "evals": build_evals,
    "budget": build_budget,
    "docs_radar": build_docs_radar,
    "change_intake": build_change_intake,
}


def main(argv):
    if len(argv) != 4 or argv[1] not in BUILDERS:
        print("usage: artemis_model_governance_common.py <registry|probes|migration|evals|budget|docs_radar|change_intake> <artifact-root> <text|json>", file=sys.stderr)
        return 2
    mode = argv[1]
    artifact_root = Path(argv[2])
    output_format = argv[3]
    payload = BUILDERS[mode](artifact_root)
    if output_format == "json":
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(f"{MODES[mode]['title']}: {payload['overall']}")
        print(f"artifact_root={artifact_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
