# ARTEMIS — Modelo Operacional de GitHub
## Integração de repositório, equipe, Claude Code e Codex

**Versão:** 1.0  
**Status:** documento-base  
**Aplica-se a:** projetos ARTEMIS em GitHub, VPS Linux, Claude Code, Codex, GitHub Actions e trabalho em equipe.  
**Documento relacionado:** `fluxo-artemis-claude-codex-v1.3.md` e `artemis-arquitetura-agentes.md`.

---

## 1. Propósito

Este documento define como o **GitHub** deve ser usado dentro do processo **ARTEMIS**.

No ARTEMIS, o GitHub não é apenas o lugar onde o código fica hospedado. Ele se torna o **plano de coordenação** entre:

- humano arquiteto;
- pessoa parceira ou equipe;
- Claude Code;
- Codex;
- CI/CD;
- revisão de código;
- rastreabilidade de tarefas;
- governança de segurança.

A regra central é:

> **o terminal executa; o GitHub coordena, registra, revisa e protege.**

---

## 2. Tese do GitHub dentro do ARTEMIS

O ARTEMIS usa o repositório local, worktrees e sessões de terminal para execução profunda. O GitHub entra como camada de governança e colaboração.

Cada unidade relevante de trabalho deve ter correspondência clara entre:

```text
Issue ou Exec Pack
    ↓
Branch de trabalho
    ↓
Worktree local/VPS
    ↓
Commits rastreáveis
    ↓
Pull Request
    ↓
CI + revisão por IA
    ↓
Revisão humana
    ↓
Merge controlado
    ↓
Registro de handoff
```

Sem isso, a IA tende a gerar muitas mudanças difíceis de auditar. Com isso, a IA pode trabalhar muito, mas sempre dentro de trilhos visíveis.

---

## 3. Onde cada coisa deve viver

### 3.1 GitHub Issues

Issues são usadas para registrar demanda, intenção e rastreabilidade.

Usar Issues para:

- features;
- bugs;
- tarefas técnicas;
- dívidas de arquitetura;
- investigações;
- refactors relevantes;
- tarefas delegadas a agentes.

Uma issue ARTEMIS deve conter ou apontar para um **Exec Pack**.

### 3.2 Exec Packs no repositório

Exec Packs continuam vivendo no repositório, preferencialmente em:

```text
docs/exec-packs/backlog/
docs/exec-packs/active/
docs/exec-packs/done/
```

A issue aponta para o Exec Pack. O Exec Pack contém o contrato operacional completo.

### 3.3 Branches

Branches são unidades de alteração.

Formato recomendado:

```text
ai/<agente>/<ticket>-<slug>
human/<pessoa>/<ticket>-<slug>
fix/<ticket>-<slug>
feature/<ticket>-<slug>
```

Exemplos:

```text
ai/claude/tkt-142-quota-workspace
ai/codex/tkt-143-review-auth
human/joao/tkt-144-architecture-boundary
```

### 3.4 Pull Requests

Pull Requests são unidades de revisão.

Um PR ARTEMIS precisa demonstrar:

- o que foi feito;
- por que foi feito;
- quais arquivos foram alterados;
- quais testes foram executados;
- quais riscos permanecem;
- se houve mudança arquitetural;
- se precisa de ADR;
- se fecha uma issue.

### 3.5 GitHub Actions

GitHub Actions são a primeira camada de evidência automática.

O mínimo esperado:

- lint;
- testes;
- build;
- verificação de tipos, quando aplicável;
- checagem de documentação crítica;
- checagem de arquitetura, quando houver script próprio;
- análise de dependências e segurança, conforme maturidade do projeto.

### 3.6 GitHub Rulesets e Branch Protection

Rulesets e branch protection são a camada de proteção do processo.

No ARTEMIS, `main` ou `master` nunca deve ser uma branch livre.

---

## 4. Modelo mínimo de colaboração

### 4.1 Trabalho solo

Mesmo sozinho, use GitHub como se houvesse equipe.

Fluxo mínimo:

1. criar issue;
2. criar Exec Pack;
3. criar branch;
4. criar worktree;
5. executar com Claude Code ou Codex;
6. abrir PR;
7. pedir revisão por IA;
8. revisar evidências;
9. merge.

Isso treina o processo para crescer sem mudar de cultura depois.

### 4.2 Trabalho com outra pessoa

Quando houver mais uma pessoa no projeto, aplicar estas regras:

- ninguém faz push direto para `main`;
- todo trabalho entra por PR;
- PR de IA precisa de pelo menos um humano revisor;
- mudanças em áreas sensíveis exigem CODEOWNER;
- mudanças arquiteturais exigem ADR;
- PR grande demais deve ser quebrado;
- conflitos devem ser resolvidos no menor escopo possível.

### 4.3 Trabalho com múltiplos agentes

Quando Claude Code e Codex participarem do mesmo projeto:

- um agente executor por branch/worktree;
- outro agente pode atuar como revisor;
- se dois agentes implementarem em paralelo, devem usar issues e branches diferentes;
- nunca deixar dois agentes editarem o mesmo worktree;
- nunca permitir que um agente faça merge final sem revisão humana, salvo em automações pequenas e explicitamente autorizadas.

---

## 5. Papéis no GitHub

### 5.1 Humano Arquiteto

Responsável por:

- definir arquitetura;
- aprovar mudanças estruturais;
- manter `AGENTS.md`, `CLAUDE.md`, docs de invariantes e ADRs;
- revisar PRs de risco;
- decidir merge final.

### 5.2 Pessoa Colaboradora

Responsável por:

- revisar PRs;
- abrir issues;
- executar tarefas próprias;
- comentar riscos;
- manter seu escopo de trabalho sincronizado com o padrão ARTEMIS.

### 5.3 Claude Code

Uso recomendado no GitHub:

- responder a issues e PRs via GitHub Actions quando configurado;
- implementar tarefas pequenas ou médias a partir de issue clara;
- criar PRs a partir de comandos explícitos;
- revisar código conforme `CLAUDE.md` e instruções do repositório;
- atuar como executor em VPS/terminal para tarefas profundas.

### 5.4 Codex

Uso recomendado no GitHub:

- revisar PRs com `@codex review`;
- executar tarefas contextuais em PRs quando mencionado;
- atuar no terminal/VPS com `codex` ou `codex exec`;
- automatizar revisões locais antes de abrir PR;
- validar mudanças contra `AGENTS.md` e guidelines do repositório.

### 5.5 GitHub Actions

Responsável por:

- validar alterações;
- bloquear merge quando evidências mínimas falham;
- proteger deploys;
- publicar artefatos;
- executar rotinas de qualidade.

---

## 6. Configuração recomendada do repositório

### 6.1 Arquivos mínimos

```text
.github/
├── ISSUE_TEMPLATE/
│   ├── artemis_task.yml
│   ├── bug_report.yml
│   └── architecture_change.yml
├── PULL_REQUEST_TEMPLATE.md
├── CODEOWNERS
└── workflows/
    ├── ci.yml
    ├── artemis-guards.yml
    └── security.yml

AGENTS.md
CLAUDE.md
AI_OPERATING_CHARTER.md
artemis-arquitetura-agentes.md
docs/exec-packs/
docs/decisions/
docs/invariants/
docs/quality/
```

### 6.2 `AGENTS.md`

`AGENTS.md` deve orientar Codex e outros agentes.

Deve conter:

- resumo do projeto;
- mapa dos documentos;
- comandos de validação;
- guidelines de revisão;
- regras de segurança;
- limites arquiteturais;
- instruções para PRs.

### 6.3 `CLAUDE.md`

`CLAUDE.md` deve orientar Claude Code.

Deve conter:

- contexto essencial;
- comandos permitidos;
- padrões do projeto;
- política de implementação;
- quando escalar ao humano;
- como registrar handoff.

### 6.4 `CODEOWNERS`

Usar CODEOWNERS para áreas sensíveis e responsabilidades.

Exemplo:

```text
# Arquitetura e governança
/ARCHITECTURE.md              @usuario-arquiteto
/docs/decisions/              @usuario-arquiteto
/docs/invariants/             @usuario-arquiteto

# Segurança e CI
/.github/workflows/           @usuario-arquiteto
/SECURITY.md                  @usuario-arquiteto

# Código-fonte por domínio
/src/auth/                    @usuario-arquiteto @pessoa-seguranca
/src/billing/                 @usuario-arquiteto
/src/api/                     @time-backend
```

### 6.5 Pull request template

Criar `.github/PULL_REQUEST_TEMPLATE.md`:

~~~md
# Pull Request ARTEMIS

## Resumo
<!-- O que mudou e por quê? -->

## Issue / Exec Pack
Closes #
Exec Pack: `docs/exec-packs/active/...`

## Tipo de mudança
- [ ] Feature
- [ ] Bugfix
- [ ] Refactor
- [ ] Documentação
- [ ] Arquitetura
- [ ] Segurança
- [ ] CI/CD

## Escopo
Arquivos/pacotes principais alterados:

## Fora de escopo
O que deliberadamente não foi feito:

## Evidências
- [ ] Lint executado
- [ ] Testes executados
- [ ] Build executado
- [ ] Revisão por IA executada
- [ ] Documentação atualizada
- [ ] ADR criada/atualizada, se necessário

Comandos executados:

```bash
# colar aqui
```

## Riscos e rollback
Riscos conhecidos:

Plano de rollback:

## Checklist ARTEMIS
- [ ] O escopo bate com o Exec Pack
- [ ] Não houve mudança arquitetural sem ADR
- [ ] Não foram adicionados segredos ao código
- [ ] Não houve push direto em branch protegida
- [ ] O PR está pequeno o suficiente para revisão humana
- [ ] O handoff foi registrado
~~~

---

## 7. Labels recomendadas

Criar labels para governar o fluxo:

```text
artemis:exec-pack
artemis:needs-context
artemis:ready-for-agent
artemis:in-progress
artemis:needs-human-review
artemis:needs-architecture-review
artemis:blocked
artemis:handoff-ready

agent:claude
agent:codex
agent:human
agent:review-only

risk:low
risk:medium
risk:high
risk:security
risk:migration
risk:production

area:architecture
area:backend
area:frontend
area:infra
area:docs
area:tests
area:security
```

Uso prático:

- `artemis:ready-for-agent` significa que a issue já tem contexto suficiente para IA.
- `artemis:needs-human-review` bloqueia merge humano.
- `risk:high` exige revisão arquitetural.
- `agent:claude` ou `agent:codex` indica agente executor preferencial.

---

## 8. GitHub Projects

Para equipe, usar GitHub Projects como quadro operacional.

Campos recomendados:

```text
Status
Priority
Risk
Agent
Owner
Exec Pack
Area
Target Milestone
Review State
```

Status recomendados:

```text
Backlog
Needs Context
Ready for Agent
In Progress
Needs AI Review
Needs Human Review
Changes Requested
Ready to Merge
Done
```

Regra importante:

> O quadro mostra estado; o Exec Pack mostra contrato; o PR mostra evidência.

---

## 9. Rulesets e branch protection

### 9.1 Branch `main`

Configuração recomendada:

- exigir pull request antes de merge;
- exigir pelo menos uma aprovação humana;
- exigir CODEOWNERS em áreas críticas;
- exigir status checks de CI;
- exigir conversa resolvida antes de merge;
- bloquear force push;
- bloquear deleção de branch;
- exigir histórico linear, se o time preferir squash/rebase;
- restringir quem pode fazer bypass;
- exigir deploy em staging antes de produção, quando aplicável.

### 9.2 Branches de release

Formato:

```text
release/YYYY-MM-DD
release/vX.Y.Z
```

Regras:

- proteção igual ou superior à `main`;
- deploy controlado por environment;
- rollback documentado;
- changelog obrigatório.

### 9.3 Push rulesets

Usar push rulesets para bloquear:

- arquivos grandes indevidos;
- extensões perigosas;
- paths proibidos;
- alterações diretas em áreas sensíveis;
- arquivos de segredo por padrão de nome.

Exemplos de paths sensíveis:

```text
.env
*.pem
*.key
secrets/**
production/**
```

---

## 10. Segurança de secrets e ambientes

### 10.1 Secrets

Regras:

- não colar secrets em issue, PR, commit, prompt ou Exec Pack;
- usar GitHub Secrets, environment secrets ou solução externa de secrets;
- dar permissão mínima;
- preferir tokens de curta duração quando possível;
- registrar quem pode alterar secrets;
- separar secrets de staging e production.

### 10.2 Environments

Criar ambientes:

```text
staging
production
```

Para `production`:

- exigir aprovação humana;
- impedir self-review quando possível;
- limitar branches que podem fazer deploy;
- registrar logs de deploy;
- exigir rollback plan.

---

## 11. Integração com Claude Code no GitHub

### 11.1 Papel recomendado

Claude Code no GitHub deve ser usado para:

- implementar tarefas a partir de issue bem descrita;
- responder dúvidas em PR;
- criar PRs para mudanças pequenas/médias;
- revisar alterações conforme `CLAUDE.md`;
- automatizar tarefas repetíveis via GitHub Actions.

### 11.2 Gatilhos recomendados

Comentários úteis:

```text
@claude leia esta issue e proponha um plano antes de implementar.
```

```text
@claude implemente esta tarefa seguindo o Exec Pack e abra um PR pequeno.
```

```text
@claude revise este PR contra CLAUDE.md, ARCHITECTURE.md e docs/invariants/.
```

### 11.3 Restrições

Claude não deve:

- alterar produção;
- criar secrets;
- remover regras de proteção;
- modificar arquitetura sem ADR;
- fazer mudanças grandes sem plano;
- expandir escopo sem comentário explícito.

---

## 12. Integração com Codex no GitHub

### 12.1 Papel recomendado

Codex no GitHub deve ser usado principalmente para:

- revisão de PR;
- detecção de problemas P0/P1;
- correção de CI em PRs;
- pequenas tarefas contextuais;
- segunda opinião sobre segurança, arquitetura ou regressões.

### 12.2 Gatilhos recomendados

```text
@codex review
```

```text
@codex review for architecture violations and security regressions
```

```text
@codex fix the CI failures without changing product behavior
```

```text
@codex review this PR against AGENTS.md and docs/invariants/
```

### 12.3 Guidelines no AGENTS.md

Adicionar ao `AGENTS.md` uma seção específica:

```md
## Review guidelines

- Trate vazamento de secrets como P0.
- Trate quebra de autenticação/autorização como P0.
- Trate violação de invariantes arquiteturais como P1.
- Trate mudança de contrato público sem documentação como P1.
- Trate testes ausentes em código crítico como P1.
- Não sinalize preferências cosméticas como bloqueadoras, salvo quando contrariem padrão explícito.
```

---

## 13. Fluxo de trabalho recomendado com VPS

### 13.1 Primeiro setup

Na VPS, usar usuário não-root:

```bash
adduser artemis
usermod -aG sudo artemis
su - artemis
```

Instalar ferramentas mínimas:

```bash
sudo apt update
sudo apt install -y git gh tmux jq ripgrep fd-find make curl
```

Autenticar GitHub CLI:

```bash
gh auth login
```

Clonar repositório:

```bash
mkdir -p /srv/ai-factory/projects/meu-projeto
cd /srv/ai-factory/projects/meu-projeto
gh repo clone ORG/REPO repo
mkdir -p worktrees artifacts sessions cache tmp
```

### 13.2 Criar branch e worktree para uma tarefa

```bash
cd /srv/ai-factory/projects/meu-projeto/repo
git fetch origin

git checkout main
git pull --ff-only

git branch ai/claude/tkt-142-quota-workspace

git worktree add ../worktrees/tkt-142--claude ai/claude/tkt-142-quota-workspace
```

### 13.3 Abrir PR pelo terminal

```bash
cd ../worktrees/tkt-142--claude

git status
git push -u origin ai/claude/tkt-142-quota-workspace

gh pr create   --base main   --title "TKT-142: implementar quota por workspace"   --body-file artifacts/tkt-142/pr-body.md
```

### 13.4 Pedir revisão por IA

```bash
gh pr comment --body "@codex review for architecture violations, security regressions, and missing tests"
```

Se Claude GitHub Action estiver configurado:

```bash
gh pr comment --body "@claude revise este PR contra CLAUDE.md, ARCHITECTURE.md e docs/invariants/."
```

---

## 14. Fluxo padrão de uma tarefa em equipe

### 14.1 Issue

Criar issue com:

- problema;
- contexto;
- impacto;
- link para Exec Pack;
- agente sugerido;
- risco;
- responsável humano.

### 14.2 Exec Pack

Criar arquivo:

```text
docs/exec-packs/active/tkt-142-quota-workspace.md
```

### 14.3 Branch/worktree

Criar branch isolada.

### 14.4 Execução

Claude Code ou Codex implementa.

### 14.5 PR

Abrir PR com template completo.

### 14.6 Revisão por IA

Pedir revisão de Codex e/ou Claude.

### 14.7 Revisão humana

Humano revisa:

- contrato;
- evidências;
- arquitetura;
- risco;
- testes;
- escopo.

### 14.8 Merge

Merge apenas se:

- CI passou;
- revisão humana aprovada;
- comments resolvidos;
- riscos aceitáveis;
- docs atualizadas.

### 14.9 Pós-merge

- mover Exec Pack para `done`;
- atualizar ADR, se necessário;
- arquivar handoff;
- remover worktree;
- fechar issue.

---

## 15. Issue template ARTEMIS

Criar `.github/ISSUE_TEMPLATE/artemis_task.yml`:

```yaml
name: ARTEMIS Task
about: Tarefa operacional para execução por humano ou IA
labels: ["artemis:needs-context"]
body:
  - type: textarea
    id: objective
    attributes:
      label: Objetivo
      description: O que precisa ser feito?
    validations:
      required: true

  - type: textarea
    id: context
    attributes:
      label: Contexto
      description: Links para docs, decisões, telas, logs ou arquivos relevantes.
    validations:
      required: true

  - type: textarea
    id: scope
    attributes:
      label: Escopo
      description: O que está dentro da tarefa?
    validations:
      required: true

  - type: textarea
    id: out_of_scope
    attributes:
      label: Fora de escopo
      description: O que não deve ser alterado?
    validations:
      required: true

  - type: dropdown
    id: risk
    attributes:
      label: Risco
      options:
        - baixo
        - médio
        - alto
        - segurança
        - produção
    validations:
      required: true

  - type: dropdown
    id: suggested_agent
    attributes:
      label: Agente sugerido
      options:
        - humano
        - claude
        - codex
        - claude-exec-codex-review
        - codex-exec-claude-review
    validations:
      required: true

  - type: textarea
    id: acceptance
    attributes:
      label: Critérios de aceite
      description: Como saberemos que está pronto?
    validations:
      required: true
```

---

## 16. Handoff em comentário de PR

Todo PR relevante deve terminar com um comentário de handoff:

```md
## ARTEMIS Handoff

### O que foi entregue

### Arquivos principais alterados

### Evidências
- CI:
- Testes locais:
- Revisão IA:

### Riscos restantes

### Decisões tomadas

### Pendências

### Recomendação do agente
- [ ] pronto para revisão humana
- [ ] precisa de ajuste
- [ ] precisa de decisão arquitetural
```

---

## 17. Políticas de commit

### 17.1 Formato recomendado

```text
type(scope): resumo curto
```

Exemplos:

```text
feat(auth): add workspace quota check
fix(api): handle quota exceeded error
refactor(worker): isolate usage calculation
docs(artemis): add GitHub operating model
```

### 17.2 Commits de IA

Commits feitos por agente devem ser claros e pequenos.

Evitar:

```text
update files
fix stuff
changes
wip
```

Preferir:

```text
feat(quotas): enforce workspace job limit
```

### 17.3 Coautoria

Quando útil, registrar coautoria:

```text
Co-authored-by: Claude <noreply@anthropic.com>
Co-authored-by: Codex <noreply@openai.com>
```

Use apenas se isso fizer sentido no fluxo da equipe e não conflitar com políticas internas.

---

## 18. Rotina semanal de manutenção GitHub

Toda semana, em projeto ativo:

- revisar issues sem contexto;
- fechar PRs mortos;
- atualizar labels;
- revisar branches antigas;
- conferir Rulesets;
- revisar Actions quebradas;
- atualizar `AGENTS.md` e `CLAUDE.md` se ferramentas mudaram;
- revisar se Claude/Codex estão obedecendo os templates;
- registrar melhorias em `docs/quality/`.

Prompt sugerido para agente:

```text
Você é o mantenedor ARTEMIS de GitHub.
Revise issues, PRs, labels, workflows e documentação operacional.
Não altere código de produto.
Entregue uma lista de melhorias com risco, impacto e comandos sugeridos.
```

---

## 19. Níveis de maturidade

### Nível 1 — Solo organizado

- Issues simples;
- PR template;
- CI básico;
- branches isoladas;
- revisão manual.

### Nível 2 — IA assistida

- Codex review em PR;
- Claude Code no terminal;
- Exec Packs obrigatórios;
- labels ARTEMIS;
- handoff em PR.

### Nível 3 — Equipe pequena

- CODEOWNERS;
- branch protection;
- GitHub Projects;
- revisão humana obrigatória;
- environments staging/production.

### Nível 4 — Multiagente controlado

- Claude GitHub Actions;
- Codex GitHub reviews automáticos;
- workflows de arquitetura;
- rulesets por área;
- políticas formais de tools e secrets.

### Nível 5 — Plataforma operacional

- métricas de qualidade;
- automações recorrentes;
- auditoria de agentes;
- integração com MCP, observabilidade e deploy gates;
- relatórios periódicos.

---

## 20. Prompt para IA Preparadora de GitHub

Use este prompt quando quiser que uma IA prepare uma issue, branch, PR ou contexto GitHub para Claude Code ou Codex:

```text
Você é a IA Preparadora de Contexto do processo ARTEMIS.

Sua tarefa é transformar uma demanda em um pacote operacional pronto para GitHub, Claude Code e Codex.

Antes de propor execução, organize:

1. Título da issue.
2. Descrição clara do problema.
3. Escopo.
4. Fora de escopo.
5. Risco.
6. Agente recomendado.
7. Branch sugerida.
8. Exec Pack sugerido.
9. Critérios de aceite.
10. Comandos de validação.
11. Revisores humanos necessários.
12. Se precisa de ADR.
13. Prompt para Claude Code.
14. Prompt para Codex review.
15. Corpo sugerido para Pull Request.

Regras:
- Não expanda escopo.
- Não peça ao agente para mudar produção.
- Não inclua secrets.
- Se houver mudança arquitetural, exija ADR.
- Se houver risco alto, exija revisão humana antes de merge.
- Se a tarefa estiver vaga, marque como artemis:needs-context.
```

---

## 21. Prompt para Claude Code vindo de issue GitHub

```text
Você está operando dentro do processo ARTEMIS.

Leia:
- AGENTS.md
- CLAUDE.md
- ARCHITECTURE.md
- docs/invariants/
- Exec Pack indicado na issue

Tarefa:
<colar link da issue e resumo>

Regras obrigatórias:
- Trabalhe somente no escopo definido.
- Não altere arquitetura sem ADR.
- Não inclua secrets.
- Não faça mudanças de produção.
- Crie testes ou explique tecnicamente por que não são aplicáveis.
- Atualize documentação quando o comportamento mudar.
- Gere um handoff final para comentário no PR.

Antes de implementar, entregue um plano curto com:
1. arquivos prováveis;
2. riscos;
3. validações;
4. dúvidas bloqueantes, se houver.

Depois de implementar, entregue:
1. resumo;
2. arquivos alterados;
3. comandos executados;
4. testes;
5. riscos restantes;
6. texto sugerido para PR.
```

---

## 22. Prompt para Codex review em PR

```text
@codex review for:
- architecture violations against AGENTS.md, ARCHITECTURE.md and docs/invariants/;
- security regressions;
- missing tests in critical code;
- public contract changes without docs;
- excessive scope creep;
- hidden production/deployment risk.

Ignore purely cosmetic preferences unless they violate documented project standards.
```

---

## 23. Checklist de implantação GitHub

Para ativar o ARTEMIS em um repositório GitHub:

```text
[ ] Criar .github/PULL_REQUEST_TEMPLATE.md
[ ] Criar .github/ISSUE_TEMPLATE/artemis_task.yml
[ ] Criar .github/CODEOWNERS
[ ] Criar labels ARTEMIS
[ ] Criar workflow CI
[ ] Criar workflow de guards arquiteturais
[ ] Ativar branch protection ou ruleset em main
[ ] Exigir PR antes de merge
[ ] Exigir status checks
[ ] Exigir revisão humana
[ ] Configurar environments staging/production, se houver deploy
[ ] Adicionar Review guidelines ao AGENTS.md
[ ] Adicionar política operacional ao CLAUDE.md
[ ] Configurar Codex review, se disponível
[ ] Configurar Claude GitHub Actions somente após fluxo base estar estável
```

---

## 24. Regra final

O GitHub, dentro do ARTEMIS, não é burocracia.

Ele existe para permitir que a IA trabalhe muito sem que o humano perca o controle.

> **Issue define intenção. Exec Pack define contrato. Branch isola execução. PR concentra evidência. Rulesets protegem o sistema. Revisão humana preserva arquitetura.**

---

## 25. Referências oficiais de manutenção

Como GitHub, Claude Code e Codex mudam com frequência, revisar periodicamente:

- GitHub Docs — Rulesets, branch protection, CODEOWNERS, GitHub Actions, environments e secrets.
- OpenAI Developers — Codex, Codex GitHub integration, Codex CLI, changelog e feature maturity.
- Claude Code Docs — GitHub Actions, hooks, skills, subagents, permissions e changelog.

Este documento deve ser revisado sempre que alguma dessas ferramentas mudar permissões, integrações GitHub, modelo de revisão, execução cloud, Actions, sandbox ou políticas de segurança.
