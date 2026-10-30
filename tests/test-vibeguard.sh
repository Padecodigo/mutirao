#!/usr/bin/env bash
# PROPÓSITO: provar que o filtro de contexto (security/scripts/vibeguard.mjs) e o
# verificador de caracteres invisíveis (check-invisible.mjs) realmente fazem o
# que prometem — redação, truncamento com referência, preservação de erro e
# códigos de saída.
#
# Uso: bash tests/test-vibeguard.sh

set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VIBEGUARD="$ROOT/security/scripts/vibeguard.mjs"
INVISIBLE="$ROOT/security/scripts/check-invisible.mjs"

PASS=0
FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()  { PASS=$((PASS + 1)); printf '  ✔ %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  ✘ %s\n' "$1"; }

check() {
  local name="$1" condition="$2"
  if [[ "$condition" == "0" ]]; then ok "$name"; else bad "$name"; fi
}

section() { printf '\n— %s\n' "$1"; }

# ------------------------------------------------------------------ 1. config

section "Configuração"

OUT="$("$VIBEGUARD" --check 2>&1)"
check "--check aceita vibeguard.yaml" "$?"
check "--check reporta a redação" "$([[ "$OUT" == *"padrão(ões)"* ]] && echo 0 || echo 1)"

printf 'redaction:\n  enabled: true\n  patterns:\n    - name: quebrada\n      regex: "([unclosed"\n' > "$TMP/ruim.yaml"
"$VIBEGUARD" --config "$TMP/ruim.yaml" --check >/dev/null 2>&1
check "config com regex inválida falha com 2" "$([[ $? -eq 2 ]] && echo 0 || echo 1)"

# ------------------------------------------------------------------- 2. redação

section "Redação de PII e segredos"

# Chave falsa montada em runtime: o literal "AKIA..." faria o guard.sh
# (corretamente) tratar este arquivo de teste como vazamento.
AWS_PREFIXO="AKIA"
AWS_SUFIXO="ABCDEFGHIJKLMNOP"
printf 'email: joao@empresa.com.br\ncpf: 123.456.789-01\nchave: %s%s\n' \
  "$AWS_PREFIXO" "$AWS_SUFIXO" > "$TMP/pii.txt"
RED="$("$VIBEGUARD" < "$TMP/pii.txt" 2>/dev/null)"

check "e-mail redigido" "$([[ "$RED" == *"[REDACTED:pii.email]"* ]] && echo 0 || echo 1)"
check "CPF redigido" "$([[ "$RED" == *"[REDACTED:pii.cpf]"* ]] && echo 0 || echo 1)"
check "chave AWS redigida" "$([[ "$RED" == *"[REDACTED:secret.aws]"* ]] && echo 0 || echo 1)"
check "valor original não vaza" "$([[ "$RED" != *"joao@empresa.com.br"* && "$RED" != *"123.456.789-01"* ]] && echo 0 || echo 1)"

# --------------------------------------------------------------- 3. truncamento

section "Truncamento"

{
  for i in $(seq 1 300); do echo "linha $i"; done
  echo "Error: falha que não pode sumir"
  for i in $(seq 301 600); do echo "linha $i"; done
} > "$TMP/grande.txt"

SAIDA="$("$VIBEGUARD" --max-lines 40 < "$TMP/grande.txt" 2>/dev/null)"
LINHAS="$(printf '%s\n' "$SAIDA" | wc -l | tr -d ' ')"

check "saída truncada (<= 60 linhas)" "$([[ "$LINHAS" -le 60 ]] && echo 0 || echo 1)"
check "marcador de omissão presente" "$([[ "$SAIDA" == *"linhas omitidas"* ]] && echo 0 || echo 1)"
check "linha de erro preservada" "$([[ "$SAIDA" == *"Error: falha que não pode sumir"* ]] && echo 0 || echo 1)"

REF="$(printf '%s\n' "$SAIDA" | grep -o 'ref: [^)]*' | head -1 | sed 's/^ref: //')"
check "marcador aponta um arquivo" "$([[ -n "$REF" ]] && echo 0 || echo 1)"
check "arquivo do handle existe" "$([[ -n "$REF" && -f "$ROOT/$REF" ]] && echo 0 || echo 1)"
check "handle não duplica o prefixo ref:" "$([[ "$SAIDA" != *"ref: ref:"* ]] && echo 0 || echo 1)"

# ------------------------------------------------------- 4. caracteres invisíveis

section "Caracteres invisíveis"

printf 'texto limpo\n' > "$TMP/limpo.txt"
"$INVISIBLE" "$TMP/limpo.txt" >/dev/null 2>&1
check "arquivo limpo passa" "$([[ $? -eq 0 ]] && echo 0 || echo 1)"

printf 'texto ok\narmadilha\u200baqui\n' > "$TMP/sujo.txt"
SAIDA_INV="$("$INVISIBLE" "$TMP/sujo.txt" 2>&1)"
STATUS_INV=$?
check "arquivo sujo falha com 1" "$([[ "$STATUS_INV" -eq 1 ]] && echo 0 || echo 1)"
check "aponta linha e codepoint" "$([[ "$SAIDA_INV" == *"U+200B"* ]] && echo 0 || echo 1)"

# --------------------------------------------------------------------- resumo

printf '\n%s\n' "$(printf '=%.0s' {1..40})"
if [[ "$FAIL" -gt 0 ]]; then
  printf 'FALHAS: %s de %s teste(s)\n' "$FAIL" "$((PASS + FAIL))"
  exit 1
fi

printf 'OK: %s teste(s) passaram\n' "$PASS"
