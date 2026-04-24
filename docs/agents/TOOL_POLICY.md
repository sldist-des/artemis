# Tool Policy

Politica de ferramentas do repositorio ARTEMIS.

## Permitido sem escalonamento

- leitura local com `rg`, `sed`, `find`, `git status`, `git diff`;
- edicao local no escopo do Exec Pack;
- `scripts/validate-artemis.sh`;
- `sh -n` em scripts shell;
- commits locais com mensagem Lore.

## Requer escalonamento humano

- criar remoto GitHub;
- fazer push;
- configurar owners reais;
- configurar branch protection/rulesets;
- adicionar secrets;
- instalar dependencia;
- alterar workflow para deploy.

## Proibido nesta fase

- deploy;
- escrita em producao;
- migracoes destrutivas;
- armazenamento de secrets no repositorio;
- sobrescrever arquivos de projeto alvo no bootstrap sem modo explicito e documentado.

