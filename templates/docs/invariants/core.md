# Invariantes Centrais

Estas regras protegem o projeto contra drift de arquitetura e operacao.

## Processo

- Toda tarefa relevante deve ter issue ou Exec Pack.
- Um worktree deve ter um agente escritor principal.
- Mudancas fora de escopo exigem novo pacote ou escalonamento.
- Toda entrega deve ter evidencia suficiente para revisao.

## Seguranca

- Nunca registrar secrets em codigo, issue, PR, prompt, artifact ou log.
- Auth, permissoes, billing, dados sensiveis e producao exigem revisao humana.
- Deploy e migracao destrutiva exigem aprovacao explicita.

## Arquitetura

- Contratos publicos so mudam com documentacao e revisao.
- Mudancas estruturais exigem ADR.
- Nova dependencia exige justificativa e revisao.

