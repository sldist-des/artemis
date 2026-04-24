# RISKS - ARTEMIS Bootstrap Run 01

## Riscos restantes

- Os templates usam placeholders como `@owner`; precisam ser ajustados por projeto antes de ativar CODEOWNERS ou rulesets.
- O Capability Registry marca capacidades como `verificar`; cada projeto deve confirmar documentacao oficial antes de tratar recursos como ativos.
- Ainda nao ha Git neste diretorio, entao nao ha evidencia de commit, PR ou CI.
- O bootstrap copia arquivos sem sobrescrever existentes; projetos com estrutura diferente podem exigir ajuste manual.

## Riscos nao assumidos nesta rodada

- Nenhum deploy.
- Nenhuma escrita em GitHub.
- Nenhuma instalacao de dependencia.
- Nenhuma mudanca em producao.

