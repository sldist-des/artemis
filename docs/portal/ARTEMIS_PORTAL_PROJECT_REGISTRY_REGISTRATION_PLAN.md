# ARTEMIS Portal Project Registry Registration Plan

Este corte transforma o caminho aprovado do Project Registry em um plano de
registro declarativo, sem escrever o registro real.

## Regra central

Plano de registro nao e registro.

```text
Approved Decision Fixture
  -> Registration Plan
  -> ready_for_registration_execution_gate
  -> no registry write
  -> no project switch
  -> no runtime
```

## O que o plano define

- Qual candidato seria registrado.
- Quais registros seriam preparados.
- Quais gates precisam existir antes de escrever.
- Como manter auditoria, rollback e validacao antes de qualquer mutacao.

## Invariantes

- O plano nao registra candidato.
- O plano nao troca projeto selecionado.
- O plano nao autentica provider.
- O plano nao cria worktree.
- O plano nao inicia runtime.
- O plano nao executa comandos.
- O plano nao gasta tokens.
- O plano nao escreve remoto.

## Para leigos

Esta etapa responde:

> O que exatamente aconteceria se formos registrar esse projeto?

Neste corte, a resposta e:

> Temos um plano claro, mas ainda nao executamos nada.
