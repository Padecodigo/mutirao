#!/usr/bin/env bash
# PROPÓSITO: manter skills, regras de segurança e dependências sincronizadas —
# atualiza skills via skillshare (desativado por padrão), valida as regras
# estáticas (sintaxe, caracteres invisíveis, trava de segredo), confere os
# pacotes declarados contra o registro npm e sincroniza submódulos git.
#
# Uso: bash scripts/sync.sh [--skillshare] [--help]
#   --skillshare   roda 'skillshare update --all' e 'skillshare sync' (rede)
#
# Saída: código 0 se tudo passou; 1 se qualquer verificação falhou.
# Nada é instalado e nenhum segredo é impresso.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_DIM=$'\033[2m'; C_R=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_R=""
fi

ok()   { printf '%s✓%s %s\n' "$C_OK" "$C_R" "$*"; }
warn() { printf '%s!%s %s\n' "$C_WARN" "$C_R" "$*"; }
err()  { printf '%s✗%s %s\n' "$C_ERR" "$C_R" "$*" >&2; }
step() { printf '\n%s== %s ==%s\n' "$C_DIM" "$*" "$C_R"; }

ENABLE_SKILLSHARE=0
for arg in "$@"; do
  case "$arg" in
    --skillshare) ENABLE_SKILLSHARE=1 ;;
    -h|--help)
      sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      err "argumento desconhecido: $arg (use --skillshare ou --help)"
      exit 2
      ;;
  esac
done

FAILURES=0
WARNINGS=0

cd "$ROOT" || exit 1

# ------------------------------------------------------------- 1. skillshare

step "1/5 Skills (skillshare)"

if [[ "$ENABLE_SKILLSHARE" -eq 1 ]]; then
  if ! command -v skillshare >/dev/null 2>&1; then
    err "skillshare não encontrado no PATH — instale (scripts/setup.sh mostra como) e rode de novo"
    FAILURES=$((FAILURES + 1))
  else
    # Atualiza o catálogo e sincroniza as skills para as ferramentas configuradas.
    if skillshare update --all; then
      ok "skillshare update --all"
    else
      err "skillshare update --all falhou"
      FAILURES=$((FAILURES + 1))
    fi

    if skillshare sync; then
      ok "skillshare sync"
    else
      err "skillshare sync falhou"
      FAILURES=$((FAILURES + 1))
    fi
  fi
else
  warn "skillshare desativado (padrão). Use 'bash scripts/sync.sh --skillshare' para atualizar skills."
  WARNINGS=$((WARNINGS + 1))
fi

SKILL_COUNT="$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
ok "skills locais: $SKILL_COUNT"

# ------------------------------------------------------------ 2. segurança

step "2/5 Segurança determinística"

# 2a. Sintaxe do verificador de dependências.
if node --check security/scripts/verify-deps.mjs 2>/dev/null; then
  ok "verify-deps.mjs: sintaxe válida"
else
  err "verify-deps.mjs: erro de sintaxe (node --check)"
  FAILURES=$((FAILURES + 1))
fi

# 2b. Arquivos obrigatórios da camada de segurança.
for required in security/rules/security-rules.md security/vibeguard.yaml; do
  if [[ -f "$required" ]]; then
    ok "$required presente"
  else
    err "$required ausente"
    FAILURES=$((FAILURES + 1))
  fi
done

# 2c. Caracteres invisíveis / zero-width (prompt injection oculto).
if git rev-parse --git-dir >/dev/null 2>&1; then
  ZW_PATTERN='[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{2069}\x{FEFF}]'
  if ZW_HITS="$(git grep -I -n --untracked -P "$ZW_PATTERN" -- . 2>/dev/null)"; then
    err "caracteres invisíveis encontrados:"
    printf '%s\n' "$ZW_HITS" | sed 's/^/    /' >&2
    FAILURES=$((FAILURES + 1))
  else
    ok "nenhum caractere invisível (zero-width/bidi)"
  fi
else
  warn "não é um repositório git — varredura de caracteres invisíveis ignorada"
  WARNINGS=$((WARNINGS + 1))
fi

# 2d. Trava de segredo do próprio projeto, se existir.
if [[ -x "$ROOT/mutirao" ]]; then
  if "$ROOT/mutirao" guard scan >/dev/null 2>&1; then
    ok "mutirao guard scan: nenhum segredo"
  else
    err "mutirao guard scan encontrou problema — rode 'mutirao guard scan' e corrija"
    FAILURES=$((FAILURES + 1))
  fi
else
  warn "CLI 'mutirao' ausente — trava de segredo não verificada"
  WARNINGS=$((WARNINGS + 1))
fi

# --------------------------------------------------------- 3. dependências

step "3/5 Dependências (registro npm)"

DEPS_VERIFIED=0
if [[ -f package.json ]]; then
  if ! command -v node >/dev/null 2>&1; then
    err "node ausente — não é possível validar package.json"
    FAILURES=$((FAILURES + 1))
  else
    mapfile -t DEPS < <(node -e '
      const p = require("./package.json");
      const deps = { ...(p.dependencies || {}), ...(p.devDependencies || {}) };
      Object.keys(deps).forEach((name) => console.log(name));
    ' 2>/dev/null)

    if [[ "${#DEPS[@]}" -eq 0 ]]; then
      ok "package.json sem dependências declaradas"
    else
      if node security/scripts/verify-deps.mjs "${DEPS[@]}"; then
        ok "${#DEPS[@]} dependência(s) confirmadas no registro"
        DEPS_VERIFIED="${#DEPS[@]}"
      else
        err "uma ou mais dependências não existem (ou não puderam ser verificadas) — NÃO instale"
        FAILURES=$((FAILURES + 1))
      fi
    fi
  fi
else
  warn "package.json ausente — nada para validar nesta etapa"
  WARNINGS=$((WARNINGS + 1))
fi

# ------------------------------------------------------------- 4. submódulos

step "4/5 Submódulos git"

if [[ -f .gitmodules ]]; then
  if git submodule sync --recursive >/dev/null 2>&1; then
    ok "submodule sync"
  else
    err "git submodule sync falhou"
    FAILURES=$((FAILURES + 1))
  fi

  if git submodule update --init --recursive >/dev/null 2>&1; then
    ok "submodule update --init"
  else
    err "git submodule update --init falhou (rede/permissão?)"
    FAILURES=$((FAILURES + 1))
  fi
else
  ok "sem .gitmodules — nada a sincronizar"
fi

# ------------------------------------------------------------------ 5. resumo

step "5/5 Resumo da sincronização"

BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "—")"
DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

printf '  branch:            %s\n' "$BRANCH"
printf '  arquivos alterados: %s\n' "$DIRTY"
printf '  skills locais:      %s\n' "$SKILL_COUNT"
printf '  dependências ok:    %s\n' "$DEPS_VERIFIED"
printf '  skillshare:         %s\n' "$([[ "$ENABLE_SKILLSHARE" -eq 1 ]] && echo "executado" || echo "desativado")"
printf '  avisos:             %s\n' "$WARNINGS"
printf '  falhas:             %s\n' "$FAILURES"

if [[ "$FAILURES" -gt 0 ]]; then
  printf '\n%sSincronização incompleta: corrija as %s falha(s) acima.%s\n' "$C_ERR" "$FAILURES" "$C_R" >&2
  exit 1
fi

printf '\n%sSincronização concluída.%s\n' "$C_OK" "$C_R"
