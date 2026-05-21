# VALIDATION

- [x] `official_sources_declared`
- [x] `all_three_providers_mapped`
- [x] `socratic_gate_declared`
- [x] `safety_invariants_declared`
- [x] `human_gate_for_antigravity_inherited_scopes`

Expected verification:

```bash
sh -n scripts/artemis-subagent-socratic-router.sh
scripts/artemis-subagent-socratic-router.sh --artifact-root artifacts/artemis-subagent-socratic-router/run-01 --json
python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json
python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/events.json
scripts/validate-artemis.sh
```
