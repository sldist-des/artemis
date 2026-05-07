# RUNNER - TKT-947

## Title

Validate queue bridge plan-only dispatch

## Command

```bash
scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-bridge/run-01/task-source.json
```

## Mode

plan-only

## Attempt purpose

```text
run
```

## Retry of

```text
none
```

## Execution cwd

```text
/srv/veri
```

## Guardrails

- Dry-run eligibility required.
- Workspace readiness required.
- Materialized workspace execution requires --use-workspace and a matching lock.
- Remote, merge, deployment and destructive commands are blocked.
- Human Gate still owns push, merge, secrets, production and real owners/rulesets.
