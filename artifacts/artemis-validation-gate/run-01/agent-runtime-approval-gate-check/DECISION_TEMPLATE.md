# ARTEMIS AGENT RUNTIME DECISION TEMPLATE

Edit `artifacts/artemis-validation-gate/run-01/agent-runtime-approval-gate-check/runtime-approval-decision.json` only as the human decision record.

Valid decisions:

- `pending`: Decision is still open; no runtime can start.
- `approved`: Requires exact approval metadata, budget, command, workspace, validation and rollback fields.
- `deferred`: Requires metadata and reason; keeps runtime blocked for later review.
- `rejected`: Requires metadata and reason; refuses this runtime request while preserving evidence.

Rules:

- Keep `approved_commands` empty unless decision is `approved`.
- Use `deferred` for partial approval or uncertainty.
- Runtime cannot execute from this gate directly.
- A later intake/launcher must validate the filled decision before any command.
