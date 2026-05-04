# RUNNER - TKT-022

## Title

Executar runner no workspace materializado

## Command

```bash
pwd
```

## Mode

execute

## Execution cwd

```text
/srv/veri-artemis-worktrees/tkt-022
```

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Materialized workspace execution requires --use-workspace and a matching lock.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
