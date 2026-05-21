# ARTEMIS Portal Project Registry Registration Approval Intake

Este corte classifica a decisao humana do pacote de aprovacao de registro.

## Regra central

Intake de aprovacao nao e escrita.

```text
Registration Approval Package
  -> decision file
  -> classify pending / approved / rejected / deferred / invalid
  -> validate candidate, paths, commands and timestamp
  -> no registry write
  -> no project switch
  -> no runtime
```

## Estados

- `pending`: nenhum humano registrou decisao valida.
- `approved_for_registry_write_gate`: a decisao foi aprovada e pode alimentar
  um gate futuro de escrita.
- `rejected`: o candidato continua nao registrado.
- `deferred`: o pacote continua aguardando decisao posterior.
- `invalid`: a decisao existe, mas falhou em campo, caminho, timestamp ou
  comando aceito.

## Invariantes

- O intake nao escreve registry.
- O intake nao registra candidato.
- O intake nao troca projeto selecionado.
- O intake nao autentica provider.
- O intake nao cria worktree.
- O intake nao inicia runtime.
- O intake nao executa comandos.
- O intake nao gasta tokens.
- O intake nao escreve remoto.
- Decisao `approved` so libera um gate futuro; ela nao executa a escrita.

## Para leigos

Esta etapa responde:

> A decisao que chegou pode seguir para a proxima trava?

No caminho padrao, a resposta ainda e:

> Nao. Continua pendente ate uma pessoa preencher e assinar a decisao.
