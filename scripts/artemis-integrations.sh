#!/usr/bin/env sh
set -eu

usage() {
  cat >&2 <<'EOF'
uso: scripts/artemis-integrations.sh [--project /caminho/do/projeto] [--agent codex|claude|both] [--format markdown|json]

Gera blocos curtos para abrir um projeto ARTEMIS em Codex CLI ou Claude Code.
EOF
}

project="."
agent="both"
format="markdown"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      project="${2:-}"
      if [ -z "$project" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --project=*)
      project=${1#--project=}
      shift
      ;;
    --agent)
      agent="${2:-}"
      if [ -z "$agent" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --agent=*)
      agent=${1#--agent=}
      shift
      ;;
    --format)
      format="${2:-}"
      if [ -z "$format" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --format=*)
      format=${1#--format=}
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "opcao desconhecida: $1" >&2
      usage
      exit 2
      ;;
  esac
done

case "$agent" in
  codex|claude|both) ;;
  *)
    echo "agent invalido: $agent" >&2
    usage
    exit 2
    ;;
esac

case "$format" in
  markdown|json) ;;
  *)
    echo "format invalido: $format" >&2
    usage
    exit 2
    ;;
esac

json_escape() {
  printf '%s' "$1" | awk '
    BEGIN { ORS="" }
    {
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\t/, "\\t")
      gsub(/\r/, "")
      gsub(/\n/, "\\n")
      print
    }
  '
}

codex_prompt='Leia AGENTS.md, ARTEMIS_WORKFLOW.md, ARCHITECTURE.md, AI_PROCESS.md e o Exec Pack ativo em docs/exec-packs/active/. Execute apenas o escopo do Exec Pack, registre validacao, riscos e handoff. Nao faca push, merge, producao, secrets ou mudanca fora de escopo sem Human Gate.'

claude_prompt='Leia CLAUDE.md primeiro. Depois siga AGENTS.md como fonte canonica comum. Trabalhe somente pelo Exec Pack ativo, apresente plano curto quando a tarefa nao for trivial, registre validacao e termine com handoff claro.'

health_command='test -f AGENTS.md && test -f CLAUDE.md && test -f ARTEMIS_WORKFLOW.md && test -d docs/exec-packs/active && test -d artifacts'

if [ "$format" = "json" ]; then
  printf '{\n'
  printf '  "schema_version": 1,\n'
  printf '  "project": "%s",\n' "$(json_escape "$project")"
  printf '  "agent": "%s",\n' "$agent"
  printf '  "health_check": "%s",\n' "$(json_escape "$health_command")"
  printf '  "codex": {\n'
  printf '    "command": "cd %s && codex",\n' "$(json_escape "$project")"
  printf '    "prompt": "%s"\n' "$(json_escape "$codex_prompt")"
  printf '  },\n'
  printf '  "claude": {\n'
  printf '    "command": "cd %s && claude",\n' "$(json_escape "$project")"
  printf '    "prompt": "%s"\n' "$(json_escape "$claude_prompt")"
  printf '  }\n'
  printf '}\n'
  exit 0
fi

cat <<EOF
# ARTEMIS integration blocks

Project:

\`\`\`bash
cd $project
$health_command
\`\`\`

EOF

if [ "$agent" = "codex" ] || [ "$agent" = "both" ]; then
  cat <<EOF
## Codex CLI

\`\`\`bash
cd $project
codex
\`\`\`

Paste:

\`\`\`text
$codex_prompt
\`\`\`

EOF
fi

if [ "$agent" = "claude" ] || [ "$agent" = "both" ]; then
  cat <<EOF
## Claude Code

\`\`\`bash
cd $project
claude
\`\`\`

Paste:

\`\`\`text
$claude_prompt
\`\`\`

EOF
fi

cat <<'EOF'
## Full profile local view

Quando o projeto foi instalado com `--profile full`:

```bash
scripts/artemis-tasks.sh --output control-plane/tasks.json
python3 -m http.server 4173
```

Abra `http://127.0.0.1:4173/control-plane/`.
EOF
