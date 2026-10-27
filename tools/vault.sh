#!/usr/bin/env bash
# Cofre de chaves e senhas. Nada aqui é gravado no repositório.
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tools/lib/common.sh
source "$SELF_DIR/lib/common.sh"

ROOT="$(repo_root 2>/dev/null || true)"
[[ -n "$ROOT" ]] && ROOT="$(cd -- "$ROOT" && pwd -P)"
STORE_DIR="${ROOT:-$PWD}/.mutirao"
CONF="$STORE_DIR/vault.conf"
MANIFEST="$STORE_DIR/secrets.list"
ENVFILE="$STORE_DIR/vault.env"

usage() {
  cat <<'EOF'
uso: mutirao vault <ação>

  setup --provider <p> [--ref <nome>]   Escolhe o cofre
  doctor                               Verifica se o cofre responde
  provider                             Mostra o cofre atual
  add <NOME>                           Declara que o projeto precisa desse segredo
  list                                 O que o projeto declarou e o que existe
  run -- <comando...>                  Injeta as chaves no comando, sem mostrar
  get <NOME> [--reveal]                Confere se existe (não imprime por padrão)
  set <NOME>                           Guarda um segredo novo
  delete <NOME>                        Remove um segredo

Provedores (--provider)
  op         1Password      (recomendado: itens com campo "password")
  bws        Bitwarden Secrets Manager
  infisical  Infisical
  doppler    Doppler
  env        Arquivo local .mutirao/vault.env  ← só para estudar/testar

O fluxo certo é sempre este:
  mutirao vault add STRIPE_SECRET_KEY
  mutirao vault run -- npm run dev

Assim a chave entra na memória do programa, nunca na tela nem no chat.
O agente de IA não tem permissão de ler o cofre: ele só sabe o NOME da chave.
EOF
}

# ---------------------------------------------------------------- configuração

conf_get() {
  local key="$1"
  [[ -f "$CONF" ]] || return 0
  sed -n "s/^${key}=//p" "$CONF" | head -n 1
}

conf_set() {
  local key="$1" value="$2"
  mkdir -p "$STORE_DIR"
  chmod 700 "$STORE_DIR" 2>/dev/null || true
  if [[ -f "$CONF" ]] && grep -q "^${key}=" "$CONF"; then
    local tmp
    tmp="$(mktemp)"
    sed "s|^${key}=.*|${key}=${value}|" "$CONF" > "$tmp"
    mv "$tmp" "$CONF"
  else
    printf '%s=%s\n' "$key" "$value" >> "$CONF"
  fi
  chmod 600 "$CONF" 2>/dev/null || true
}

PROVIDER="$(conf_get VAULT_PROVIDER)"
REF="$(conf_get VAULT_REF)"

require_provider() {
  if [[ -z "$PROVIDER" ]]; then
    die "nenhum cofre configurado. Rode: mutirao vault setup --provider op --ref Projetos"
  fi
}

provider_cli() {
  case "$PROVIDER" in
    op) echo "op" ;;
    bws) echo "bws" ;;
    infisical) echo "infisical" ;;
    doppler) echo "doppler" ;;
    env) echo "" ;;
    *) echo "desconhecido" ;;
  esac
}

ensure_cli() {
  local cli
  cli="$(provider_cli)"
  [[ "$cli" == "desconhecido" ]] && die "provedor inválido: $PROVIDER"
  [[ -z "$cli" ]] && return 0
  have "$cli" || die "o comando '$cli' não está instalado. Veja docs/seguranca-e-cofre.md"
}

# ---------------------------------------------------------------- leitura

secret_get() {
  local name="$1"
  case "$PROVIDER" in
    op)
      op read "op://${REF}/${name}/password" 2>/dev/null \
        || op read "op://${REF}/${name}/credential" 2>/dev/null \
        || return 1
      ;;
    bws)
      have jq || die "instale 'jq' para usar o Bitwarden"
      local v
      v="$(bws secret list --output json 2>/dev/null \
        | jq -r --arg k "$name" '.[] | select(.key == $k) | .value' \
        | head -n 1)"
      [[ -n "$v" ]] || return 1
      printf '%s' "$v"
      ;;
    infisical)
      infisical secrets get "$name" --plain 2>/dev/null | tr -d '\r'
      ;;
    doppler)
      doppler secrets get "$name" --plain 2>/dev/null | tr -d '\r'
      ;;
    env)
      [[ -f "$ENVFILE" ]] || return 1
      local v
      v="$(sed -n "s/^${name}=//p" "$ENVFILE" | head -n 1)"
      [[ -n "$v" ]] || return 1
      printf '%s' "$v"
      ;;
    *)
      die "provedor inválido: $PROVIDER"
      ;;
  esac
}

secret_exists() {
  local name="$1"
  [[ -n "$(secret_get "$name" 2>/dev/null || true)" ]]
}

# ---------------------------------------------------------------- comandos

cmd_setup() {
  local provider="" ref=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --provider) provider="${2:-}"; shift 2 ;;
      --provider=*) provider="${1#*=}"; shift ;;
      --ref) ref="${2:-}"; shift 2 ;;
      --ref=*) ref="${1#*=}"; shift ;;
      *) die "argumento desconhecido: $1" ;;
    esac
  done

  [[ -n "$provider" ]] || die "informe --provider (op, bws, infisical, doppler, env)"
  case "$provider" in
    op|bws|infisical|doppler|env) ;;
    *) die "provedor inválido: $provider" ;;
  esac

  conf_set VAULT_PROVIDER "$provider"
  [[ -n "$ref" ]] && conf_set VAULT_REF "$ref"
  PROVIDER="$provider"
  REF="$ref"

  ok "cofre configurado: $provider${ref:+ (ref: $ref)}"

  if [[ "$provider" == "env" ]]; then
    warn "o provedor 'env' guarda em texto puro no seu computador."
    warn "serve para aprender e testar. Para projeto de verdade, use 1Password."
  fi
  info ""
  info "Agora declare o que o projeto precisa:"
  dim "  mutirao vault add NOME_DA_CHAVE"
  dim "  mutirao vault run -- seu-comando"
}

cmd_provider() {
  if [[ -z "$PROVIDER" ]]; then
    info "nenhum cofre configurado ainda."
    dim "  mutirao vault setup --provider op --ref Projetos"
    return 0
  fi
  info "provedor: $PROVIDER${REF:+  ·  ref: $REF}"
}

cmd_doctor() {
  title "Cofre"
  if [[ -z "$PROVIDER" ]]; then
    warn "não configurado — rode: mutirao vault setup --provider op --ref Projetos"
    return 0
  fi
  ok "provedor configurado: $PROVIDER${REF:+ (ref: $REF)}"

  local cli
  cli="$(provider_cli)"
  if [[ -n "$cli" ]]; then
    if have "$cli"; then
      ok "comando '$cli' encontrado"
    else
      fail "comando '$cli' não instalado"
      return 1
    fi
  fi

  case "$PROVIDER" in
    op)
      if op whoami >/dev/null 2>&1; then ok "1Password autenticado"; else fail "1Password não autenticado (rode: op signin)"; fi
      ;;
    doppler)
      if doppler me >/dev/null 2>&1; then ok "Doppler autenticado"; else fail "Doppler não autenticado (rode: doppler login)"; fi
      ;;
    env)
      if [[ -f "$ENVFILE" ]]; then
        ok "arquivo local encontrado"
      else
        warn "arquivo local ainda não existe: $ENVFILE"
      fi
      ;;
  esac

  if [[ -f "$MANIFEST" ]]; then
    local total missing=0 name
    total="$(grep -cvE '^[[:space:]]*(#|$)' "$MANIFEST" || true)"
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      secret_exists "$name" || { warn "faltando no cofre: $name"; missing=$((missing + 1)); }
    done < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST")
    if (( missing == 0 )); then
      ok "todas as $total chave(s) declaradas existem no cofre"
    else
      warn "$missing de $total chave(s) declaradas não estão no cofre"
    fi
  else
    dim "nenhuma chave declarada ainda (.mutirao/secrets.list)"
  fi
}

cmd_add() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "uso: mutirao vault add <NOME_DA_CHAVE>"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "use um nome tipo STRIPE_SECRET_KEY (letras, números e _)"
  mkdir -p "$STORE_DIR"
  touch "$MANIFEST"
  if grep -qxF "$name" "$MANIFEST"; then
    info "'$name' já estava declarada."
  else
    printf '%s\n' "$name" >> "$MANIFEST"
    ok "declarada: $name"
  fi
  dim "  chame no código como variável de ambiente: \$($name)"
}

declared_names() {
  [[ -f "$MANIFEST" ]] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST"
}

cmd_list() {
  if [[ -z "$PROVIDER" ]]; then
    warn "cofre não configurado."
    return 0
  fi
  local name found=0
  title "Chaves declaradas pelo projeto"
  if ! declared_names | grep -q .; then
    dim "  (nenhuma)"
    return 0
  fi
  while IFS= read -r name; do
    if secret_exists "$name"; then
      printf '  %s✔%s %-32s no cofre\n' "$C_GREEN" "$C_RESET" "$name"
      found=$((found + 1))
    else
      printf '  %s✘%s %-32s faltando\n' "$C_RED" "$C_RESET" "$name"
    fi
  done < <(declared_names)
  (( found > 0 )) && dim "  $found pronta(s) para uso."
}

cmd_get() {
  local name="${1:-}" reveal=0
  shift || true
  [[ "${1:-}" == "--reveal" ]] && reveal=1
  [[ -n "$name" ]] || die "uso: mutirao vault get <NOME> [--reveal]"
  require_provider

  if ! secret_exists "$name"; then
    fail "'$name' não existe no cofre."
    return 1
  fi

  if (( reveal == 0 )); then
    ok "'$name' existe no cofre."
    info ""
    info "Não vou imprimir o valor. Use assim:"
    dim "  mutirao vault run -- <seu comando>"
    info ""
    info "Só se você realmente precisar ver:"
    dim "  mutirao vault get $name --reveal"
    return 0
  fi

  warn "o valor vai aparecer na tela. Cuidado com gravação de tela e histórico."
  confirm "Mostrar mesmo assim?" || die "cancelado."
  secret_get "$name"
}

cmd_set() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "uso: mutirao vault set <NOME>"
  require_provider

  case "$PROVIDER" in
    op)
      cat <<EOF
Para guardar '$name' no 1Password:
  1. abra o app do 1Password
  2. entre no cofre '${REF:-o seu cofre}'
  3. crie um item do tipo "Senha" com o título  $name
  4. cole a chave no campo "senha"

O Mutirão não pede a chave no chat, de propósito.
Depois confira com:  mutirao vault get $name
EOF
      return 0
      ;;
    bws)
      cat <<EOF
Para guardar '$name' no Bitwarden Secrets Manager:
  1. abra o cofre no site do Bitwarden
  2. crie um segredo com a chave (key)  $name
  3. cole o valor e salve

Depois confira com:  mutirao vault get $name
EOF
      return 0
      ;;
    infisical)
      local value
      value="$(read_secret "valor de $name (não aparece): ")"
      [[ -n "$value" ]] || die "valor vazio."
      infisical secrets set "${name}=${value}" >/dev/null
      ok "guardado: $name"
      ;;
    doppler)
      local value
      value="$(read_secret "valor de $name (não aparece): ")"
      [[ -n "$value" ]] || die "valor vazio."
      doppler secrets set "${name}=${value}" >/dev/null
      ok "guardado: $name"
      ;;
    env)
      local value
      value="$(read_secret "valor de $name (não aparece): ")"
      [[ -n "$value" ]] || die "valor vazio."
      mkdir -p "$STORE_DIR"
      touch "$ENVFILE"
      chmod 600 "$ENVFILE"
      local tmp
      tmp="$(mktemp)"
      sed "/^${name}=/d" "$ENVFILE" > "$tmp"
      printf '%s=%s\n' "$name" "$value" >> "$tmp"
      mv "$tmp" "$ENVFILE"
      ok "guardado em $ENVFILE (texto puro, só para estudo)"
      ;;
  esac
}

cmd_delete() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "uso: mutirao vault delete <NOME>"
  require_provider

  case "$PROVIDER" in
    op|bws)
      info "apague '$name' direto no app do cofre (é lá que a verdade mora)."
      ;;
    infisical)
      infisical secrets delete "$name" >/dev/null && ok "removido: $name" ;;
    doppler)
      doppler secrets delete "$name" --yes >/dev/null && ok "removido: $name" ;;
    env)
      [[ -f "$ENVFILE" ]] || die "nada para apagar."
      local tmp
      tmp="$(mktemp)"
      sed "/^${name}=/d" "$ENVFILE" > "$tmp"
      mv "$tmp" "$ENVFILE"
      ok "removido do arquivo local."
      ;;
  esac

  if [[ -f "$MANIFEST" ]]; then
    local tmp
    tmp="$(mktemp)"
    grep -vxF "$name" "$MANIFEST" > "$tmp" || true
    mv "$tmp" "$MANIFEST"
  fi
}

cmd_run() {
  [[ "${1:-}" == "--" ]] && shift
  [[ $# -gt 0 ]] || die "uso: mutirao vault run -- <comando...>"
  require_provider
  ensure_cli

  local -a names=()
  local name value
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    names+=("$name")
  done < <(declared_names)

  if (( ${#names[@]} == 0 )); then
    warn "nenhuma chave declarada em .mutirao/secrets.list"
    info "rodando o comando sem chaves."
    exec "$@"
  fi

  for name in "${names[@]}"; do
    if ! value="$(secret_get "$name")" || [[ -z "$value" ]]; then
      die "não consegui ler '$name' do cofre ($PROVIDER)."
    fi
    export "$name=$value"
  done
  unset value

  exec "$@"
}

action="${1:-help}"
[[ $# -gt 0 ]] && shift

case "$action" in
  setup)    cmd_setup "$@" ;;
  doctor)   cmd_doctor ;;
  provider) cmd_provider ;;
  add)      cmd_add "$@" ;;
  list|ls)  cmd_list ;;
  get)      cmd_get "$@" ;;
  set)      cmd_set "$@" ;;
  delete|rm) cmd_delete "$@" ;;
  run)      cmd_run "$@" ;;
  help|-h|--help) usage ;;
  *) fail "ação desconhecida: $action"; info ""; usage; exit 2 ;;
esac
