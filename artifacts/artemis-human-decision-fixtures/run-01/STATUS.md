# STATUS

## Resultado

TKT-030 criou fixtures sinteticas para decisoes humanas de cleanup.

## Mudancas

- `scripts/artemis-human-decision-fixtures.sh` gera fixtures read-only.
- Fixtures cobrem `approved`, `deferred`, `rejected` e dois casos invalidos.
- Caminhos de worktree, lock e branch sao sinteticos.
- Nenhuma fixture deve ser usada com `--execute`.

## Fixtures

- `approved-exact`: aprovacao valida com comandos exatos.
- `deferred`: decisao valida de adiamento sem comandos aprovados.
- `rejected`: decisao valida de rejeicao sem comandos aprovados.
- `invalid-partial-approval`: aprovacao parcial invalida.
- `invalid-missing-metadata`: aprovacao invalida por metadata ausente.

## Invariantes preservados

- Nenhum cleanup foi executado.
- Fixtures nao autorizam cleanup real.
- Executor permanece dry-run por padrao.
- Casos invalidos falham no contrato antes de qualquer execucao.
