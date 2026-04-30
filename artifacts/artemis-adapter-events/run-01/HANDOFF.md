# HANDOFF

## Result

TKT-017 is complete.

Adapters now emit canonical ARTEMIS `events.json` artifacts while preserving their existing adapter-specific JSON outputs for diagnostics.

## Design

- Shared envelope generation lives in `scripts/artemis_event_common.py`.
- Runtime-specific fields remain in `payload`.
- Human Gate information is explicit in `gate`.
- Evidence paths are populated by the shared helper.
- Validation Gate now verifies canonical event artifacts exist.

## Next

Proceed to TKT-018: make the Control Plane consume the canonical event log as a read-only timeline surface.
