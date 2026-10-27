#!/usr/bin/env bash
# Testes do próprio kit Mutirão.
# Rode:  bash tests/smoke.sh
set -uo pipefail

KIT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
PASS=0
FAIL=0
FAILED=()

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ok()      { PASS=$((PASS + 1)); printf '  ✔ %s\n' "$1"; }
bad()     { FAIL=$((FAIL + 1)); FAILED+=("$1"); printf '  ✘ %s\n' "$1"; }
section() { printf '\n— %s\n' "$1"; }

# expect_ok "nome" comando...
expect_ok() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi
}

expect_fail() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then bad "$name (deveria falhar)"; else ok "$name"; fi
}

run_in() {
  local dir="$1"; shift
  ( cd "$dir" && "$@" )
}

new_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email "teste@mutirao.local"
  git -C "$dir" config user.name "Teste Mutirão"
  printf '# projeto de teste\n' > "$dir/README.md"
  printf '.mutirao/\n' > "$dir/.gitignore"
  git -C "$dir" add README.md .gitignore
  git -C "$dir" commit -qm "primeiro commit"
  printf '%s\n' "$dir"
}

# ================================================================ 1. sintaxe
section "Sintaxe dos scripts"

SYNTAX_BAD=0
while IFS= read -r f; do
  if ! bash -n "$f" 2>/dev/null; then
    bad "erro de sintaxe: ${f#"$KIT"/}"
    SYNTAX_BAD=1
  fi
done < <(find "$KIT" -type f \( -name '*.sh' -o -name 'mutirao' \) \
          -not -path '*/.git/*' -not -path '*/node_modules/*')
(( SYNTAX_BAD == 0 )) && ok "todos os scripts compilam (bash -n)"

# =================================================================== 2. CLI
section "CLI"

expect_ok "mutirao version" \
  run_in "$KIT" ./mutirao version

expect_ok "mutirao help" \
  run_in "$KIT" ./mutirao help

expect_ok "mutirao gate" \
  run_in "$KIT" ./mutirao gate

if run_in "$KIT" ./mutirao start "uma padaria com encomendas" >"$TMPROOT/start.txt" 2>/dev/null; then
  if grep -q "padaria com encomendas" "$TMPROOT/start.txt"; then
    ok "start inclui a ideia no prompt"
  else
    bad "start inclui a ideia no prompt"
  fi
else
  bad "start inclui a ideia no prompt (saiu com erro)"
fi

if run_in "$KIT" ./mutirao gate | grep -q "Portão 1\|Criar conta"; then
  ok "gate lista as 4 paradas"
else
  bad "gate lista as 4 paradas"
fi

expect_ok "comando desconhecido sai com erro" \
  bash -c "cd '$KIT' && ./mutirao comando-que-nao-existe >/dev/null 2>&1 && exit 1 || exit 0"

expect_ok "doctor" \
  run_in "$KIT" ./mutirao doctor

# ================================================================= 3. guard
section "guard (segredo não passa)"

R1="$(new_repo "$TMPROOT/guard")"

# Segredo montado em tempo de execução: o arquivo do teste não contém o padrão.
FAKE="$(printf 'sk_%s_%s' live 0123456789abcdefghijklmnopqrstuv)"
printf 'STRIPE=%s\n' "$FAKE" > "$R1/config.txt"
git -C "$R1" add config.txt

expect_fail "detecta chave no stage" \
  run_in "$R1" "$KIT/tools/guard.sh" staged

expect_ok "arquivo limpo passa" \
  run_in "$R1" bash -c "git rm -q --cached config.txt && rm config.txt && '$KIT/tools/guard.sh' staged"

FAKE2="$(printf 'ghp_%s' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij)"
printf 'token: %s\n' "$FAKE2" > "$R1/token.txt"
expect_fail "detecta token do GitHub" \
  run_in "$R1" bash -c "git add token.txt && '$KIT/tools/guard.sh' staged"

printf 'API_KEY=\n' > "$R1/.env"
expect_fail "bloqueia arquivo .env" \
  run_in "$R1" bash -c "git add -f .env && '$KIT/tools/guard.sh' staged"

git -C "$R1" rm -q --cached token.txt .env 2>/dev/null
rm -f "$R1/token.txt" "$R1/.env"

printf 'API_KEY=\n' > "$R1/.env.example"
expect_ok ".env.example é permitido" \
  run_in "$R1" bash -c "git add .env.example && '$KIT/tools/guard.sh' staged"

# O projeto real tem tools/ (criado pelo `mutirao init`), então simulamos isso.
cp -R "$KIT/tools" "$R1/tools"

expect_ok "guard install cria o hook" \
  run_in "$R1" "$KIT/tools/guard.sh" install

printf 'PASSWORD_TOKEN="%s"\n' "$(printf 'ghp_%s' zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz)" > "$R1/vazou.txt"
git -C "$R1" add vazou.txt
expect_fail "hook recusa commit com segredo" \
  run_in "$R1" git commit -m "tentativa"

expect_ok "guard rules" \
  run_in "$R1" "$KIT/tools/guard.sh" rules

# ============================================================== 4. worktree
section "worktree (paralelo isolado)"

R2="$(new_repo "$TMPROOT/wt")"
( cd "$R2" && git branch -M main )

expect_ok "cria área do agente" \
  run_in "$R2" "$KIT/tools/worktree.sh" new frontend

if [[ -d "$R2/.mutirao/worktrees/frontend" ]]; then
  ok "diretório da worktree existe"
else
  bad "diretório da worktree existe"
fi

if git -C "$R2" show-ref --verify --quiet refs/heads/agente/frontend; then
  ok "branch agente/frontend criada"
else
  bad "branch agente/frontend criada"
fi

expect_ok "worktree list" \
  run_in "$R2" "$KIT/tools/worktree.sh" list

expect_ok "worktree status" \
  run_in "$R2" "$KIT/tools/worktree.sh" status

expect_fail "recusa nome duplicado" \
  run_in "$R2" "$KIT/tools/worktree.sh" new frontend

expect_ok "remove área" \
  run_in "$R2" "$KIT/tools/worktree.sh" remove frontend --force

if [[ ! -d "$R2/.mutirao/worktrees/frontend" ]]; then
  ok "diretório removido"
else
  bad "diretório removido"
fi

# ================================================================= 5. vault
section "vault (chave sem aparecer)"

R3="$(new_repo "$TMPROOT/vault")"

expect_ok "configura provedor de estudo" \
  run_in "$R3" "$KIT/tools/vault.sh" setup --provider env

expect_ok "declara chave" \
  run_in "$R3" "$KIT/tools/vault.sh" add TESTE_CHAVE

if printf 'valor-secreto-123\n' | run_in "$R3" "$KIT/tools/vault.sh" set TESTE_CHAVE >/dev/null 2>&1; then
  ok "guarda valor"
else
  bad "guarda valor"
fi

GET_OUT="$(run_in "$R3" "$KIT/tools/vault.sh" get TESTE_CHAVE 2>/dev/null || true)"
if grep -q "valor-secreto-123" <<< "$GET_OUT"; then
  bad "get não imprime o valor por padrão"
else
  ok "get não imprime o valor por padrão"
fi

expect_ok "vault list mostra a chave" \
  run_in "$R3" "$KIT/tools/vault.sh" list

# shellcheck disable=SC2016  # a variável é expandida no processo filho, de propósito
OUT="$(run_in "$R3" "$KIT/tools/vault.sh" run -- sh -c 'printf %s "$TESTE_CHAVE"' 2>/dev/null)"
if [[ "$OUT" == "valor-secreto-123" ]]; then
  ok "run injeta a chave no processo"
else
  bad "run injeta a chave no processo (obtido: '$OUT')"
fi

if [[ -f "$R3/.mutirao/vault.env" ]]; then
  PERM="$(stat -c '%a' "$R3/.mutirao/vault.env" 2>/dev/null || stat -f '%Lp' "$R3/.mutirao/vault.env" 2>/dev/null || echo '?')"
  if [[ "$PERM" == "600" ]]; then
    ok "arquivo local com permissão 600"
  else
    bad "arquivo local com permissão 600 (obtido: $PERM)"
  fi
else
  bad "arquivo local criado"
fi

if run_in "$R3" git check-ignore -q .mutirao/vault.env; then
  ok ".mutirao é ignorado pelo git"
else
  bad ".mutirao é ignorado pelo git"
fi

expect_ok "vault doctor" \
  run_in "$R3" "$KIT/tools/vault.sh" doctor

# ================================================================== 6. init
section "init (projeto novo)"

DEST="$TMPROOT/novo-projeto"
expect_ok "cria projeto" \
  run_in "$KIT" ./mutirao init "$DEST"

for item in AGENTS.md .agents .specify tools mutirao .gitignore; do
  if [[ -e "$DEST/$item" ]]; then ok "gerou $item"; else bad "gerou $item"; fi
done

if grep -q '^\.mutirao/$' "$DEST/.gitignore"; then
  ok ".gitignore cobre .mutirao"
else
  bad ".gitignore cobre .mutirao"
fi

if [[ -x "$DEST/mutirao" ]]; then
  ok "atalho ./mutirao executável"
else
  bad "atalho ./mutirao executável"
fi

# Segunda execução não deve sobrescrever
printf 'personalizado\n' > "$DEST/AGENTS.md"
run_in "$KIT" ./mutirao init "$DEST" >/dev/null 2>&1
if [[ "$(cat "$DEST/AGENTS.md")" == "personalizado" ]]; then
  ok "init não sobrescreve arquivo existente"
else
  bad "init não sobrescreve arquivo existente"
fi

# ================================================================= 7. links
section "Links da documentação"

if command -v python3 >/dev/null 2>&1; then
  if python3 - "$KIT" <<'PY'
import os, re, sys

root = sys.argv[1]
skip_dirs = {'.git', 'node_modules', '.mutirao'}
bad = []

for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d not in skip_dirs]
    for name in filenames:
        if not name.endswith('.md'):
            continue
        path = os.path.join(dirpath, name)
        try:
            text = open(path, encoding='utf-8').read()
        except OSError:
            continue
        for match in re.finditer(r'\[[^\]]*\]\(([^)]+)\)', text):
            link = match.group(1).strip()
            if link.startswith(('http://', 'https://', 'mailto:', '#')):
                continue
            link = link.split('#')[0].split(' ')[0]
            if not link:
                continue
            target = os.path.normpath(os.path.join(dirpath, link))
            if not os.path.exists(target):
                bad.append(f"{os.path.relpath(path, root)} -> {link}")

for item in bad:
    print(f"  ✘ link quebrado: {item}")

sys.exit(1 if bad else 0)
PY
  then
    ok "todos os links relativos resolvem"
  else
    bad "todos os links relativos resolvem"
  fi
else
  printf '  - python3 ausente: checagem de links ignorada\n'
fi

# ============================================================== 8. primeiro contato
section "primeiro contato (link no chat)"

if [[ -f "$KIT/START.md" ]]; then
  ok "START.md existe"
else
  bad "START.md existe"
fi

if grep -q "usar o Mutirão" "$KIT/START.md" 2>/dev/null; then
  ok "START.md oferece a opção 1 (usar)"
else
  bad "START.md oferece a opção 1 (usar)"
fi

if grep -q "desenvolver o próprio Mutirão" "$KIT/START.md" 2>/dev/null; then
  ok "START.md oferece a opção 2 (desenvolver)"
else
  bad "START.md oferece a opção 2 (desenvolver)"
fi

if grep -q "START.md" "$KIT/llms.txt" 2>/dev/null; then
  ok "llms.txt aponta para o START.md"
else
  bad "llms.txt aponta para o START.md"
fi

if grep -q "START.md" "$KIT/README.md" 2>/dev/null; then
  ok "README aponta para o START.md"
else
  bad "README aponta para o START.md"
fi

HELP_OUT="$(run_in "$KIT" ./mutirao help 2>/dev/null || true)"
if grep -q "board" <<< "$HELP_OUT"; then
  ok "help lista o comando board"
else
  bad "help lista o comando board"
fi

# ==================================================================== 9. board
section "board (gestão visual)"

R4="$(new_repo "$TMPROOT/board")"
mkdir -p "$R4/.specify/specs/001-teste"
printf '# Spec · Teste do quadro\n' > "$R4/.specify/specs/001-teste/spec.md"
cat > "$R4/.specify/specs/001-teste/tasks.md" <<'TASKS'
- [x] **T1** · backend · Rota pronta de verdade
- [>] **T2** · frontend · Tela em construcao
- [ ] **T3** · revisor · Falta conferir
TASKS

expect_ok "gera o quadro" \
  run_in "$R4" "$KIT/tools/board.sh" --no-open --out "$R4/quadro.html"

for termo in "Rota pronta de verdade" "Tela em construcao" "Falta conferir" \
             "col todo" "col doing" "col done" "Os 4 portões"; do
  if grep -qF "$termo" "$R4/quadro.html" 2>/dev/null; then
    ok "quadro mostra: $termo"
  else
    bad "quadro mostra: $termo"
  fi
done

expect_ok "gera quadro em projeto sem tarefas" \
  run_in "$KIT" ./mutirao board --no-open --out "$TMPROOT/vazio.html"

# ================================================================ resultado
printf '\n'
if (( FAIL == 0 )); then
  printf '✔ %d verificações passaram\n' "$PASS"
  exit 0
fi

printf '✘ %d de %d falharam:\n' "$FAIL" "$((PASS + FAIL))"
printf '   - %s\n' "${FAILED[@]}"
exit 1
