#!/usr/bin/env bash
# Áreas de trabalho paralelas: um agente por worktree, para que dois agentes
# nunca editem o mesmo arquivo ao mesmo tempo.
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tools/lib/common.sh
source "$SELF_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
uso: mutirao worktree <ação>

  new <nome> [--base <ref>]   Cria uma área de trabalho isolada para um agente
  list                        Lista as áreas ativas
  status                      Mostra o que cada agente mudou
  remove <nome> [--force]     Apaga a área (e a branch) de um agente
  prune                       Limpa referências de áreas já apagadas na mão

Exemplos
  mutirao worktree new frontend
  mutirao worktree new backend --base main
  mutirao worktree status
  mutirao worktree remove frontend

Por que isso existe
  Dois agentes editando o mesmo arquivo no mesmo diretório viram conflito e
  trabalho perdido. Cada worktree é uma cópia isolada do projeto, com a sua
  própria branch. O Revisor junta depois.
EOF
}

ROOT="$(repo_root)" || die "rode dentro do projeto (git)."
WT_ROOT="$ROOT/.mutirao/worktrees"

default_base() {
  local ref
  if ref="$(git -C "$ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    printf '%s\n' "$ref"
    return 0
  fi
  if git -C "$ROOT" show-ref --verify --quiet refs/heads/main; then
    printf 'main\n'
    return 0
  fi
  if git -C "$ROOT" show-ref --verify --quiet refs/heads/master; then
    printf 'master\n'
    return 0
  fi
  git -C "$ROOT" rev-parse --abbrev-ref HEAD
}

validate_name() {
  local name
  name="$(slugify "$1")"
  [[ -n "$name" ]] || die "nome inválido: '$1'"
  printf '%s\n' "$name"
}

cmd_new() {
  local raw="${1:-}" base=""
  shift || true
  [[ -n "$raw" ]] || die "uso: mutirao worktree new <nome> [--base <ref>]"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base) base="${2:-}"; [[ -n "$base" ]] || die "--base precisa de um valor"; shift 2 ;;
      *) die "argumento desconhecido: $1" ;;
    esac
  done

  local name branch path
  name="$(validate_name "$raw")"
  branch="agente/$name"
  path="$WT_ROOT/$name"
  base="${base:-$(default_base)}"

  if ! git -C "$ROOT" rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    die "base '$base' não existe neste repositório."
  fi
  if [[ -e "$path" ]]; then
    die "já existe uma área para '$name' em $path"
  fi

  mkdir -p "$WT_ROOT"

  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    warn "branch $branch já existe; reaproveitando"
    git -C "$ROOT" worktree add "$path" "$branch"
  else
    git -C "$ROOT" worktree add -b "$branch" "$path" "$base"
  fi

  ok "área de '$name' pronta: $path"
  info "  branch: $branch (a partir de $base)"
  info ""
  info "Abra o seu agente DENTRO dessa pasta, por exemplo:"
  dim "  cd \"$path\" && claude   # ou codex, gemini, cursor…"
  info ""
  info "Regras da casa:"
  info "  • o agente só mexe nos arquivos da sua tarefa"
  info "  • não faz merge sozinho — quem junta é o Revisor"
  info "  • antes de juntar, rode: mutirao worktree status"
}

cmd_list() {
  if [[ ! -d "$WT_ROOT" ]]; then
    info "nenhuma área de agente ainda."
    return 0
  fi
  title "Áreas de trabalho"
  local dir name branch dirty
  for dir in "$WT_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    dir="${dir%/}"
    name="$(basename -- "$dir")"
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    dirty="$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    printf '  %-14s %-22s %s arquivo(s) alterado(s)\n' "$name" "$branch" "$dirty"
  done
}

cmd_status() {
  if [[ ! -d "$WT_ROOT" ]]; then
    info "nenhuma área de agente ainda."
    return 0
  fi
  local dir name base ahead
  base="$(default_base)"
  for dir in "$WT_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    dir="${dir%/}"
    name="$(basename -- "$dir")"
    ahead="$(git -C "$dir" rev-list --count "$base..HEAD" 2>/dev/null || echo '?')"
    title "$name"
    info "  commits à frente de $base: $ahead"
    git -C "$dir" status --short 2>/dev/null | sed 's/^/  /' || true
    local stat
    stat="$(git -C "$dir" diff --stat "$base...HEAD" 2>/dev/null | tail -1 || true)"
    if [[ -n "$stat" ]]; then
      info "  $stat"
    fi
  done
}

cmd_remove() {
  local raw="${1:-}" force=""
  shift || true
  [[ -n "$raw" ]] || die "uso: mutirao worktree remove <nome> [--force]"
  [[ "${1:-}" == "--force" ]] && force="--force"

  local name path branch
  name="$(validate_name "$raw")"
  path="$WT_ROOT/$name"
  branch="agente/$name"

  [[ -d "$path" ]] || die "não existe área para '$name'."

  if [[ -z "$force" ]] && [[ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]]; then
    warn "há mudanças não commitadas em $name."
    confirm "Apagar mesmo assim e perder essas mudanças?" || die "cancelado."
    force="--force"
  fi

  # shellcheck disable=SC2086
  git -C "$ROOT" worktree remove $force "$path"
  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    # shellcheck disable=SC2086
    git -C "$ROOT" branch -D $force "$branch" >/dev/null 2>&1 || warn "branch $branch não removida (tem commits não juntados?)"
  fi
  ok "área '$name' removida."
}

cmd_prune() {
  git -C "$ROOT" worktree prune
  ok "referências de worktree limpas."
}

action="${1:-help}"
[[ $# -gt 0 ]] && shift

case "$action" in
  new)     cmd_new "$@" ;;
  list|ls) cmd_list ;;
  status|st) cmd_status ;;
  remove|rm) cmd_remove "$@" ;;
  prune)   cmd_prune ;;
  help|-h|--help) usage ;;
  *) fail "ação desconhecida: $action"; info ""; usage; exit 2 ;;
esac
