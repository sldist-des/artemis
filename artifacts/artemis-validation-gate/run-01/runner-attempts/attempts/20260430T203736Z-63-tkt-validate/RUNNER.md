# RUNNER - TKT-VALIDATE

## Title

Validate supervised runner

## Command

```bash
scripts/artemis-dry-run.sh --input artifacts/artemis-validation-gate/run-01/runner-task-source.json
```

## Mode

plan-only

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
