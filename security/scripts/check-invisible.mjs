#!/usr/bin/env node
// PROPÓSITO: detectar caracteres invisíveis/de controle (zero-width, bidi, BOM)
// em código e documentação — vetor de prompt injection oculto e de comparação
// quebrada. Portátil: não depende de PCRE no grep nem de UTF-8 no shell.
//
// Uso:
//   node security/scripts/check-invisible.mjs            # arquivos do git (versionados + novos)
//   node security/scripts/check-invisible.mjs a.js b.md  # arquivos específicos
//
// Saída: lista "arquivo:linha:coluna U+XXXX"; código 0 = limpo, 1 = achou, 2 = erro.

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const EXIT_CLEAN = 0;
const EXIT_FOUND = 1;
const EXIT_ERROR = 2;

const MAX_FILE_BYTES = 2 * 1024 * 1024;
const SKIP_DIRS = new Set([".git", "node_modules", ".cache", "dist", "build", ".venv", "venv"]);

// Faixas proibidas: zero-width, bidi controls, word joiner, isolates, BOM.
const INVISIBLE = /[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]/g;

function usage() {
  process.stderr.write(
    [
      "uso: node security/scripts/check-invisible.mjs [arquivos...]",
      "",
      "  sem argumentos: verifica os arquivos do git (versionados + não ignorados)",
      "  com argumentos: verifica apenas os arquivos indicados",
      "",
      "códigos: 0 limpo | 1 caracteres encontrados | 2 erro de uso/leitura",
      "",
    ].join("\n"),
  );
}

function listGitFiles() {
  try {
    const output = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard"], {
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
    });
    return output.split("\0").filter(Boolean);
  } catch (error) {
    throw new Error(`não consegui listar arquivos do git: ${error.message}`);
  }
}

function isBinary(file) {
  const buffer = Buffer.alloc(8192);
  let fd;
  try {
    fd = fs.openSync(file, "r");
    const read = fs.readSync(fd, buffer, 0, buffer.length, 0);
    return buffer.subarray(0, read).includes(0);
  } catch {
    return true;
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

function describe(codePoint) {
  return `U+${codePoint.toString(16).toUpperCase().padStart(4, "0")}`;
}

function scanFile(file) {
  const hits = [];

  let stats;
  try {
    stats = fs.statSync(file);
  } catch {
    return hits;
  }
  if (!stats.isFile() || stats.size > MAX_FILE_BYTES || stats.size === 0) return hits;
  if (isBinary(file)) return hits;

  const lines = fs.readFileSync(file, "utf8").split("\n");

  for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    const line = lines[lineIndex];
    if (!/[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]/.test(line)) continue;

    for (const match of line.matchAll(INVISIBLE)) {
      hits.push({
        file,
        line: lineIndex + 1,
        column: match.index + 1,
        codePoint: match[0].codePointAt(0),
      });
    }
  }

  return hits;
}

function main() {
  const args = process.argv.slice(2);

  if (args.includes("--help") || args.includes("-h")) {
    usage();
    return EXIT_CLEAN;
  }

  const unknown = args.filter((arg) => arg.startsWith("-"));
  if (unknown.length > 0) {
    process.stderr.write(`check-invisible: argumento desconhecido: ${unknown.join(", ")}\n`);
    return EXIT_ERROR;
  }

  let files;
  try {
    files = args.length > 0 ? args : listGitFiles();
  } catch (error) {
    process.stderr.write(`check-invisible: ${error.message}\n`);
    return EXIT_ERROR;
  }

  files = files.filter((file) => {
    const normalized = file.replaceAll("\\", "/");
    if (normalized.split("/").some((part) => SKIP_DIRS.has(part))) return false;
    return fs.existsSync(path.resolve(file));
  });

  const hits = [];
  for (const file of files) hits.push(...scanFile(file));

  if (hits.length === 0) {
    process.stdout.write(`check-invisible: ${files.length} arquivo(s) verificado(s), nada encontrado\n`);
    return EXIT_CLEAN;
  }

  for (const hit of hits) {
    process.stdout.write(`${hit.file}:${hit.line}:${hit.column} ${describe(hit.codePoint)}\n`);
  }
  process.stderr.write(`check-invisible: ${hits.length} caractere(s) invisível(is) em ${files.length} arquivo(s)\n`);
  return EXIT_FOUND;
}

process.exit(main());
