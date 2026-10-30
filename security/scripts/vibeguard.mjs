#!/usr/bin/env node
// PROPÓSITO: aplicar security/vibeguard.yaml de verdade — redigir PII/segredos e
// truncar saídas grandes ANTES de elas entrarem no contexto do modelo. Lê da
// entrada padrão e escreve o resultado filtrado na saída padrão.
//
// Uso:
//   comando 2>&1 | node security/scripts/vibeguard.mjs
//   comando | node security/scripts/vibeguard.mjs --max-lines 80
//   node security/scripts/vibeguard.mjs --check        # valida a configuração
//
// Saída: 0 = ok | 2 = configuração/uso/entrada inválidos (falha fechada)
//
// Segurança: o texto bruto só vai para o disco se a configuração permitir
// (handles.store_redacted_only: false). O padrão é gravar já redigido, 0600.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import { parseYaml } from "./lib/yaml.mjs";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIR, "..", "..");
const DEFAULT_CONFIG = path.join(ROOT, "security", "vibeguard.yaml");
const MAX_INPUT_BYTES = 64 * 1024 * 1024;

const EXIT_OK = 0;
const EXIT_INVALID = 2;

function usage() {
  process.stderr.write(
    [
      "uso: <comando> | node security/scripts/vibeguard.mjs [opções]",
      "",
      "  --config <arquivo>  caminho do vibeguard.yaml (padrão: security/vibeguard.yaml)",
      "  --max-lines <n>     teto de linhas na saída (sobrepõe a configuração)",
      "  --max-bytes <n>     teto de bytes na saída",
      "  --no-store          não grava o texto em .cache/tool-output",
      "  --verbose           mostra estatísticas no stderr",
      "  --check             valida a configuração e sai (não lê stdin)",
      "  --help              esta ajuda",
      "",
      "códigos: 0 ok | 2 configuração/uso/entrada inválidos",
      "",
    ].join("\n"),
  );
}

function fail(message) {
  process.stderr.write(`vibeguard: ${message}\n`);
  process.exit(EXIT_INVALID);
}

// ------------------------------------------------------------------ argumentos

function parseArgs(argv) {
  const options = {
    config: DEFAULT_CONFIG,
    maxLines: null,
    maxBytes: null,
    store: true,
    verbose: false,
    check: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const value = () => {
      const next = argv[++i];
      if (next === undefined) fail(`faltou valor para ${arg}`);
      return next;
    };

    switch (arg) {
      case "--config": options.config = path.resolve(value()); break;
      case "--max-lines": options.maxLines = toPositiveInt(value(), arg); break;
      case "--max-bytes": options.maxBytes = toPositiveInt(value(), arg); break;
      case "--no-store": options.store = false; break;
      case "--verbose": options.verbose = true; break;
      case "--check": options.check = true; break;
      case "--help":
      case "-h":
        usage();
        process.exit(EXIT_OK);
        break;
      default:
        fail(`argumento desconhecido: ${arg} (use --help)`);
    }
  }

  return options;
}

function toPositiveInt(raw, flag) {
  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed <= 0) fail(`${flag} precisa de um inteiro positivo (recebi "${raw}")`);
  return parsed;
}

// -------------------------------------------------------------------- config

function loadConfig(configPath) {
  if (!fs.existsSync(configPath)) fail(`configuração não encontrada: ${configPath}`);

  let config;
  try {
    config = parseYaml(fs.readFileSync(configPath, "utf8"));
  } catch (error) {
    fail(`não consegui ler a configuração: ${error.message}`);
  }

  if (!config || typeof config !== "object" || Array.isArray(config)) fail("configuração vazia ou inválida");

  const redaction = config.redaction ?? {};
  const truncation = config.truncation ?? {};
  const defaults = config.defaults ?? {};
  const handles = config.handles ?? {};

  const patterns = Array.isArray(redaction.patterns) ? redaction.patterns : [];
  const compiledPatterns = patterns.map((pattern, index) => {
    if (!pattern || typeof pattern.regex !== "string" || !pattern.regex) {
      fail(`padrão #${index + 1} sem campo "regex"`);
    }
    let flags = typeof pattern.flags === "string" ? pattern.flags : "";
    if (!flags.includes("g")) flags += "g";
    try {
      return {
        name: pattern.name ?? `padrão-${index + 1}`,
        type: pattern.type ?? pattern.name ?? "redacted",
        regex: new RegExp(pattern.regex, flags),
      };
    } catch (error) {
      fail(`regex inválida no padrão "${pattern.name ?? index + 1}": ${error.message}`);
    }
  });

  const preservePatterns = (Array.isArray(truncation.preserve_patterns) ? truncation.preserve_patterns : [])
    .filter((source) => typeof source === "string" && source)
    .map((source) => {
      try {
        return new RegExp(source);
      } catch (error) {
        fail(`preserve_patterns inválido ("${source}"): ${error.message}`);
      }
    });

  return {
    redaction: {
      enabled: redaction.enabled !== false,
      replacement: typeof redaction.replacement === "string" ? redaction.replacement : "[REDACTED:{type}]",
      allowlist: (Array.isArray(redaction.allowlist) ? redaction.allowlist : []).filter(
        (value) => typeof value === "string" && value,
      ),
      patterns: compiledPatterns,
    },
    truncation: {
      mode: typeof truncation.mode === "string" ? truncation.mode : defaults.overflow_mode ?? "head_tail",
      headLines: positiveInt(truncation.head_lines, 120),
      tailLines: positiveInt(truncation.tail_lines, 60),
      marker:
        typeof truncation.marker === "string"
          ? truncation.marker
          : "... {omitted_lines} linhas omitidas (ref: {ref}) ...",
      preservePatterns,
    },
    defaults: {
      maxLines: positiveInt(defaults.max_lines_per_response, 200),
      maxBytes: positiveInt(defaults.max_bytes_per_response, 32768),
    },
    handles: {
      enabled: handles.enabled !== false,
      storeDir: typeof handles.store_dir === "string" ? handles.store_dir : ".cache/tool-output",
      storeRedactedOnly: handles.store_redacted_only !== false,
      ttlMinutes: positiveInt(handles.ttl_minutes, 120),
    },
  };
}

function positiveInt(value, fallback) {
  return Number.isInteger(value) && value > 0 ? value : fallback;
}

// ------------------------------------------------------------------ redação

function redact(text, config) {
  if (!config.redaction.enabled) return { text, count: 0 };

  let working = text;
  const protectedValues = [];

  // Allowlist: protege os valores contra a própria redação.
  for (const allowed of config.redaction.allowlist) {
    const token = `\u0000ALLOW${protectedValues.length}\u0000`;
    protectedValues.push(allowed);
    working = working.split(allowed).join(token);
  }

  let count = 0;
  for (const pattern of config.redaction.patterns) {
    working = working.replace(pattern.regex, () => {
      count += 1;
      return config.redaction.replacement.replaceAll("{type}", pattern.type);
    });
  }

  protectedValues.forEach((value, index) => {
    working = working.split(`\u0000ALLOW${index}\u0000`).join(value);
  });

  return { text: working, count };
}

// --------------------------------------------------------------- truncamento

/**
 * Devolve a lista de peças que compõem a saída:
 *   { type: "line", value } ou { type: "gap", count }
 * O marcador é montado depois, quando o handle do texto já é conhecido.
 */
function buildPieces(text, config, options) {
  const lines = text.replace(/\n$/, "").split("\n");
  const totalLines = lines.length;
  const maxLines = options.maxLines ?? config.defaults.maxLines;
  const mode = config.truncation.mode;

  if (mode === "none" || totalLines <= maxLines) {
    return { pieces: lines.map((value) => ({ type: "line", value })), totalLines, omitted: 0, cut: false };
  }

  const keep = new Set();

  if (mode === "head") {
    for (let i = 0; i < maxLines; i++) keep.add(i);
  } else if (mode === "tail") {
    for (let i = totalLines - maxLines; i < totalLines; i++) keep.add(i);
  } else {
    let head = config.truncation.headLines;
    let tail = config.truncation.tailLines;

    const pair = head + tail;
    if (pair >= maxLines) {
      head = Math.max(1, Math.floor(maxLines * 0.66));
      tail = Math.max(1, maxLines - head);
    } else {
      head = Math.max(1, maxLines - tail);
    }

    for (let i = 0; i < Math.min(head, totalLines); i++) keep.add(i);
    for (let i = Math.max(0, totalLines - tail); i < totalLines; i++) keep.add(i);
  }

  for (let i = 0; i < totalLines; i++) {
    const line = lines[i].length > 500 ? lines[i].slice(0, 500) : lines[i];
    if (config.truncation.preservePatterns.some((regex) => regex.test(line))) keep.add(i);
  }

  const pieces = [];
  let omitted = 0;
  let gap = 0;

  for (let i = 0; i < totalLines; i++) {
    if (keep.has(i)) {
      if (gap > 0) {
        pieces.push({ type: "gap", count: gap });
        omitted += gap;
        gap = 0;
      }
      pieces.push({ type: "line", value: lines[i] });
    } else {
      gap += 1;
    }
  }

  if (gap > 0) {
    pieces.push({ type: "gap", count: gap });
    omitted += gap;
  }

  return { pieces, totalLines, omitted, cut: true };
}

function renderPieces(pieces, config, handle) {
  return pieces
    .map((piece) =>
      piece.type === "gap"
        ? config.truncation.marker
            .replaceAll("{omitted_lines}", String(piece.count))
            .replaceAll("{omitted}", String(piece.count))
            .replaceAll("{ref}", handle)
        : piece.value,
    )
    .join("\n");
}

function clampBytes(text, maxBytes) {
  if (Buffer.byteLength(text, "utf8") <= maxBytes) return text;

  const suffix = `\n... truncado em ${maxBytes} bytes ...`;
  let low = 0;
  let high = text.length;

  while (low < high) {
    const mid = Math.ceil((low + high) / 2);
    const candidate = text.slice(0, mid);
    if (Buffer.byteLength(candidate, "utf8") + Buffer.byteLength(suffix, "utf8") <= maxBytes) low = mid;
    else high = mid - 1;
  }

  return text.slice(0, low) + suffix;
}

// ------------------------------------------------------------------- handles

function storeHandle(content, config, options) {
  if (!options.store || !config.handles.enabled) return null;

  const dir = path.resolve(ROOT, config.handles.storeDir);
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });

  const file = path.join(dir, `${Date.now()}-${crypto.randomBytes(4).toString("hex")}.log`);
  fs.writeFileSync(file, content, { mode: 0o600 });
  fs.chmodSync(file, 0o600);

  cleanupExpired(dir, config.handles.ttlMinutes);

  return { absolute: file, relative: path.relative(ROOT, file) };
}

function cleanupExpired(dir, ttlMinutes) {
  const cutoff = Date.now() - ttlMinutes * 60_000;

  let entries = [];
  try {
    entries = fs.readdirSync(dir);
  } catch {
    return;
  }

  for (const entry of entries) {
    if (!entry.endsWith(".log")) continue;
    const file = path.join(dir, entry);
    try {
      if (fs.statSync(file).mtimeMs < cutoff) fs.unlinkSync(file);
    } catch {
      // arquivo removido no meio do caminho: ignora
    }
  }
}

// --------------------------------------------------------------------- stdin

function readStdin() {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;

    process.stdin.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_INPUT_BYTES) {
        reject(new Error(`entrada maior que ${MAX_INPUT_BYTES / 1024 / 1024} MB`));
        process.stdin.destroy();
        return;
      }
      chunks.push(chunk);
    });
    process.stdin.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    process.stdin.on("error", reject);
  });
}

// ---------------------------------------------------------------------- main

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const config = loadConfig(options.config);

  if (options.check) {
    process.stdout.write(
      "vibeguard: configuração válida\n" +
        `  redação: ${config.redaction.enabled ? `${config.redaction.patterns.length} padrão(ões)` : "desativada"}\n` +
        `  truncamento: ${config.truncation.mode} (${config.truncation.headLines}+${config.truncation.tailLines} linhas, ${config.defaults.maxBytes} bytes)\n` +
        `  handles: ${config.handles.enabled ? config.handles.storeDir : "desativado"}\n`,
    );
    return EXIT_OK;
  }

  if (process.stdin.isTTY) {
    usage();
    return EXIT_INVALID;
  }

  let input;
  try {
    input = await readStdin();
  } catch (error) {
    fail(`não consegui ler a entrada: ${error.message}`);
  }

  if (!input.trim()) {
    process.stdout.write("");
    return EXIT_OK;
  }

  const redacted = redact(input, config);
  const stored = storeHandle(
    config.handles.storeRedactedOnly ? redacted.text : input,
    config,
    options,
  );
  const handle = stored ? stored.relative : "(não armazenado)";

  const { pieces, totalLines, omitted, cut } = buildPieces(redacted.text, config, options);
  const rendered = renderPieces(pieces, config, handle);
  const output = clampBytes(rendered, options.maxBytes ?? config.defaults.maxBytes);

  process.stdout.write(output.endsWith("\n") ? output : `${output}\n`);

  if (options.verbose) {
    process.stderr.write(
      `vibeguard: ${totalLines} linha(s) → ${output.split("\n").length} · ` +
        `${redacted.count} redação(ões) · ${omitted} omitida(s)${cut ? "" : " · sem corte"}\n`,
    );
  }

  return EXIT_OK;
}

main()
  .then((code) => process.exit(code))
  .catch((error) => {
    process.stderr.write(`vibeguard: erro inesperado: ${error?.stack ?? error}\n`);
    process.exit(EXIT_INVALID);
  });
