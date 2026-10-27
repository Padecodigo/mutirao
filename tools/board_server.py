#!/usr/bin/env python3
"""Servidor local do quadro do Mutirão.

Só biblioteca padrão. Serve a página gerada por tools/board.sh e aceita
arrastar cartões, gravando o estado de volta no tasks.md.

Escuta apenas em 127.0.0.1: nada sai da máquina.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = ""
RENDERER = ""

# .specify/specs/<slug>/tasks.md — nada fora disso pode ser escrito
ARQUIVO_OK = re.compile(r"^\.specify/specs/[A-Za-z0-9._-]+/tasks\.md$")
TAREFA_OK = re.compile(r"^T[0-9]+$")
ESTADOS_OK = {" ", ">", "x"}


def render():
    """Roda o renderizador bash e devolve o HTML em bytes."""
    tmpdir = tempfile.mkdtemp(prefix="mutirao-board-")
    saida = os.path.join(tmpdir, "index.html")
    env = dict(os.environ)
    env["MUTIRAO_BOARD_INTERACTIVE"] = "1"
    try:
        subprocess.run(
            [RENDERER, "--no-open", "--out", saida],
            cwd=ROOT,
            env=env,
            check=True,
            capture_output=True,
            timeout=30,
        )
        with open(saida, "rb") as f:
            return f.read()
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def caminho_seguro(relativo):
    if not ARQUIVO_OK.match(relativo):
        raise ValueError("arquivo fora do permitido")
    raiz = os.path.realpath(ROOT)
    destino = os.path.realpath(os.path.join(raiz, relativo))
    if not destino.startswith(raiz + os.sep):
        raise ValueError("caminho escapou do projeto")
    return destino


def atualizar_tarefa(relativo, tarefa, estado):
    if not TAREFA_OK.match(tarefa):
        raise ValueError("identificador de tarefa inválido")
    if estado not in ESTADOS_OK:
        raise ValueError("estado inválido")

    destino = caminho_seguro(relativo)
    if not os.path.isfile(destino):
        raise ValueError("tasks.md não encontrado")

    padrao = re.compile(r"^(- \[)([ x>])(\] \*\*" + re.escape(tarefa) + r"\*\* · )")
    with open(destino, encoding="utf-8") as f:
        linhas = f.readlines()

    mudou = False
    for i, linha in enumerate(linhas):
        achado = padrao.match(linha)
        if achado:
            linhas[i] = achado.group(1) + estado + achado.group(3) + linha[achado.end():]
            mudou = True
            break

    if not mudou:
        raise LookupError("tarefa nao_encontrada")

    temporario = destino + ".mutirao.tmp"
    with open(temporario, "w", encoding="utf-8", newline="") as f:
        f.writelines(linhas)
    os.replace(temporario, destino)
    return True


class Handler(BaseHTTPRequestHandler):
    server_version = "mutirao-board/0.2"

    def responder(self, codigo, corpo, tipo="application/json; charset=utf-8"):
        dados = corpo if isinstance(corpo, bytes) else corpo.encode("utf-8")
        self.send_response(codigo)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(dados)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(dados)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            try:
                self.responder(200, render(), "text/html; charset=utf-8")
            except subprocess.CalledProcessError as erro:
                detalhe = (erro.stderr or b"").decode("utf-8", "replace")[:400]
                self.responder(500, json.dumps({"erro": "falha ao gerar", "detalhe": detalhe}))
            except Exception as erro:  # noqa: BLE001
                self.responder(500, json.dumps({"erro": str(erro)}))
            return
        if self.path == "/api/ping":
            self.responder(200, json.dumps({"ok": True}))
            return
        self.responder(404, json.dumps({"erro": "nao_encontrado"}))

    def do_POST(self):
        if self.path != "/api/task":
            self.responder(404, json.dumps({"erro": "nao_encontrado"}))
            return
        try:
            tamanho = int(self.headers.get("Content-Length") or 0)
            if tamanho <= 0 or tamanho > 4096:
                raise ValueError("corpo inválido")
            dados = json.loads(self.rfile.read(tamanho) or b"{}")
            ok = atualizar_tarefa(
                str(dados.get("arquivo", "")),
                str(dados.get("tarefa", "")),
                str(dados.get("estado", "")),
            )
            self.responder(200, json.dumps({"ok": ok}))
        except LookupError as erro:
            self.responder(404, json.dumps({"erro": str(erro)}))
        except Exception as erro:  # noqa: BLE001
            self.responder(400, json.dumps({"erro": str(erro)}))

    def log_message(self, *args):  # silencia o log padrão
        return


def abrir_navegador(url):
    try:
        webbrowser.open(url)
    except Exception:  # noqa: BLE001
        pass


def main():
    global ROOT, RENDERER

    parser = argparse.ArgumentParser(description="Quadro interativo do Mutirão")
    parser.add_argument("--root", required=True)
    parser.add_argument("--renderer", required=True)
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument("--no-open", action="store_true")
    args = parser.parse_args()

    ROOT = os.path.realpath(args.root)
    RENDERER = os.path.realpath(args.renderer)
    if not os.path.isfile(RENDERER):
        sys.exit("renderizador não encontrado: " + RENDERER)

    servidor = None
    porta = None
    for tentativa in range(args.port, args.port + 20):
        try:
            servidor = ThreadingHTTPServer(("127.0.0.1", tentativa), Handler)
            porta = tentativa
            break
        except OSError:
            continue
    if servidor is None:
        sys.exit("nenhuma porta livre a partir de %d" % args.port)

    url = "http://127.0.0.1:%d/" % porta
    print("")
    print("  Quadro do Mutirão no ar: %s" % url, flush=True)
    print("  arraste os cartões entre as colunas — o tasks.md é atualizado na hora", flush=True)
    print("  Ctrl+C para parar", flush=True)
    print("", flush=True)

    if not args.no_open:
        threading.Timer(0.4, abrir_navegador, args=(url,)).start()

    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("\n  quadro encerrado.")
    finally:
        servidor.server_close()


if __name__ == "__main__":
    main()
