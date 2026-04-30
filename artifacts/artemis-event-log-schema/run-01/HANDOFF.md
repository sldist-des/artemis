# HANDOFF

## Result

TKT-016 is complete as a schema and local read-only event log example.

ARTEMIS now has a canonical event envelope for task, runner, approval, Human Gate, validation, evidence and handoff events. The schema keeps Exec Packs, artifacts and Git canonical while allowing the Control Plane to consume event streams safely.

## Design

- Stable cross-adapter fields live in the event envelope.
- Adapter-specific data lives in `payload`.
- Human Gate is explicit event data.
- Evidence paths are first-class fields.
- Correlation is by ticket and optional `correlation_id`.

## Next

Proceed to TKT-017: update the GitHub, Codex app-server and Claude Code adapters to emit canonical ARTEMIS events directly alongside their current adapter-specific JSON.
