#!/usr/bin/env bash
# PROPÓSITO: instalar as ferramentas auxiliares OPCIONAIS (skillshare, RTK,
# ShrinkWrap, VibeGuard) somente quando pedido explicitamente por flag.
# Cada instalação usa o método oficial verificado e é idempotente.
#
# Uso: bash scripts/install-tools.sh [--skillshare] [--rtk] [--shrinkwrap]
#                                    [--vibeguard] [--all] [--dry-run] [--help]
#
# Nada é instalado sem uma flag correspondente. Nenhum segredo é solicitado.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_R=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_R=""
fi

ok()   { printf '%s✓%s %s\n' "$C_OK" "$C_R" "$*"; }
warn() { printf '%s!%s %s\n' "$C_WARN" "$C_R" "$*"; }
err()  { printf '%s✗%s %s\n' "$C_ERR" "$C_R" "$*" >&2; }
info() { printf '  → %s\n' "$*"; }

DRY_RUN=0
WANT_SKILLSHARE=0
WANT_RTK=0
WANT_SHRINKWRAP=0
WANT_VIBEGUARD=0

for arg in "$@"; do
  case "$arg" in
    --skillshare) WANT_SKILLSHARE=1 ;;
    --rtk) WANT_RTK=1 ;;
    --shrinkwrap) WANT_SHRINKWRAP=1 ;;
    --vibeguard) WANT_VIBEGUARD=1 ;;
    --all) WANT_SKILLSHARE=1; WANT_RTK=1; WANT_SHRINKWRAP=1; WANT_VIBEGUARD=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) err "argumento desconhecido: $arg (use --help)"; exit 2 ;;
  esac
done

if [[ "$WANT_SKILLSHARE$WANT_RTK$WANT_SHRINKWRAP$WANT_VIBEGUARD" -eq 0 ]]; then
  err "nada selecionado. Use --skillshare, --rtk, --shrinkwrap, --vibeguard ou --all"
  exit 2
fi

run() {
  info "$*"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  "$@"
}

FAILURES=0

# ------------------------------------------------------------------ skillshare

if [[ "$WANT_SKILLSHARE" -eq 1 ]]; then
  printf '\n== skillshare (sincroniza skills entre harnesses) ==\n'
  if command -v skillshare >/dev/null 2>&1; then
    ok "já instalado: $(skillshare --version 2>/dev/null | head -1)"
  elif command -v brew >/dev/null 2>&1 && [[ "$DRY_RUN" -eq 0 ]]; then
    run brew install skillshare || FAILURES=$((FAILURES + 1))
  else
    # Método oficial quando não há Homebrew (instala em ~/.local/bin).
    if [[ "$DRY_RUN" -eq 1 ]]; then
      info "curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh"
    else
      info "curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh"
      if curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh; then
        ok "skillshare instalado (confira o PATH: ~/.local/bin)"
      else
        err "falha ao instalar skillshare"
        FAILURES=$((FAILURES + 1))
      fi
    fi
  fi
fi

# ------------------------------------------------------------------------- RTK

if [[ "$WANT_RTK" -eq 1 ]]; then
  printf '\n== RTK (comprime saída de comandos) ==\n'
  if command -v rtk >/dev/null 2>&1; then
    ok "já instalado: $(rtk --version 2>/dev/null | head -1)"
  elif command -v brew >/dev/null 2>&1; then
    run brew install rtk || FAILURES=$((FAILURES + 1))
  else
    warn "Homebrew ausente. Instale manualmente: https://github.com/rtk-ai/rtk#installation"
    info "depois confirme com: rtk gain  (se não mostrar o painel, é o rtk errado)"
  fi
fi

# ------------------------------------------------------------------ ShrinkWrap

if [[ "$WANT_SHRINKWRAP" -eq 1 ]]; then
  printf '\n== ShrinkWrap (proxy MCP) ==\n'
  if command -v shrinkwrap >/dev/null 2>&1; then
    ok "já instalado: $(shrinkwrap --version 2>/dev/null | head -1)"
  elif command -v pip3 >/dev/null 2>&1; then
    run pip3 install --user shrinkwrap-cli || FAILURES=$((FAILURES + 1))
    info "depois: shrinkwrap install && shrinkwrap status"
  else
    warn "pip3 ausente — instale Python 3 + pip e rode: pip install shrinkwrap-cli"
  fi
fi

# ------------------------------------------------------------------- VibeGuard

if [[ "$WANT_VIBEGUARD" -eq 1 ]]; then
  printf '\n== VibeGuard (linter de código gerado por IA) ==\n'
  VG_DIR="$ROOT/.cache/tools/vibeguard"
  if [[ -d "$VG_DIR/.git" ]]; then
    ok "já clonado em .cache/tools/vibeguard"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    info "git clone https://github.com/zeroFhacker/vibeguard.git $VG_DIR"
  else
    mkdir -p "$ROOT/.cache/tools"
    if run git clone --depth 1 https://github.com/zeroFhacker/vibeguard.git "$VG_DIR"; then
      ok "clonado em .cache/tools/vibeguard (não versionado)"
      info "instale as dependências dele: python3 -m venv $VG_DIR/venv && $VG_DIR/venv/bin/pip install -r $VG_DIR/requirements.txt"
    else
      err "falha ao clonar VibeGuard"
      FAILURES=$((FAILURES + 1))
    fi
  fi
fi

printf '\n'
if [[ "$FAILURES" -gt 0 ]]; then
  err "$FAILURES instalação(ões) falharam"
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  ok "dry-run concluído (nada foi instalado)"
else
  ok "instalação concluída — confirme com 'bash scripts/sync.sh'"
fi
