# Invariantes Centrais

Estas regras protegem o repositorio ARTEMIS.

## Processo

- Toda tarefa relevante deve ter Exec Pack.
- Toda entrega deve ter evidencia minima.
- Toda mudanca deve ser versionada em Git.
- Commits de agente devem seguir o Lore Commit Protocol.
- `docs/exec-packs/` e o caminho canonico para pacotes de execucao.

## Agentes

- `AGENTS.md` e a fonte canonica comum.
- `CLAUDE.md` e apenas adaptador para Claude Code.
- Regras compartilhadas nao devem ser duplicadas em `CLAUDE.md`.
- Um worktree deve ter um agente escritor principal.

## Templates

- Templates devem continuar copiaveis para outros projetos.
- Nao adicionar dependencia externa ao bootstrap sem decisao explicita.
- Placeholders devem ser seguros por padrao.

## Seguranca

- Nunca versionar secrets.
- `.omx/` e `.codex` locais ficam fora do Git.
- GitHub owners e rulesets reais exigem decisao humana.
- Workflows nao devem fazer deploy.

