#!/usr/bin/env bash
# Impede que chaves e senhas entrem no repositório.
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tools/lib/common.sh
source "$SELF_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
uso: mutirao guard <ação>

  scan                 Varre o projeto inteiro (arquivos versionados e novos)
  staged               Varre só o que está indo para o próximo commit
  install              Instala a trava automática antes de cada commit
  uninstall            Remove a trava
  rules                Lista o que é procurado

Rode 'scan' sempre que terminar uma tarefa. Se aparecer algo, NÃO faça commit:
apague o valor do arquivo e ponha a chave no cofre (mutirao vault set).

A trava (install) roda sozinha antes de cada commit e recusa o commit.
EOF
}

# tipo | expressão regular
PATTERNS=(
  'chave-privada|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'aws-access-key|AKIA[0-9A-Z]{16}'
  'github-token|(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}'
  'github-pat|github_pat_[A-Za-z0-9_]{50,}'
  'openai-key|sk-(proj-|svcacct-)?[A-Za-z0-9]{32,}'
  'anthropic-key|sk-ant-[A-Za-z0-9_-]{24,}'
  'stripe-live|(sk|rk)_live_[A-Za-z0-9]{20,}'
  'google-api-key|AIza[0-9A-Za-z_-]{35}'
  'slack-token|xox[abprs]-[A-Za-z0-9-]{10,}'
  'jwt|eyJ[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.'
  'atribuicao-suspeita|(api[_-]?key|apikey|secret[_-]?key|access[_-]?token|client[_-]?secret|password|senha)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{16,}["'"'"']'
)

# Arquivos que nunca devem ser versionados.
FORBIDDEN_NAMES='(^|/)\.env(\..+)?$'
FORBIDDEN_EXT='\.(pem|key|p12|pfx|jks|keystore)$'

is_allowed_name() {
  local path="$1"
  [[ "$path" == *.env.example ]] && return 0
  [[ "$path" == *.env.sample ]] && return 0
  [[ "$path" == */.mutirao/* ]] && return 0
  return 1
}

# Arquivos ignorados sempre (mesmo se versionados por engano).
is_skipped() {
  local path="$1"
  case "$path" in
    .git/*|*/.git/*) return 0 ;;
    .mutirao/*|*/.mutirao/*) return 0 ;;
    node_modules/*|*/node_modules/*) return 0 ;;
    dist/*|*/dist/*|build/*|*/build/*) return 0 ;;
    vendor/*|*/vendor/*) return 0 ;;
    tools/guard.sh) return 0 ;;
  esac
  return 1
}

FINDINGS=0
declare -A SEEN=()

report() {
  local file="$1" line="$2" kind="$3"
  local key="$file:$line:$kind"
  [[ -n "${SEEN[$key]:-}" ]] && return 0
  SEEN["$key"]=1
  FINDINGS=$((FINDINGS + 1))
  printf '%s✘%s %s:%s  %s[%s]%s\n' \
    "$C_RED" "$C_RESET" "$file" "$line" "$C_YELLOW" "$kind" "$C_RESET"
}

report_file() {
  local file="$1" why="$2"
  FINDINGS=$((FINDINGS + 1))
  printf '%s✘%s %s  %s[%s]%s\n' "$C_RED" "$C_RESET" "$file" "$C_YELLOW" "$why" "$C_RESET"
}

scan_text_stream() {
  # Lê "arquivo:linha:texto" (formato do grep -n) sem imprimir o texto.
  local kind="$1"
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    local file line
    file="${hit%%:*}"
    line="${hit#*:}"
    line="${line%%:*}"
    report "$file" "$line" "$kind"
  done
}

# ------------------------------------------------------------------ varredura

scan_worktree() {
  local -a files=()
  local f

  if ! repo_root >/dev/null 2>&1; then
    die "rode dentro do projeto (git)."
  fi

  while IFS= read -r -d '' f; do
    is_skipped "$f" && continue
    files+=("$f")
  done < <(git ls-files -z --cached --others --exclude-standard 2>/dev/null)

  # Nomes proibidos
  for f in "${files[@]}"; do
    is_allowed_name "$f" && continue
    if [[ "$f" =~ $FORBIDDEN_NAMES ]] || [[ "$f" =~ $FORBIDDEN_EXT ]]; then
      report_file "$f" "arquivo-de-segredo"
    fi
  done

  # Conteúdo
  local entry kind re
  for entry in "${PATTERNS[@]}"; do
    kind="${entry%%|*}"
    re="${entry#*|}"
    if (( ${#files[@]} )); then
      scan_text_stream "$kind" < <(grep -EnI -E -- "$re" "${files[@]}" 2>/dev/null || true)
    fi
  done
}

scan_staged() {
  local f
  if ! repo_root >/dev/null 2>&1; then
    die "rode dentro do projeto (git)."
  fi

  local -a staged=()
  while IFS= read -r -d '' f; do
    [[ -z "$f" ]] && continue
    is_skipped "$f" && continue
    staged+=("$f")
    is_allowed_name "$f" || {
      if [[ "$f" =~ $FORBIDDEN_NAMES ]] || [[ "$f" =~ $FORBIDDEN_EXT ]]; then
        report_file "$f" "arquivo-de-segredo"
      fi
    }
  done < <(git diff --cached --name-only --diff-filter=ACMR -z 2>/dev/null)

  (( ${#staged[@]} )) || return 0

  local entry kind re
  for entry in "${PATTERNS[@]}"; do
    kind="${entry%%|*}"
    re="${entry#*|}"
    scan_text_stream "$kind" < <(git grep --cached -nI -E -- "$re" 2>/dev/null || true)
  done
}

finish() {
  if (( FINDINGS > 0 )); then
    info ""
    fail "$FINDINGS problema(s) encontrado(s)."
    info "  O que fazer:"
    info "   1. apague o valor do arquivo (deixe a variável vazia)"
    info "   2. guarde a chave no cofre:  mutirao vault set NOME"
    info "   3. declare no projeto:       mutirao vault add NOME"
    info "   4. rode de novo:             mutirao guard scan"
    exit 1
  fi
  ok "nenhum segredo encontrado."
}

# ---------------------------------------------------------------------- hook

install_hook() {
  local root hook
  root="$(repo_root)" || die "rode dentro do projeto (git)."
  hook="$root/.git/hooks/pre-commit"

  if [[ -f "$hook" ]]; then
    if grep -q "mutirao guard" "$hook" 2>/dev/null; then
      ok "trava já instalada."
      return 0
    fi
    warn "já existe um hook pre-commit que não é do Mutirão."
    confirm "Substituir? (cópia de segurança em pre-commit.bak)" || die "cancelado."
    cp "$hook" "$hook.bak"
  fi

  cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# Instalado pelo Mutirão — impede commit com segredos.
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
guard="$root/tools/guard.sh"
if [[ ! -x "$guard" ]]; then
  echo "✘ Mutirão: a trava de segredos não foi encontrada em tools/guard.sh" >&2
  echo "  Restaure com: mutirao init --force" >&2
  echo "  Ou remova a trava: mutirao guard uninstall" >&2
  exit 1
fi
exec "$guard" staged
HOOK
  chmod +x "$hook"
  ok "trava instalada: o commit é recusado se houver segredo."
}

uninstall_hook() {
  local root hook
  root="$(repo_root)" || die "rode dentro do projeto (git)."
  hook="$root/.git/hooks/pre-commit"
  if [[ -f "$hook" ]] && grep -q "mutirao guard" "$hook" 2>/dev/null; then
    rm -f "$hook"
    ok "trava removida."
  else
    info "nenhuma trava do Mutirão instalada."
  fi
}

action="${1:-scan}"
shift || true

case "$action" in
  scan)
    scan_worktree
    finish
    ;;
  staged)
    scan_staged
    finish
    ;;
  install) install_hook ;;
  uninstall) uninstall_hook ;;
  rules)
    title "O que o Mutirão procura"
    for entry in "${PATTERNS[@]}"; do
      printf '  %-22s %s\n' "${entry%%|*}" "${entry#*|}"
    done
    unset entry
    info ""
    info "  arquivos: .env, *.pem, *.key, *.p12, *.pfx (exceto .env.example)"
    ;;
  help|-h|--help) usage ;;
  *)
    fail "ação desconhecida: $action"
    usage
    exit 2
    ;;
esac
