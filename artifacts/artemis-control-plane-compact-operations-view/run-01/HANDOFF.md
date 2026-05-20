# ARTEMIS Control Plane Compact Operations View - Handoff

The Control Plane simple mode was compacted before the next functional cut.
The previous three stacked operational sections were replaced by one
operations band with compact metrics and short provider/operator chips.

## What Changed

- The simple view now prioritizes the current state first.
- Project, registration and runtime are grouped under `Operacao`.
- Mobile hides explanatory principle cards and auxiliary panels to reduce page
  height.
- Detailed audit remains behind `Mostrar visao tecnica completa` and in the
  generated artifacts.

## Remaining Boundaries

- This is visual/read-only.
- It does not start Codex app-server, Claude Code, SDKs or CLIs.
- It does not authenticate providers.
- It does not switch projects.
- It does not spend tokens.
