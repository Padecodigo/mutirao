#!/usr/bin/env bash
# Quadro visual do mutirão: gera uma página que abre no navegador.
set -euo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tools/lib/common.sh
source "$SELF_DIR/lib/common.sh"

ROOT="$(repo_root)" || die "rode dentro do projeto (git)."
OUT="$ROOT/.mutirao/board/index.html"
OPEN=1
REFRESH=0
WATCH=0

usage() {
  cat <<'EOF'
uso: mutirao board [opções]

  (sem opção)     Gera o quadro e abre no navegador
  --no-open       Gera sem abrir
  --out <arquivo> Gera em outro caminho
  --watch         Gera, abre e atualiza sozinho a cada 5 segundos
  --refresh       Só inclui a atualização automática na página

O quadro mostra, em colunas: a fazer, fazendo agora e concluído — mais os
agentes em worktree, os 4 portões e o estado do cofre.

Como ele sabe o andamento: lendo .specify/specs/*/tasks.md.
  - [ ]  a fazer
  - [>]  fazendo agora (o agente marca com o próprio nome)
  - [x]  concluído
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-open) OPEN=0; shift ;;
    --out) OUT="${2:-}"; shift 2 ;;
    --watch) WATCH=1; REFRESH=1; shift ;;
    --refresh) REFRESH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "opção desconhecida: $1" ;;
  esac
done

[[ -n "$OUT" ]] || die "--out precisa de um caminho"

# ---------------------------------------------------------------- utilidades

html_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  printf '%s' "$s"
}

# TSV: id · papel · texto · estado · spec
collect_tasks() {
  local dir name f
  for dir in "$ROOT"/.specify/specs/*/; do
    [[ -d "$dir" ]] || continue
    f="${dir}tasks.md"
    [[ -f "$f" ]] || continue
    name="$(basename -- "${dir%/}")"
    awk -F' · ' -v spec="$name" '
      /^- \[[ x>]\] \*\*T[0-9]+\*\* · / {
        status = substr($0, 4, 1)
        id = $1
        sub(/^- \[.\] /, "", id)
        gsub(/\*/, "", id)
        role = $2
        text = $3
        printf "%s\t%s\t%s\t%s\t%s\n", id, role, text, status, spec
      }
    ' "$f"
  done
}

# -------------------------------------------------------------------- render

project_title() {
  local dir t="" n=0
  for dir in "$ROOT"/.specify/specs/*/; do
    [[ -d "$dir" ]] && n=$((n + 1))
  done
  if (( n == 1 )); then
    for dir in "$ROOT"/.specify/specs/*/; do
      [[ -d "$dir" ]] || continue
      if [[ -f "${dir}spec.md" ]]; then
        t="$(sed -n 's/^#[[:space:]]*Spec[[:space:]]*·[[:space:]]*//p' "${dir}spec.md" | head -n 1)"
      fi
    done
  fi
  [[ -n "$t" ]] || t="$(basename -- "$ROOT")"
  printf '%s' "$t"
}

render() {
  local proj
  proj="$(project_title)"

  local -a t_id=() t_role=() t_text=() t_st=() t_spec=()
  local id role text st spec
  while IFS=$'\t' read -r id role text st spec; do
    [[ -z "${id:-}" ]] && continue
    t_id+=("$id")
    t_role+=("$role")
    t_text+=("$text")
    t_st+=("$st")
    t_spec+=("$spec")
  done < <(collect_tasks)

  local total=${#t_id[@]} done_n=0 doing_n=0 todo_n=0 i
  for i in "${!t_st[@]}"; do
    case "${t_st[$i]}" in
      x) done_n=$((done_n + 1)) ;;
      '>') doing_n=$((doing_n + 1)) ;;
      *) todo_n=$((todo_n + 1)) ;;
    esac
  done

  mkdir -p "$(dirname -- "$OUT")"

  {
    printf '<!doctype html>\n<html lang="pt-BR">\n<head>\n<meta charset="utf-8">\n'
    printf '<meta name="viewport" content="width=device-width,initial-scale=1">\n'
    printf '<title>%s · Mutirão</title>\n' "$(html_escape "$proj")"
    if (( REFRESH == 1 )); then
      printf '<meta http-equiv="refresh" content="5">\n'
    fi
    cat <<'CSS'
<style>
  :root{
    --bg:#f6f4ef; --card:#fff; --ink:#1f1d1a; --muted:#6f6a62;
    --line:#e2ddd3; --todo:#b9b2a6; --doing:#b86a2e; --done:#3f7a52;
    --accent:#b5654a;
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--ink);
       font:16px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
  header{padding:28px 24px 8px;max-width:1200px;margin:0 auto}
  h1{margin:0;font-size:26px;letter-spacing:-.02em}
  .sub{color:var(--muted);font-size:14px;margin-top:4px}
  .stats{display:flex;gap:8px;flex-wrap:wrap;margin-top:16px}
  .stat{background:var(--card);border:1px solid var(--line);border-radius:999px;
        padding:6px 14px;font-size:13px;color:var(--muted)}
  .stat b{color:var(--ink)}
  main{max-width:1200px;margin:0 auto;padding:16px 24px 48px;
       display:grid;grid-template-columns:1fr 300px;gap:24px;align-items:start}
  .board{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}
  .col h2{font-size:13px;text-transform:uppercase;letter-spacing:.08em;
          color:var(--muted);margin:0 0 10px 2px;font-weight:600}
  .col.todo h2{color:var(--todo)} .col.doing h2{color:var(--doing)}
  .col.done h2{color:var(--done)}
  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;
        padding:12px 14px;margin-bottom:10px;box-shadow:0 1px 0 rgba(0,0,0,.02)}
  .card p{margin:8px 0 0;font-size:14px}
  .card .top{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
  .id{font:600 12px/1 ui-monospace,monospace;color:var(--muted)}
  .role{font-size:11px;padding:2px 8px;border-radius:999px;border:1px solid var(--line);
        color:var(--muted);background:#faf8f4}
  .role.frontend{color:#2c5f8a;border-color:#cfe0ef;background:#eef5fb}
  .role.backend{color:#3f7a52;border-color:#cfe4d6;background:#eef7f1}
  .role.revisor{color:#6a4b8a;border-color:#e0d2ee;background:#f5eefa}
  .role.maestro{color:#8a6a2c;border-color:#eadfc8;background:#fbf5e8}
  .spec{font-size:11px;color:var(--muted);opacity:.7}
  .empty{border:1px dashed var(--line);border-radius:12px;padding:18px;
         color:var(--muted);font-size:13px;background:transparent}
  aside{display:flex;flex-direction:column;gap:16px}
  .panel{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 16px}
  .panel h3{margin:0 0 10px;font-size:12px;text-transform:uppercase;
            letter-spacing:.08em;color:var(--muted)}
  .panel ul{margin:0;padding-left:18px;font-size:13px;color:var(--muted)}
  .panel li{margin:4px 0}
  .agent{display:flex;justify-content:space-between;gap:8px;font-size:13px;
         padding:6px 0;border-bottom:1px dashed var(--line);flex-wrap:wrap}
  .hint{font-size:11px;color:var(--muted);margin:2px 0 8px}
  .panel code{overflow-wrap:anywhere}
  .agent:last-child{border-bottom:0}
  .agent code{font-size:12px;color:var(--muted)}
  .dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:6px}
  .dot.on{background:var(--doing)} .dot.off{background:var(--todo)}
  footer{max-width:1200px;margin:0 auto;padding:0 24px 40px;color:var(--muted);font-size:12px}
  @media (max-width:900px){
    main{grid-template-columns:1fr}
    .board{grid-template-columns:1fr}
  }
</style>
CSS
    printf '</head>\n<body>\n'
    printf '<header>\n<h1>%s</h1>\n' "$(html_escape "$proj")"
    printf '<div class="sub">Gestão visual do mutirão · atualizado em %s</div>\n' "$(date '+%d/%m %H:%M')"
    printf '<div class="stats">'
    printf '<span class="stat"><b>%d</b> tarefas</span>' "$total"
    printf '<span class="stat"><b>%d</b> concluídas</span>' "$done_n"
    printf '<span class="stat"><b>%d</b> fazendo agora</span>' "$doing_n"
    printf '<span class="stat"><b>%d</b> a fazer</span>' "$todo_n"
    printf '</div>\n</header>\n<main>\n<div class="board">\n'

    # colunas
    local -a col_keys=('todo' 'doing' 'done')
    local -a col_titles=('A fazer' 'Fazendo agora' 'Concluído')
    local c
    for c in 0 1 2; do
      printf '<section class="col %s">\n<h2>%s</h2>\n' "${col_keys[$c]}" "${col_titles[$c]}"
      local printed=0
      for i in "${!t_id[@]}"; do
        local match=0
        case "${col_keys[$c]}" in
          todo)  [[ "${t_st[$i]}" == " " ]] && match=1 ;;
          doing) [[ "${t_st[$i]}" == ">" ]] && match=1 ;;
          done)  [[ "${t_st[$i]}" == "x" ]] && match=1 ;;
        esac
        (( match )) || continue
        printed=1
        local role_lc
        role_lc="$(printf '%s' "${t_role[$i]}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
        printf '<article class="card">\n<div class="top">'
        printf '<span class="id">%s</span>' "$(html_escape "${t_id[$i]}")"
        printf '<span class="role %s">%s</span>' "$(html_escape "$role_lc")" "$(html_escape "${t_role[$i]}")"
        printf '<span class="spec">%s</span>' "$(html_escape "${t_spec[$i]}")"
        printf '</div>\n<p>%s</p>\n</article>\n' "$(html_escape "${t_text[$i]}")"
      done
      if (( printed == 0 )); then
        case "${col_keys[$c]}" in
          todo)
            printf '<div class="empty">Nada na fila. Peça ao Maestro a próxima etapa.</div>\n' ;;
          doing)
            printf '<div class="empty">Nenhum agente trabalhando agora.</div>\n' ;;
          done)
            printf '<div class="empty">Ainda nada concluído.</div>\n' ;;
        esac
      fi
      printf '</section>\n'
    done

    printf '</div>\n<aside>\n'

    # agentes
    printf '<div class="panel"><h3>Agentes</h3>\n'
    local wt dir name branch dirty any=0
    for wt in "$ROOT"/.mutirao/worktrees/*/; do
      [[ -d "$wt" ]] || continue
      any=1
      dir="${wt%/}"
      name="$(basename -- "$dir")"
      branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
      dirty="$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
      printf '<div class="agent"><span><span class="dot on"></span>%s</span><code>%s arq.</code></div>\n' \
        "$(html_escape "$name")" "$dirty"
      printf '<div class="hint"><code>%s</code></div>\n' "$(html_escape "$branch")"
    done
    if (( any == 0 )); then
      printf '<div class="agent"><span><span class="dot off"></span>nenhum</span><code>mutirao worktree new &lt;nome&gt;</code></div>\n'
    fi
    printf '</div>\n'

    # portões
    cat <<'GATES'
<div class="panel">
  <h3>Os 4 portões</h3>
  <ul>
    <li><b>Conta</b> — você resolve a verificação</li>
    <li><b>Pagamento</b> — você paga no site</li>
    <li><b>Publicar</b> — você aprova o deploy</li>
    <li><b>Chave</b> — você guarda no cofre</li>
  </ul>
</div>
GATES

    # cofre
    local provider="" nkeys=0
    if [[ -f "$ROOT/.mutirao/vault.conf" ]]; then
      provider="$(sed -n 's/^VAULT_PROVIDER=//p' "$ROOT/.mutirao/vault.conf" | head -n 1)"
    fi
    if [[ -f "$ROOT/.mutirao/secrets.list" ]]; then
      nkeys="$(grep -cvE '^[[:space:]]*(#|$)' "$ROOT/.mutirao/secrets.list" || true)"
    fi
    printf '<div class="panel"><h3>Cofre</h3>\n'
    if [[ -n "$provider" ]]; then
      printf '<div class="agent"><span>%s</span><code>%s chave(s)</code></div>\n' "$(html_escape "$provider")" "$nkeys"
    else
      printf '<div class="agent"><span>não configurado</span><code>mutirao vault setup</code></div>\n'
    fi
    printf '</div>\n'

    # atividade
    printf '<div class="panel"><h3>Últimos passos</h3><ul>\n'
    git -C "$ROOT" log --pretty='%h %s' -n 5 2>/dev/null | while IFS= read -r l; do
      printf '<li>%s</li>\n' "$(html_escape "$l")"
    done
    printf '</ul></div>\n'

    printf '</aside>\n</main>\n'
    printf '<footer>Gerado por <code>mutirao board</code> · %s · regras em AGENTS.md</footer>\n' \
      "$(html_escape "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')")"
    printf '</body>\n</html>\n'
  } > "$OUT"
}

open_browser() {
  local f="$1"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$f" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$f" >/dev/null 2>&1 &
  elif command -v start >/dev/null 2>&1; then
    start "" "$f" >/dev/null 2>&1 &
  else
    warn "não achei como abrir o navegador. Abra este arquivo:"
  fi
  info "  $f"
}

render
if (( OPEN == 1 )); then open_browser "$OUT"; fi

if (( WATCH == 1 )); then
  info ""
  dim "atualizando a cada 5 segundos — Ctrl+C para parar"
  trap 'exit 0' INT TERM
  while true; do
    sleep 5
    render
  done
fi
