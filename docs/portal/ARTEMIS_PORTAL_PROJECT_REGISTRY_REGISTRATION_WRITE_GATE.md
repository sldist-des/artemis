# ARTEMIS Portal Project Registry Registration Write Gate

Este corte separa evidencia sintetica de autoridade real para escrita do
Project Registry.

## Regra central

Fixture aprovada prova o caminho; nao autoriza escrita.

```text
Approved Write Fixture
  -> Write Gate
  -> real-human write approval template
  -> waiting_for_real_human_write_approval
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que o gate exige

- Fixture aprovada pronta.
- Reconhecimento explicito de que a fixture e sintetica.
- Decisao humana real separada.
- Escopo `project_registry_registration_real_write`.
- Target aceito.
- Rascunho de escrita aceito.
- Diff preview aceito.
- Rollback plan aceito.
- Comandos de validacao aceitos.

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

> Temos permissao real para escrever no registro?

No caminho padrao, a resposta e:

> Ainda nao. A fixture mostrou que o metodo entende a aprovacao, mas uma pessoa
> precisa aprovar a escrita real separadamente.
