# ARTEMIS Operator Reference Intake

- Overall: `operator_reference_intake_ready`
- References: `2`
- Capabilities mapped: `5`
- Runtime execution allowed: `false`
- External installers executed: `0`
- External code copied: `false`
- Next cut: `TKT-123 - ARTEMIS Operator Capability Registry`

## References

- `ecc`: https://github.com/affaan-m/ECC (MIT) -> harness_operator_system.
- `gstack`: https://github.com/garrytan/gstack (MIT) -> opinionated_operator_role_stack.

## Capability Map

- `operator_capability_registry`: future registry of operator capabilities, providers, gates and validation evidence Future: `TKT-123 - ARTEMIS Operator Capability Registry`.
- `operator_role_lanes`: bounded lanes for product framing, engineering review, design review, QA, docs, release and security Future: `TKT-124 - ARTEMIS Operator Routing Gate`.
- `memory_learning_governance`: candidate learnings start quarantined and are promoted only after repeated validation Future: `TKT-125 - ARTEMIS Operator Memory Learning Gate`.
- `hook_and_security_policy`: deny-default hook, browser, CDP, MCP and shell escape policy with preview and rollback Future: `TKT-126 - ARTEMIS Operator Tool Security Gate`.
- `status_snapshot_handoff`: portable operator status snapshot backed by Exec Packs, Event Log, Project Graph and Validation Gate Future: `TKT-127 - ARTEMIS Operator Status Snapshot`.

## Rejected Paths

- `vendor_ecc_or_gstack`: Would blur authorship, licensing obligations, update surface and ARTEMIS authority.
- `run_external_installers_now`: Installers can mutate harness config, hooks and local state before ARTEMIS has preview and rollback gates.
- `copy_role_prompts_directly`: ARTEMIS needs its own vocabulary, Socratic routing, Validation Gate and Human Gate boundaries.
- `enable_global_hooks_by_default`: Hooks can intercept commands and tool outputs; that is runtime enforcement and requires explicit approval.
