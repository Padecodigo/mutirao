#!/usr/bin/env node
// PROPÓSITO: verificar se um pacote existe no registro oficial do npm ANTES de
// qualquer instalação — defesa determinística contra slopsquatting (nome de
// pacote alucinado por LLM e registrado por atacante).
//
// Uso:  node security/scripts/verify-deps.mjs <pacote> [pacote...]
// Saída: 0 = existe | 1 = não existe | 2 = não foi possível verificar (rede/uso)
//
// Semântica dos códigos: 1 é uma resposta ("não existe, não instale");
// 2 é ignorância ("não sei"), e nesse caso a regra é PARAR, nunca supor que existe.
//
// Regra 2 de security/rules/security-rules.md.

const REGISTRY = "https://registry.npmjs.org/";
const TIMEOUT_MS = 10_000;

// Nome de pacote npm: opcional @scope/ seguido de nome minúsculo, URL-safe.
const PACKAGE_NAME = /^(@[a-z0-9-~][a-z0-9-._~]*\/)?[a-z0-9-~][a-z0-9-._~]*$/;

const SYMBOL = {
  ok: "[OK]",
  missing: "[FALTA]",
  unknown: "[?]",
  error: "[ERRO]",
};

function usage(stream = process.stdout) {
  stream.write(
    [
      "uso: node security/scripts/verify-deps.mjs <pacote> [pacote...]",
      "",
      "Consulta https://registry.npmjs.org/ e informa se o pacote existe.",
      "",
      "códigos de saída:",
      "  0  todos os pacotes existem",
      "  1  pelo menos um pacote NÃO existe (não instale)",
      "  2  não foi possível verificar (rede, uso incorreto) — pare e investigue",
      "",
      "exemplos:",
      "  node security/scripts/verify-deps.mjs express",
      "  node security/scripts/verify-deps.mjs @types/node zod",
      "",
    ].join("\n"),
  );
}

/** Codifica o nome para a URL do registro: @scope/nome -> @scope%2Fnome */
function encodePackageName(name) {
  return name.startsWith("@") ? name.replace("/", "%2F") : name;
}

/** Consulta o registro. Retorna { status: "ok"|"missing"|"unknown", detail }. */
async function checkPackage(name) {
  if (!PACKAGE_NAME.test(name)) {
    return {
      status: "unknown",
      detail: "nome inválido para o npm (use minúsculas, sem espaço, ex.: @scope/nome)",
    };
  }

  const url = REGISTRY + encodePackageName(name);

  let response;
  try {
    response = await fetch(url, {
      headers: { accept: "application/json" },
      signal: AbortSignal.timeout(TIMEOUT_MS),
      redirect: "follow",
    });
  } catch (error) {
    const reason =
      error?.name === "TimeoutError"
        ? `tempo esgotado após ${TIMEOUT_MS / 1000}s`
        : error?.cause?.code || error?.message || "falha de rede";
    return { status: "unknown", detail: `não consegui consultar o registro (${reason})` };
  }

  if (response.status === 404) {
    return {
      status: "missing",
      detail: "não existe no npm — NÃO instale; confira se o nome foi inventado ou digitado errado",
    };
  }

  if (!response.ok) {
    return {
      status: "unknown",
      detail: `registro respondeu HTTP ${response.status} — não é possível confirmar a existência`,
    };
  }

  let data;
  try {
    data = await response.json();
  } catch {
    return { status: "unknown", detail: "resposta do registro não é JSON válido" };
  }

  const latest = data?.["dist-tags"]?.latest ?? "sem versão estável";
  const description = typeof data?.description === "string" ? data.description.trim() : "";
  const repo =
    (typeof data?.repository === "string" ? data.repository : data?.repository?.url) ?? "";
  const homepage = typeof data?.homepage === "string" ? data.homepage : "";

  return {
    status: "ok",
    detail: [
      `versão mais recente: ${latest}`,
      description && `descrição: ${truncate(description, 100)}`,
      repo && `repositório: ${repo}`,
      !repo && homepage && `site: ${homepage}`,
    ]
      .filter(Boolean)
      .join(" | "),
  };
}

function truncate(text, max) {
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

function printResult(name, result) {
  const prefix =
    result.status === "ok" ? SYMBOL.ok : result.status === "missing" ? SYMBOL.missing : SYMBOL.unknown;
  console.log(`${prefix} ${name}`);
  console.log(`      ${result.detail}`);
}

async function main() {
  const args = process.argv.slice(2).filter((a) => a !== "--");

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    usage(args.length === 0 ? process.stderr : process.stdout);
    return 2;
  }

  if (typeof fetch !== "function" || typeof AbortSignal?.timeout !== "function") {
    console.error(
      `${SYMBOL.error} Node.js sem fetch nativo — é preciso Node 18+ para verificar pacotes.`,
    );
    return 2;
  }

  const results = [];
  for (const name of args) {
    const normalized = name.trim();
    if (!normalized) continue;
    const result = await checkPackage(normalized);
    printResult(normalized, result);
    results.push(result);
  }

  if (results.length === 0) {
    usage(process.stderr);
    return 2;
  }

  const unknown = results.filter((r) => r.status === "unknown").length;
  const missing = results.filter((r) => r.status === "missing").length;

  console.log("");
  if (unknown > 0) {
    console.log(
      `${SYMBOL.error} ${unknown} pacote(s) sem resposta do registro. Não trate como "existe" — pare e investigue.`,
    );
    return 2;
  }
  if (missing > 0) {
    console.log(`${SYMBOL.missing} ${missing} pacote(s) não existem. Não instale.`);
    return 1;
  }
  console.log(`${SYMBOL.ok} ${results.length} pacote(s) confirmados no registro.`);
  return 0;
}

const exitCode = await main();
process.exitCode = exitCode;
