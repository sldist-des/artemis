# RUNNER - TKT-023

## Title

Loop de validacao e fix em workspace isolado

## Command

```bash
pwd
```

## Mode

execute

## Attempt purpose

```text
retry
```

## Retry of

```text
20260504T141956Z-2-tkt-023
```

## Execution cwd

```text
/srv/veri-artemis-worktrees/tkt-023
```

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Materialized workspace execution requires --use-workspace and a matching lock.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
