# ARTEMIS Control Plane Project Registry Home State

Esta camada valida que a home humana do Control Plane consome o Registry Intake
sem voltar a mostrar auditoria tecnica na primeira tela.

## Regra central

A home mostra estado, nao maquinaria.

```text
Project Selector Registry Intake
  -> home: projeto selecionado
  -> home: candidato em revisao
  -> home: runtime bloqueado
```

## O que aparece para o humano

- Estado atual do metodo.
- Projeto selecionado.
- Candidato em revisao, quando existir.
- Runtime bloqueado.
- Links curtos para resumo, validacao e handoff.

## O que nao aparece na home

- Board tecnico.
- Timeline de eventos.
- Grafo completo.
- Provider chips.
- Caminhos de artefatos.
- Fonte JSON.
- Comandos internos.

## Invariantes

- A home nao aprova candidato.
- A home nao troca projeto.
- A home nao autentica provider.
- A home nao inicia runtime.
- A home nao executa comandos.
- A home nao gasta tokens.

## Para leigos

Esta tela responde:

> Em qual projeto estamos e se ja podemos rodar agente?

Neste corte, a resposta e:

> Estamos no projeto ARTEMIS. Existe candidato em revisao. Ainda nao pode rodar
> agente.
