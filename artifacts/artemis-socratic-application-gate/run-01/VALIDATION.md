# Validation

- [x] `socratic_logic_available`
- [x] `application_stages_declared`
- [x] `routes_are_distinct`
- [x] `contexts_are_mapped`
- [x] `human_question_is_bounded`
- [x] `no_runtime_side_effects`

## Commands

```bash
sh -n scripts/artemis-socratic-application-gate.sh
scripts/artemis-socratic-application-gate.sh --artifact-root artifacts/artemis-socratic-application-gate/run-01 --json
python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json
python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/events.json
```
