# ARTEMIS Control Plane Operational Decision Home

Este corte corrige a home do Control Plane para mostrar informacao operacional,
nao apenas contadores.

## Regra central

A primeira tela deve responder:

```text
O que falta?
Onde mexer?
O que continua bloqueado?
```

## Estado visivel

- Proxima acao: preencher decisao humana.
- Arquivo: `project-registry-decision-template.json`.
- Bloqueio: registro, troca de projeto e runtime bloqueados.

## Invariantes

- A home nao registra candidato.
- A home nao troca projeto.
- A home nao autentica provider.
- A home nao inicia runtime.
- A home nao executa comandos.
- A home nao gasta tokens.
- A home nao escreve remoto.

## Para leigos

Esta tela passa a dizer:

> O projeto esta parado porque falta preencher uma decisao humana. O arquivo
> certo esta indicado na tela. Enquanto isso, nada roda automaticamente.
