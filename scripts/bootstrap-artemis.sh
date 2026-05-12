#!/usr/bin/env sh
set -eu

usage() {
  cat >&2 <<'EOF'
uso: scripts/bootstrap-artemis.sh [--profile lite|full] /caminho/do/projeto

perfis:
  lite  contrato comum, templates, guias curtos e helper de integracao
  full  lite + Control Plane local e gerador de tasks.json
EOF
}

profile="lite"
target=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      if [ -z "$profile" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --profile=*)
      profile=${1#--profile=}
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "opcao desconhecida: $1" >&2
      usage
      exit 2
      ;;
    *)
      if [ -n "$target" ]; then
        echo "apenas um diretorio alvo e permitido" >&2
        usage
        exit 2
      fi
      target=$1
      shift
      ;;
  esac
done

case "$profile" in
  lite|full) ;;
  *)
    echo "profile invalido: $profile" >&2
    usage
    exit 2
    ;;
esac

if [ -z "$target" ]; then
  usage
  exit 2
fi

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ ! -d "$target" ]; then
  echo "diretorio alvo nao existe: $target" >&2
  exit 1
fi

copy_one() {
  src=$1
  dst=$2
  if [ -e "$dst" ]; then
    echo "skip: $dst ja existe"
    return 0
  fi
  mkdir -p "$(dirname -- "$dst")"
  cp "$src" "$dst"
  echo "created: $dst"
}

find "$root/templates" -type f | while IFS= read -r src; do
  rel=${src#"$root/templates/"}
  copy_one "$src" "$target/$rel"
done

copy_one "$root/ARTEMIS_QUICKSTART.md" "$target/ARTEMIS_QUICKSTART.md"
copy_one "$root/ARTEMIS_WORKFLOW.md" "$target/ARTEMIS_WORKFLOW.md"
copy_one "$root/ARTEMIS_APPLY.md" "$target/ARTEMIS_APPLY.md"
copy_one "$root/ARTEMIS_INTEGRATIONS.md" "$target/ARTEMIS_INTEGRATIONS.md"
copy_one "$root/scripts/artemis-integrations.sh" "$target/scripts/artemis-integrations.sh"

if [ "$profile" = "full" ]; then
  copy_one "$root/control-plane/index.html" "$target/control-plane/index.html"
  copy_one "$root/control-plane/tasks.json" "$target/control-plane/tasks.json"
  copy_one "$root/scripts/artemis-tasks.sh" "$target/scripts/artemis-tasks.sh"
fi

mkdir -p "$target/docs/exec-packs/backlog" "$target/docs/exec-packs/active" "$target/docs/exec-packs/done" "$target/docs/decisions" "$target/artifacts" "$target/scripts"

echo "ARTEMIS bootstrap concluido com profile=$profile."
echo "Revise AGENTS.md, CLAUDE.md, ARCHITECTURE.md e ARTEMIS_INTEGRATIONS.md antes de usar."
