# ARTEMIS Portal Project Registry Decision Intake

Este corte cria a entrada estruturada para uma decisao humana sobre candidatos
do Project Registry.

## Regra central

Intake de decisao nao e execucao da decisao.

```text
Human Review Gate
  -> Decision Intake
  -> pending | approved | rejected | deferred | invalid
  -> no registration
  -> no project switch
  -> no runtime
```

## Template

Quando nao ha arquivo de decisao, o script grava um template preenchivel em:

```text
artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-template.json
```

## Campos obrigatorios

- `candidate_project_id`
- `decision`
- `decided_by`
- `decided_at`
- `rationale`

## Decisoes permitidas

- `approved`: pode seguir para um gate de registro futuro.
- `rejected`: candidato continua nao selecionavel.
- `deferred`: candidato continua pendente.

## Invariantes

- O intake nao registra projeto.
- O intake nao troca projeto selecionado.
- O intake nao autentica provider.
- O intake nao cria worktree.
- O intake nao inicia runtime.
- O intake nao executa comandos.
- O intake nao gasta tokens.
- O intake nao escreve remoto.

## Para leigos

Esta etapa responde:

> Existe uma decisao humana registrada para esse projeto candidato?

Neste corte, a resposta padrao e:

> Ainda nao. Existe um modelo de decisao para preencher.
