# RUNNER - TKT-020

## Title

Emitir eventos canonicos de tentativa do runner

## Command

```bash
scripts/artemis-dry-run.sh
```

## Mode

plan-only

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
