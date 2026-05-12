# ARTEMIS Portal Workspace Session

O Workspace Session e o contrato que impede um assignment de chegar ao
launcher sem um projeto, worktree, branch policy e writer lock explicitos.

Ele nao cria worktree, nao troca branch, nao inicia agente e nao executa
comando. Ele define a fronteira de workspace que o portal deve validar antes de
qualquer Codex, Claude Code ou agente futuro tocar o projeto.

## Regra central

Workspace aprovado nao e permissao de execucao. Ele apenas permite que o
launcher preflight continue avaliando o assignment com uma area de trabalho
conhecida.

```text
Run Assignment
  -> Budget Ledger
  -> Workspace Session
  -> Writer lock
  -> Dirty worktree policy
  -> Launcher preflight
```

## Session record

Campos obrigatorios:

- `workspace_session_id`
- `assignment_id`
- `project_id`
- `ticket`
- `agent_profile_id`
- `workspace_policy_id`
- `budget_policy_id`
- `repository_path`
- `worktree_path`
- `branch_policy`
- `writer_lock`
- `allowed_write_roots`
- `forbidden_paths`
- `dirty_worktree_policy`
- `validation_policy_id`
- `opened_at`
- `expires_at`
- `session_state`
- `evidence`

Campos proibidos:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `provider_billing_secret`
- `runtime_command_output`
- `git_remote_token`
- `ssh_private_key`

## Workspace policies

### Single writer worktree

- maximo de um escritor por worktree;
- writer lock obrigatorio;
- verificador deve usar sessao separada ou read-only;
- remote write bloqueado;
- dirty state precisa ser detectado e reportado antes do launch.

### Read-only review

- nenhum escritor;
- sem writer lock;
- remote write bloqueado;
- nenhuma mudanca permitida no worktree.

## Regras de enforcement

- Workspace Session precisa consumir Run Assignment aceito e Budget Ledger
  pronto.
- Agente escritor precisa de writer lock exclusivo antes do launcher preflight.
- Agente verificador precisa de read-only ou sessao separada.
- Dirty worktree precisa ser detectado e reportado antes de runtime.
- Paths proibidos nao podem ser escritos por agentes gerenciados pelo portal.
- Remote write, branch protection e deploy exigem Human Gate separado.
- Workspace aprovado nao libera execucao sozinho.
- Session record nao pode guardar secrets, tokens, chaves privadas ou output
  bruto de comando.

## Fora de escopo neste corte

- criar worktree real;
- trocar branch;
- iniciar Codex app-server ou Claude Code;
- autenticar provider;
- emitir vault lease real;
- executar comando;
- gastar tokens;
- fazer push, PR, deploy ou mutacao remota.

Proximo corte recomendado: `TKT-078 - ARTEMIS Portal Runtime Session Contract`.
