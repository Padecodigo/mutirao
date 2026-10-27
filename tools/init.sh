#!/usr/bin/env bash
# Cria um projeto novo a partir do kit Mutirão.
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
KIT_ROOT="$(cd -- "$SELF_DIR/.." && pwd -P)"
# shellcheck source=tools/lib/common.sh
source "$SELF_DIR/lib/common.sh"

FORCE=0
DEST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    -h|--help)
      cat <<'EOF'
uso: mutirao init <pasta> [--force]

Cria um projeto novo com a estrutura do Mutirão:
  AGENTS.md, .agents/, .specify/, tools/, .mutirao/

Nada existente é sobrescrito sem --force.
EOF
      exit 0
      ;;
    -*) die "opção desconhecida: $1" ;;
    *) DEST="$1"; shift ;;
  esac
done

[[ -n "$DEST" ]] || die 'uso: mutirao init <pasta-do-projeto>'

if [[ -e "$DEST" && ! -d "$DEST" ]]; then
  die "'$DEST' existe e não é uma pasta."
fi

mkdir -p "$DEST"
DEST="$(cd -- "$DEST" && pwd -P)"

title "Mutirão · criando projeto em $DEST"

COPIED=0
SKIPPED=0

copy_one() {
  local src="$1" rel="$2"
  local dst="$DEST/$rel"

  if [[ ! -e "$src" ]]; then
    return 0
  fi
  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    warn "já existe, mantido: $rel"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  mkdir -p "$(dirname -- "$dst")"
  cp -R "$src" "$dst"
  ok "criado: $rel"
  COPIED=$((COPIED + 1))
}

copy_one "$KIT_ROOT/AGENTS.md"   "AGENTS.md"
copy_one "$KIT_ROOT/.agents"     ".agents"
copy_one "$KIT_ROOT/.specify"    ".specify"
copy_one "$KIT_ROOT/tools"       "tools"
copy_one "$KIT_ROOT/.env.example" ".env.example"

chmod +x "$DEST"/tools/*.sh "$DEST"/mutirao 2>/dev/null || true
# O projeto novo ganha o próprio atalho ./mutirao
if [[ ! -e "$DEST/mutirao" ]]; then
  cp "$KIT_ROOT/mutirao" "$DEST/mutirao"
  chmod +x "$DEST/mutirao"
  ok "criado: mutirao"
fi

mkdir -p "$DEST/.mutirao"

# .gitignore: só acrescenta o que falta.
GITIGNORE="$DEST/.gitignore"
touch "$GITIGNORE"
add_ignore() {
  local rule="$1"
  if ! grep -qxF "$rule" "$GITIGNORE" 2>/dev/null; then
    printf '%s\n' "$rule" >> "$GITIGNORE"
  fi
}
{
  printf '\n# Mutirão — nunca versione segredos\n'
} >> "$GITIGNORE"
add_ignore ".mutirao/"
add_ignore ".env"
add_ignore ".env.*"
add_ignore "!.env.example"
add_ignore "*.pem"
add_ignore "*.key"

printf 'kit_version=%s\ncriado_em=%s\n' "$MUTIRAO_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$DEST/.mutirao/config"

if [[ ! -d "$DEST/.git" ]]; then
  if git -C "$DEST" init -q 2>/dev/null; then
    ok "git inicializado"
  else
    warn "não consegui rodar 'git init' aqui"
  fi
fi

info ""
ok "Projeto criado: $DEST"
info "  arquivos novos: $COPIED · mantidos: $SKIPPED"
info ""
info "Próximos passos:"
info "  cd \"$DEST\""
info "  ./mutirao doctor"
info "  ./mutirao start \"o que você quer construir\""
info ""
dim "Leia docs/como-comecar.md se quiser o passo a passo em linguagem simples."
