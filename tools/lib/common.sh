# shellcheck shell=bash
# Helpers compartilhados pelos scripts do Mutirão.
# Carregado com: source tools/lib/common.sh

# shellcheck disable=SC2034  # consumido pelos scripts que carregam este arquivo
MUTIRAO_VERSION="0.1.0"

# Cores só quando a saída é um terminal (não polui logs de CI).
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ -n "${TERM:-}" ]]; then
  C_RESET="$(tput sgr0)"
  C_BOLD="$(tput bold)"
  C_RED="$(tput setaf 1)"
  C_GREEN="$(tput setaf 2)"
  C_YELLOW="$(tput setaf 3)"
  C_DIM="$(tput setaf 8)"
else
  C_RESET=""
  C_BOLD=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_DIM=""
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '%s✔%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail()  { printf '%s✘%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
title() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
dim()   { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }

die() {
  fail "$*"
  exit 1
}

# Caminho absoluto do diretório que contém o script que chamou esta função.
script_dir() {
  local src="${BASH_SOURCE[1]}"
  cd -- "$(dirname -- "$src")" && pwd -P
}

# Raiz do projeto atual. Retorna 1 se não estiver dentro de um repositório git.
repo_root() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  printf '%s\n' "$root"
}

# Raiz do kit (onde ficam AGENTS.md/.agents). Funciona tanto no repo do kit
# quanto num projeto criado por `mutirao init`.
kit_root() {
  local root
  root="$(repo_root)" || return 1
  if [[ -f "$root/AGENTS.md" && -d "$root/.agents" ]]; then
    printf '%s\n' "$root"
    return 0
  fi
  return 1
}

have() { command -v "$1" >/dev/null 2>&1; }

# Confirma com o humano. Em ambiente não interativo, recusa (fail-closed).
confirm() {
  local prompt="${1:-Continuar?}" answer
  if [[ ! -t 0 ]]; then
    warn "sem terminal interativo; assumindo NÃO para: $prompt"
    return 1
  fi
  printf '%s [s/N] ' "$prompt"
  read -r answer
  [[ "$answer" =~ ^[sSyY]$ ]]
}

# Lê uma linha sem ecoar o que foi digitado (para senhas/segredos).
read_secret() {
  local prompt="$1" value
  printf '%s' "$prompt" >&2
  if [[ -t 0 ]]; then
    stty -echo
    # Garante que o terminal volte ao normal mesmo com Ctrl-C.
    trap 'stty echo' INT TERM
    read -r value || true
    stty echo
    trap - INT TERM
  else
    read -r value || true
  fi
  printf '\n' >&2
  printf '%s' "$value"
}

require_git_repo() {
  local root
  root="$(repo_root)" || die "você não está dentro de um projeto git. Rode 'git init' primeiro."
  printf '%s\n' "$root"
}

# Normaliza nomes de agente/branch: minúsculas, sem acento, só [a-z0-9-].
slugify() {
  local s="${1,,}"
  s="${s//[áàãâä]/a}"
  s="${s//[éèêë]/e}"
  s="${s//[íìîï]/i}"
  s="${s//[óòõôö]/o}"
  s="${s//[úùûü]/u}"
  s="${s//[ç]/c}"
  s="${s//[^a-z0-9]/-}"
  s="${s#-}"
  s="${s%-}"
  printf '%s\n' "$s"
}
