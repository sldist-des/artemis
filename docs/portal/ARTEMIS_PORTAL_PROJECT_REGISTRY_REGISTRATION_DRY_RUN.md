# ARTEMIS Portal Project Registry Registration Dry Run

Este corte gera uma simulacao auditavel da escrita no Project Registry.

## Regra central

Dry-run nao e registro.

```text
Registration Execution Gate
  -> Registration Dry Run
  -> draft records
  -> diff preview
  -> rollback plan
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que o dry-run produz

- Rascunho dos registros que seriam escritos.
- Preview de diff em linguagem revisavel.
- Plano de rollback para uma escrita futura.
- Comandos de validacao sugeridos para o pacote de aprovacao.

## Invariantes

- O dry-run nao escreve registry.
- O dry-run nao registra candidato.
- O dry-run nao troca projeto selecionado.
- O dry-run nao autentica provider.
- O dry-run nao cria worktree.
- O dry-run nao inicia runtime.
- O dry-run nao executa comandos por provider.
- O dry-run nao gasta tokens.
- O dry-run nao escreve remoto.

## Para leigos

Esta etapa responde:

> Se eu aprovar depois, o que exatamente vai ser escrito?

Neste corte, a resposta e:

> Aqui esta a previa. Nada foi escrito ainda.

