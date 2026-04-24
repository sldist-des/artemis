# Tool Policy

Esta politica separa ferramentas por risco.

## Leitura segura

Permitido normalmente:

- `rg`, `find`, `sed`, `cat`, `git diff`, `git status`;
- leitura de docs locais;
- leitura de logs sem secrets.

## Escrita local controlada

Permitido dentro do escopo do Exec Pack:

- editar arquivos no worktree;
- criar docs e artifacts;
- atualizar testes relacionados.

## Execucao local

Permitido quando listado no Exec Pack:

- lint;
- testes;
- build;
- scripts nao destrutivos.

## Rede e MCP externo

Requer politica explicita:

- GitHub;
- issue tracker;
- Figma;
- observabilidade;
- bancos somente leitura;
- documentacao externa.

## Acoes sensiveis

Requer aprovacao humana:

- deploy;
- producao;
- banco real;
- secrets;
- billing;
- auth/permissoes;
- migracoes destrutivas;
- integracoes externas com escrita.

