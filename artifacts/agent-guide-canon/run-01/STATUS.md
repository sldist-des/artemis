# STATUS - Agent Guide Canon Run 01

## Estado

Concluido.

## Decisao

`AGENTS.md` sera a fonte canonica comum para Codex, Claude Code e outros agentes.

`CLAUDE.md` sera mantido como adaptador fino para Claude Code, apontando para `AGENTS.md` e contendo somente orientacoes especificas do Claude Code.

## Justificativa

Essa estrutura reduz drift entre agentes. Quando a mesma regra aparece em dois arquivos, ela tende a divergir com o tempo.

## Acoes realizadas

- Criado `AGENTS.md` raiz como guia canonico deste repositorio.
- Criado `CLAUDE.md` raiz como adaptador fino.
- Atualizado `templates/CLAUDE.md` para o mesmo padrao.
- Atualizado `README.md` para documentar a regra de canonizacao.
