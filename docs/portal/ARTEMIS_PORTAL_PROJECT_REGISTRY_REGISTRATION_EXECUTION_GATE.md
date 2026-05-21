# ARTEMIS Portal Project Registry Registration Execution Gate

Este corte cria o gate que impede escrita real no Project Registry sem aprovacao
humana real e pacote minimo de execucao.

## Regra central

Plano pronto nao autoriza escrita.

```text
Registration Plan
  -> Registration Execution Gate
  -> waiting_for_real_human_execution_approval
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que o gate exige

- Aprovacao humana real, nao fixture sintetica.
- Escopo de aprovacao igual a `project_registry_registration_execution`.
- Alvo de escrita declarado.
- Preview de diff.
- Plano de rollback.
- Comandos de validacao.
- Racional da decisao.

## Invariantes

- O gate nao escreve registry.
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

> Ja temos permissao real para escrever esse registro?

Neste corte, a resposta e:

> Ainda nao. O plano esta pronto, mas falta aprovacao humana real e evidencias de execucao.
