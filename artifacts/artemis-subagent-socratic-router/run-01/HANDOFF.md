# HANDOFF

The ARTEMIS method now has a provider-aware Socratic Router for subagents.

Use it before launching Codex, Claude Code or Antigravity CLI subagents. The router must produce an explicit outcome, scope, provider fit, validation plan, budget, stop condition and Human Gate decision before any runtime provider receives work.

Next cut should generate preview-only config artifacts from this contract. It must still avoid writing `.codex/agents`, `.claude/agents` or Antigravity runtime definitions until the human accepts the generated plan.
