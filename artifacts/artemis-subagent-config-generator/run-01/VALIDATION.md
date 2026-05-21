# VALIDATION

- [x] `router_contract_available`
- [x] `all_three_providers_available`
- [x] `socratic_gate_available`
- [x] `codex_preview_valid_toml`
- [x] `claude_preview_has_frontmatter`
- [x] `antigravity_preview_valid_json`
- [x] `runtime_paths_untouched`
- [x] `no_runtime_side_effects`

Expected verification:

```bash
sh -n scripts/artemis-subagent-config-generator.sh
scripts/artemis-subagent-config-generator.sh --artifact-root artifacts/artemis-subagent-config-generator/run-01 --json
python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json
python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/events.json
scripts/validate-artemis.sh
```
