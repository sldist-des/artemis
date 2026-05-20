# ARTEMIS Portal Project Selector Registry Intake

O Registry Intake e a camada entre o `Local Project Connect`, o registro externo
e o `Project Selector`.

Ele existe para evitar que o portal confunda tres coisas diferentes:

- projeto atual do metodo ARTEMIS;
- projeto candidato detectado por terminal;
- projeto selecionado para runtime real.

## Regra central

Um candidato pode entrar no registry como leitura revisavel, mas isso nao
seleciona projeto nem libera runtime.

```text
Terminal connect
  -> External Project Registration candidate
  -> Registry Intake
  -> Project Selector read model
  -> Workspace/Runtime gates
```

## Estados

- `selected_read_only`: projeto atual conhecido e visivel.
- `candidate_review_pending`: projeto vindo do terminal, aguardando revisao.
- `registered_read_only`: projeto aceito para aparecer no registry, ainda sem runtime.
- `runtime_blocked`: qualquer projeto sem gates completos.

## Invariantes

- Browser nao fornece caminho de projeto.
- Servidor nao escaneia diretorios.
- Registry nao guarda secrets.
- Registry nao autentica providers.
- Registry nao cria worktree.
- Registry nao troca branch.
- Registry nao inicia agentes.
- Registry nao executa comandos.
- Registry nao gasta tokens.

## Para leigos

Este corte responde:

> Quais projetos o portal conhece sem ainda deixar agentes mexerem neles?

Hoje a resposta deve ser pequena:

- projeto ativo: ARTEMIS em `/srv/veri`;
- candidato: projeto conectado pelo terminal;
- runtime: bloqueado.

## Fora de escopo

- aprovar projeto externo;
- trocar projeto selecionado;
- criar seletor editavel;
- abrir navegador de arquivos;
- iniciar Codex, Claude Code ou Antigravity CLI;
- conectar auth;
- executar comandos;
- gastar tokens;
- fazer push ou deploy.
