// PROPÓSITO: parser YAML mínimo (sem dependências) para ler os arquivos de
// configuração deste repositório (security/vibeguard.yaml e
// token-optimization/config.example.yaml). Cobre o subconjunto que usamos:
// mapas aninhados por indentação, listas, escalares quoted/plain, números,
// booleanos e listas em fluxo ([a, b]).
//
// NÃO é um parser YAML completo: âncoras, aliases, tags, multi-linha e
// documentos múltiplos não são suportados. Se precisar disso, use uma lib real.
//
// Validação: comparado contra o PyYAML em tests/test-vibeguard.sh.

export function parseYaml(source) {
  const rawLines = String(source).replace(/^\uFEFF/, "").split(/\r?\n/);
  const lines = [];

  for (let i = 0; i < rawLines.length; i++) {
    const withoutComment = stripComment(rawLines[i]);
    if (!withoutComment.trim()) continue;
    const trimmed = withoutComment.trim();
    if (trimmed === "---" || trimmed === "...") continue;
    const indent = withoutComment.match(/^ */)[0].length;
    lines.push({ indent, text: trimmed, line: i + 1 });
  }

  if (lines.length === 0) return {};

  const [value, next] = parseBlock(lines, 0, lines[0].indent);
  if (next < lines.length) {
    throw new YamlError(`conteúdo inesperado na linha ${lines[next].line}`, lines[next].line);
  }
  return value;
}

export class YamlError extends Error {
  constructor(message, line) {
    super(line ? `YAML linha ${line}: ${message}` : `YAML: ${message}`);
    this.name = "YamlError";
  }
}

function stripComment(line) {
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];

    if (quote === '"') {
      if (ch === "\\") { i++; continue; }
      if (ch === '"') quote = null;
      continue;
    }
    if (quote === "'") {
      if (ch === "'" && line[i + 1] === "'") { i++; continue; }
      if (ch === "'") quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") { quote = ch; continue; }
    if (ch === "#" && (i === 0 || /\s/.test(line[i - 1]))) return line.slice(0, i);
  }
  return line;
}

function parseBlock(lines, start, indent) {
  const first = lines[start];
  if (first.text === "-" || first.text.startsWith("- ")) {
    return parseSequence(lines, start, indent);
  }
  return parseMapping(lines, start, indent);
}

function parseMapping(lines, start, indent) {
  const obj = {};
  let i = start;

  while (i < lines.length) {
    const current = lines[i];
    if (current.indent < indent) break;
    if (current.indent > indent) {
      throw new YamlError(`indentação inesperada ("${current.text}")`, current.line);
    }
    if (current.text === "-" || current.text.startsWith("- ")) break;

    const { key, rest } = splitKey(current.text, current.line);

    if (rest === "") {
      const next = lines[i + 1];
      if (next && next.indent > indent) {
        const [value, consumed] = parseBlock(lines, i + 1, next.indent);
        obj[key] = value;
        i = consumed;
      } else {
        obj[key] = null;
        i++;
      }
    } else {
      obj[key] = parseScalar(rest, current.line);
      i++;
    }
  }

  return [obj, i];
}

function parseSequence(lines, start, indent) {
  const arr = [];
  let i = start;

  while (i < lines.length) {
    const current = lines[i];
    if (current.indent !== indent) break;
    if (current.text !== "-" && !current.text.startsWith("- ")) break;

    const itemText = current.text === "-" ? "" : current.text.slice(2).trim();

    if (itemText === "") {
      const next = lines[i + 1];
      if (!next || next.indent <= indent) {
        arr.push(null);
        i++;
      } else {
        const [value, consumed] = parseBlock(lines, i + 1, next.indent);
        arr.push(value);
        i = consumed;
      }
      continue;
    }

    if (looksLikeMappingEntry(itemText)) {
      // Reescreve "- chave: valor" como um mapa na indentação do item.
      lines[i] = { indent: indent + 2, text: itemText, line: current.line };
      const [value, consumed] = parseMapping(lines, i, indent + 2);
      arr.push(value);
      i = consumed;
      continue;
    }

    arr.push(parseScalar(itemText, current.line));
    i++;
  }

  return [arr, i];
}

function looksLikeMappingEntry(text) {
  const match = text.match(/^([A-Za-z0-9_.-]+):(\s|$)/);
  return Boolean(match);
}

function splitKey(text, lineNumber) {
  const match = text.match(/^([A-Za-z0-9_.-]+):(?:\s+(.*))?$/);
  if (!match) throw new YamlError(`esperava "chave: valor" ("${text}")`, lineNumber);
  return { key: match[1], rest: (match[2] ?? "").trim() };
}

function parseScalar(text, lineNumber) {
  const value = text.trim();

  if (value === "[]") return [];
  if (value === "{}") return {};
  if (value.startsWith("[") && value.endsWith("]")) {
    return splitFlowSequence(value.slice(1, -1)).map((item) => parseScalar(item, lineNumber));
  }
  if (value.startsWith('"')) return parseDoubleQuoted(value, lineNumber);
  if (value.startsWith("'")) return parseSingleQuoted(value, lineNumber);

  if (value === "null" || value === "~" || value === "") return null;
  if (value === "true") return true;
  if (value === "false") return false;
  if (/^-?\d+$/.test(value)) return Number.parseInt(value, 10);
  if (/^-?\d+\.\d+$/.test(value)) return Number.parseFloat(value);

  return value;
}

function parseDoubleQuoted(value, lineNumber) {
  if (!value.endsWith('"') || value.length < 2) {
    throw new YamlError(`string com aspas não fechada ("${value}")`, lineNumber);
  }
  const body = value.slice(1, -1);
  let out = "";

  for (let i = 0; i < body.length; i++) {
    const ch = body[i];
    if (ch !== "\\") { out += ch; continue; }

    const next = body[++i];
    switch (next) {
      case "0": out += "\0"; break;
      case "n": out += "\n"; break;
      case "t": out += "\t"; break;
      case "r": out += "\r"; break;
      case '"': out += '"'; break;
      case "\\": out += "\\"; break;
      case "/": out += "/"; break;
      case "u": {
        const hex = body.slice(i + 1, i + 5);
        if (!/^[0-9a-fA-F]{4}$/.test(hex)) throw new YamlError(`escape \\u inválido em "${value}"`, lineNumber);
        out += String.fromCharCode(Number.parseInt(hex, 16));
        i += 4;
        break;
      }
      default:
        throw new YamlError(`escape desconhecido "\\${next}" em "${value}"`, lineNumber);
    }
  }

  return out;
}

function parseSingleQuoted(value, lineNumber) {
  if (!value.endsWith("'") || value.length < 2) {
    throw new YamlError(`string com aspas não fechada ("${value}")`, lineNumber);
  }
  return value.slice(1, -1).replace(/''/g, "'");
}

function splitFlowSequence(body) {
  const items = [];
  let current = "";
  let quote = null;

  for (let i = 0; i < body.length; i++) {
    const ch = body[i];

    if (quote) {
      current += ch;
      if (ch === "\\" && quote === '"') { current += body[++i] ?? ""; continue; }
      if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") { quote = ch; current += ch; continue; }
    if (ch === ",") { items.push(current.trim()); current = ""; continue; }
    current += ch;
  }

  if (current.trim()) items.push(current.trim());
  return items;
}
