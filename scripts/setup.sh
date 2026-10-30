#!/usr/bin/env bash
# PROPÓSITO: preparar o repositório base de vibecoding na máquina — validar
# pré-requisitos, criar a árvore de diretórios, marcar scripts como executáveis
# e exibir (sem instalar nada sozinho) os comandos das ferramentas auxiliares.
#
# Idempotente: pode rodar quantas vezes quiser. Não instala pacote, não usa rede.
# Uso: bash scripts/setup.sh

set -euo pipefail

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

REQUIRED_DIRS=(
  skills
  security/rules
  security/scripts
  token-optimization
  scripts
  docs
)

FAILURES=0
WARNINGS=0

# ---------------------------------------------------------------- pré-requisitos

step "Pré-requisitos"

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  ok "bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
else
  err "bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} — é preciso bash 4+ (para arrays e pipefail)"
  FAILURES=$((FAILURES + 1))
fi

if command -v git >/dev/null 2>&1; then
  ok "git $(git --version | awk '{print $3}')"
else
  err "git ausente — instale com: sudo dnf install git  (ou apt install git)"
  FAILURES=$((FAILURES + 1))
fi

if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [[ "${NODE_MAJOR:-0}" -ge 18 ]]; then
    ok "node $(node -v) (fetch nativo disponível)"
  else
    err "node $(node -v) — é preciso Node 18+ (usado por security/scripts/verify-deps.mjs)"
    FAILURES=$((FAILURES + 1))
  fi
else
  err "node ausente — instale Node 18+ (https://nodejs.org) ou use nvm"
  FAILURES=$((FAILURES + 1))
fi

# Opcionais: só avisam, não bloqueiam.
if command -v python3 >/dev/null 2>&1; then
  ok "python3 $(python3 --version 2>&1 | awk '{print $2}') (opcional: ShrinkWrap, VibeGuard)"
else
  warn "python3 ausente — ShrinkWrap (pip) e VibeGuard não poderão ser instalados"
  WARNINGS=$((WARNINGS + 1))
fi

# ------------------------------------------------------------------- estrutura

step "Estrutura de diretórios"

for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ -d "$ROOT/$dir" ]]; then
    ok "$dir/ (já existia)"
  else
    mkdir -p "$ROOT/$dir"
    ok "$dir/ (criado)"
  fi
done

# --------------------------------------------------------------- permissões

step "Permissões de execução"

chmod_dir() {
  local dir="$1" pattern="$2" count=0 file
  [[ -d "$ROOT/$dir" ]] || return 0
  while IFS= read -r -d '' file; do
    chmod +x "$file"
    count=$((count + 1))
  done < <(find "$ROOT/$dir" -maxdepth 1 -type f -name "$pattern" -print0 2>/dev/null)
  ok "$dir/$pattern — $count arquivo(s) com +x"
}

chmod_dir "scripts" "*.sh"
chmod_dir "security/scripts" "*.mjs"

# ------------------------------------------------------------------ ferramentas

step "Ferramentas auxiliares (instale você mesmo — nada é instalado aqui)"

cat <<'EOF'
skillshare — sincroniza skills entre harnesses (Claude Code, Codex, Cursor, Gemini…)
   Linux/macOS:  curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
   Homebrew:     brew install skillshare
   Uso:          skillshare init -p && skillshare sync

ShrinkWrap — proxy MCP que resume payloads grandes (token-optimization/README.md)
   pip install shrinkwrap-cli
   shrinkwrap install && shrinkwrap status && shrinkwrap benchmark

VibeGuard — linter de segurança para código gerado por IA (opcional; escolha o repositório)
   git clone https://github.com/zeroFhacker/vibeguard.git
   cd vibeguard && python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt

RTK — comprime saída de comandos de terminal antes de virar contexto
   brew install rtk        (depois: rtk gain — confirma que instalou o rtk certo)
EOF

# --------------------------------------------------------------------- resumo

step "Resumo"

if [[ "$FAILURES" -gt 0 ]]; then
  err "$FAILURES pré-requisito(s) faltando. Corrija acima e rode novamente."
  exit 1
fi

ok "ambiente pronto (${WARNINGS} aviso(s) opcional(ais))"
printf '\nPróximos passos:\n'
printf '  1. bash scripts/sync.sh            # atualiza skills e valida dependências\n'
printf '  2. export PATH="$HOME/.local/bin:$PATH"   # se skillshare foi para ~/.local/bin\n'
printf '  3. leia AGENTS.md                  # regras que valem para qualquer harness\n'
