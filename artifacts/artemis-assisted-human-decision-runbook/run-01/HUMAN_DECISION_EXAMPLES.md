# HUMAN DECISION EXAMPLES

Os exemplos abaixo mostram formato, nao autorizacao. Nao copie `decided_by`, `decided_at` ou `reason` sem uma decisao humana real.

## Exemplo `approved`

```json
"decision_record": {
  "decision": "approved",
  "decided_by": "Nome do humano",
  "decided_at": "2026-05-04T17:45:00Z",
  "reason": "Evidencias revisadas, branch integrada e worktree limpo.",
  "approved_commands": [
    "git worktree remove ../veri-artemis-worktrees/tkt-021",
    "rm .artemis/locks/tkt-021.lock",
    "git branch -d artemis/tkt-021-materializar-workspace-artemis-contr"
  ]
}
```

## Exemplo `deferred`

```json
"decision_record": {
  "decision": "deferred",
  "decided_by": "Nome do humano",
  "decided_at": "2026-05-04T17:45:00Z",
  "reason": "Manter workspace para revisar evidencia adicional antes de cleanup.",
  "approved_commands": []
}
```

## Exemplo `rejected`

```json
"decision_record": {
  "decision": "rejected",
  "decided_by": "Nome do humano",
  "decided_at": "2026-05-04T17:45:00Z",
  "reason": "Workspace deve ser preservado como referencia operacional.",
  "approved_commands": []
}
```

## Exemplo invalido

Este exemplo e invalido porque aprova parcialmente:

```json
"decision_record": {
  "decision": "approved",
  "decided_by": "Nome do humano",
  "decided_at": "2026-05-04T17:45:00Z",
  "reason": "Aprovacao parcial.",
  "approved_commands": [
    "git worktree remove ../veri-artemis-worktrees/tkt-021"
  ]
}
```

Use `deferred` quando a aprovacao for parcial.
