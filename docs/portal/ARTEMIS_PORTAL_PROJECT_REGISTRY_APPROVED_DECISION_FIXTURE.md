# ARTEMIS Portal Project Registry Approved Decision Fixture

Este corte cria uma fixture sintetica de decisao humana aprovada para provar o
caminho positivo do Project Registry sem executar a decisao no mundo real.

## Regra central

Fixture aprovada nao e aprovacao real de dono.

```text
Human Review Gate
  -> Approved Decision Fixture
  -> Decision Intake recorded
  -> Registration Gate ready_for_registration_plan
  -> no registration
  -> no project switch
  -> no runtime
```

## O que a fixture prova

- Existe candidato conhecido.
- O arquivo de decisao aprovada tem os campos obrigatorios.
- O Decision Intake aceita a decisao como `recorded`.
- O Registration Gate chega em `ready_for_registration_plan`.
- Registro, troca de projeto, runtime, auth, comandos e tokens continuam
  bloqueados.

## Invariantes

- A fixture nao registra candidato.
- A fixture nao troca projeto selecionado.
- A fixture nao autentica provider.
- A fixture nao cria worktree.
- A fixture nao inicia runtime.
- A fixture nao executa comandos de runtime.
- A fixture nao gasta tokens.
- A fixture nao escreve remoto.

## Para leigos

Esta etapa responde:

> Se uma decisao humana aprovada existir, o fluxo entende isso corretamente?

Neste corte, a resposta e:

> Sim. O fluxo permite preparar um plano de registro, mas ainda nao executa nada.
