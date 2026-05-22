# Validation

- [x] `clarity_questions_declared`
- [x] `argument_contract_declared`
- [x] `ambiguity_gates_declared`
- [x] `question_policy_declared`
- [x] `no_runtime_side_effects`

## Commands

```bash
sh -n scripts/artemis-socratic-logic.sh
scripts/artemis-socratic-logic.sh --artifact-root artifacts/artemis-socratic-logic/run-01 --json
python3 -m json.tool artifacts/artemis-socratic-logic/run-01/socratic-logic.json
python3 -m json.tool artifacts/artemis-socratic-logic/run-01/events.json
```
