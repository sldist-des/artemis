# ARTEMIS Portal Project Registry Human Review Gate

Este corte transforma o candidato do Registry Intake em uma decisao humana
explicita antes de qualquer registro, troca de projeto ou runtime.

## Regra central

Nenhum projeto candidato entra em operacao por aparecer no painel.

```text
Registry Intake
  -> Human Review Gate
  -> pending decision
  -> no project switch
  -> no runtime
```

## Decisao esperada

Uma decisao futura deve registrar:

- `candidate_project_id`
- `decision`
- `decided_by`
- `decided_at`
- `rationale`

As decisoes permitidas sao `approved`, `rejected` e `deferred`.

## Invariantes

- O gate nao aprova candidato sozinho.
- O gate nao registra projeto externo sozinho.
- O gate nao troca o projeto selecionado.
- O gate nao autentica provider.
- O gate nao cria worktree.
- O gate nao inicia runtime.
- O gate nao executa comandos.
- O gate nao gasta tokens.

## Para leigos

Esta etapa responde:

> Tem um projeto candidato. Alguem ja decidiu se ele entra?

Neste corte, a resposta e:

> Ainda nao. Ele esta aguardando decisao humana.
