#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "uso: $0 /caminho/do/projeto" >&2
  exit 2
fi

target=$1
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

mkdir -p "$target/docs/exec-packs/backlog" "$target/docs/exec-packs/active" "$target/docs/exec-packs/done" "$target/docs/decisions" "$target/artifacts"

echo "ARTEMIS bootstrap concluido. Revise AGENTS.md, CLAUDE.md e ARCHITECTURE.md antes de usar."

