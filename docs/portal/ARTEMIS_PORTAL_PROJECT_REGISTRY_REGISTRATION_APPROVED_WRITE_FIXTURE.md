# ARTEMIS Portal Project Registry Registration Approved Write Fixture

Este corte cria uma fixture aprovada controlada para provar o caminho positivo
do intake de aprovacao de escrita.

## Regra central

Fixture aprovada nao e aprovacao real.

```text
Approval Package
  -> synthetic approved decision
  -> Approval Intake
  -> approved_for_registry_write_gate
  -> write gate can be planned
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que a fixture prova

- O template do pacote pode virar uma decisao aprovada bem formada.
- O intake reconhece candidato, escopo, caminhos, comandos e timestamp.
- O estado `approved_for_registry_write_gate` e alcancavel.
- Mesmo no caminho positivo, escrita real continua bloqueada.

## Invariantes

- A fixture e sintetica e nao substitui aprovacao humana real.
- A fixture nao escreve registry.
- A fixture nao registra candidato.
- A fixture nao troca projeto selecionado.
- A fixture nao autentica provider.
- A fixture nao cria worktree.
- A fixture nao inicia runtime.
- A fixture nao executa comandos.
- A fixture nao gasta tokens.
- A fixture nao escreve remoto.

## Para leigos

Esta etapa responde:

> Se uma pessoa aprovar corretamente, o metodo entende essa aprovacao?

Neste corte, a resposta e:

> Sim, mas ainda sem executar nada. Isso apenas permite desenhar a proxima trava.
