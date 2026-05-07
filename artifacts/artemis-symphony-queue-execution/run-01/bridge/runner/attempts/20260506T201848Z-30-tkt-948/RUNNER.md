# RUNNER - TKT-948

## Title

Validate queue execution opt-in

## Command

```bash
scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-queue-execution/run-01/fixtures/task-source.json
```

## Mode

execute

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
