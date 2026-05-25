# Validation

- [x] `references_declared`
- [x] `licenses_recorded`
- [x] `capability_map_declared`
- [x] `rejected_paths_declared`
- [x] `no_vendor_or_install`

## Commands

```bash
sh -n scripts/artemis-operator-reference-intake.sh
scripts/artemis-operator-reference-intake.sh --artifact-root artifacts/artemis-operator-reference-intake/run-01 --json
python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/operator-reference-intake.json
python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/events.json
```
