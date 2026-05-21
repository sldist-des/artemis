# ARTEMIS Portal Project Registry Registration Gate

Este corte cria o gate que impede registro de projeto candidato sem uma decisao
humana aprovada e validada.

## Regra central

Registro de candidato e uma etapa separada da decisao.

```text
Decision Intake
  -> Registration Gate
  -> waiting_for_valid_human_decision
  -> no registration
  -> no project switch
  -> no runtime
```

## Precondicoes

- Decision Intake pronto.
- Decisao humana registrada.
- Decisao igual a `approved`.
- Candidato conhecido.
- Troca de projeto bloqueada.
- Runtime bloqueado.

## Invariantes

- O gate nao registra candidato.
- O gate nao troca projeto selecionado.
- O gate nao autentica provider.
- O gate nao cria worktree.
- O gate nao inicia runtime.
- O gate nao executa comandos.
- O gate nao gasta tokens.
- O gate nao escreve remoto.

## Para leigos

Esta etapa responde:

> O candidato ja pode virar projeto registrado?

Neste corte, a resposta e:

> Ainda nao. Falta uma decisao humana aprovada.
