# RUNNER - TKT-023

## Title

Loop de validacao e fix em workspace isolado

## Command

```bash
false
```

## Mode

execute

## Attempt purpose

```text
validation
```

## Retry of

```text
none
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
