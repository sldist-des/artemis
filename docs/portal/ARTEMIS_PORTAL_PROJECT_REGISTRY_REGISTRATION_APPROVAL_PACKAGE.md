# ARTEMIS Portal Project Registry Registration Approval Package

Este corte empacota o dry-run de registro para decisao humana.

## Regra central

Pacote de aprovacao nao e aprovacao.

```text
Registration Dry Run
  -> Approval Package
  -> human decision template
  -> waiting_for_human_approval
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que o pacote contem

- Rascunho dos registros que seriam escritos.
- Preview de diff aceito ou rejeitado pelo humano.
- Plano de rollback aceito ou rejeitado pelo humano.
- Template de decisao com opcoes `approved`, `rejected` e `deferred`.
- Comandos de validacao que precisam ser aceitos antes de uma escrita futura.

## Invariantes

- O pacote nao registra aprovacao sozinho.
- O pacote nao escreve registry.
- O pacote nao registra candidato.
- O pacote nao troca projeto selecionado.
- O pacote nao autentica provider.
- O pacote nao cria worktree.
- O pacote nao inicia runtime.
- O pacote nao executa comandos.
- O pacote nao gasta tokens.
- O pacote nao escreve remoto.

## Para leigos

Esta etapa responde:

> O que eu preciso aprovar, rejeitar ou deixar para depois?

Neste corte, a resposta e:

> Aqui esta o pacote de decisao. Nada foi aprovado ainda.

