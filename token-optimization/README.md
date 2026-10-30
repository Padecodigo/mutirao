<!-- PROPÓSITO: documentar as estratégias de economia de contexto — proxies de
     transporte MCP, wrappers de CLI, leitura fatiada de arquivos e redação —
     com as ferramentas verificadas e os critérios para escolher cada uma. -->

# Otimização de tokens

Token é o recurso mais caro e mais escasso do fluxo com LLM: define custo, latência e,
principalmente, **quanto o agente consegue lembrar**. Saída de terminal gigante é o
maior ofensor — um `git log` sem limite ou um `npm install` verboso consome a janela
inteira e o agente esquece o que estava fazendo.

Regra da casa: **o dado bruto não precisa entrar no contexto; a referência a ele precisa.**

---

## 1. Proxy de transporte (MCP) — intercepta antes de virar contexto

**O que faz:** fica entre o harness e o servidor MCP. Recebe o payload grande, guarda
o bruto num buffer local e entrega ao modelo um **resumo estruturado + handles**
(`sw-ref:…`) que permitem buscar o trecho exato depois, sem reenviar tudo.

**Ferramenta verificada:** [ShrinkWrap](https://github.com/lucronn/shrinkwrap) —
"protocol-level transport proxy and compaction engine for MCP tool outputs and CLI
execution streams".

```bash
pip install shrinkwrap-cli     # requer Python 3
shrinkwrap install             # envolve as configs MCP ativas
shrinkwrap status              # confirma o que foi envolvido
shrinkwrap benchmark           # mede a economia
```

**Quando usar:** resposta de API, JSON de banco, log de servidor, resultado de busca
na web — qualquer payload em que o modelo precise de **fatos**, não de todos os bytes.

**Cuidado:** se o resumo esconder o erro, o agente alucina a causa. Payload de falha
segue a regra de truncamento preservando `error`/stacktrace (seção 5).

---

## 2. Wrappers de CLI — comprime antes do harness ler

**O que faz:** reescreve comandos conhecidos (`ls`, `git status`, `grep`) para um
equivalente compacto, com contagem e agrupamento em vez de uma linha por item.

**Ferramenta verificada:** [RTK — Rust Token Killer](https://github.com/rtk-ai/rtk)
(binário único, 100+ comandos, <10 ms de overhead):

```bash
brew install rtk     # macOS/Linux (ou winget install rtk-ai.rtk; ou install.sh)
rtk --version
rtk gain             # painel de economia — se der "command not found", instalou o errado
rtk init -g          # Claude Code / Copilot
rtk init -g --codex  # Codex
rtk init -g --gemini # Gemini CLI
rtk init -g --agent cursor
```

> ⚠️ Existe outro projeto chamado `rtk` no crates.io — confirme pelo `rtk gain`.

**Alternativa sem dependência** (funciona offline, qualquer máquina com coreutils):

```bash
# guardar o bruto fora do contexto e ler só o essencial
mkdir -p .cache/tool-output
npm test > .cache/tool-output/test.log 2>&1
tail -n 40 .cache/tool-output/test.log        # só o fim (onde o erro aparece)
grep -nE 'FAIL|Error' .cache/tool-output/test.log | head -20
```

**Nota de escopo:** o pedido original citava "TokMan/PTK". Não existe projeto
verificável com esses nomes (o pacote npm `ptk` é um kit de performance web, sem
relação). Por isso este documento usa **RTK**, que é real, e o padrão manual acima.

---

## 3. Memória entre sessões — não é compressão

**Ferramenta verificada:** [ai-memory](https://github.com/akitaonrails/ai-memory)
(★14,5k, MIT, Rust) — memória de longo prazo compartilhada entre 20+ harnesses,
com *handoff* tipado: saia do Claude Code no meio, abra o Codex no mesmo diretório
e ele retoma com o que falhou e o que ficou aberto.

```bash
curl -fsSL https://github.com/akitaonrails/ai-memory/releases/latest/download/install.sh | sh
ai-memory setup --yes --agent claude-code   # ou codex, cursor, gemini-cli...
# reinicie o harness para carregar MCP + hooks
```

**A economia é indireta:** você deixa de reexplicar arquitetura e tentativas
falhas a cada sessão. O custo é o *startup packet* injetado no começo — memória
não é compressão. A compressão extrativa do ai-memory vem **desligada por padrão**.

Diferença entre as três camadas (não confunda):

| Camada | Ferramenta | O que "economiza" | Custo/risco |
|---|---|---|---|
| **Memória** | ai-memory | retrabalho entre sessões e troca de agente | injeta contexto no início; dados ficam **fora** do repositório |
| **Compressão** | ShrinkWrap, RTK | bytes de saída de ferramenta | resumo pode esconder a causa do erro |
| **Redação** | `vibeguard.mjs` | não é economia: é vazamento evitado | redigir demais esconde dado útil |

Instalação opcional neste repositório: `bash scripts/install-tools.sh --ai-memory`
(ou `--ai-memory-agent claude-code`). Nada é instalado sem a flag.

## 4. Leitura fatiada (progressive disclosure)

Quem controla o custo é o **agente**, não a ferramenta:

- `grep` primeiro, `read` depois — localize a linha e leia só o trecho (`offset`/`limit`).
- Nunca `cat` de arquivo inteiro "para entender o projeto": liste, depois leia.
- `git diff --stat` antes de `git diff`; `--unified=0` quando só interessa o que mudou.
- Em log: `tail` + `grep` do identificador de erro. Nunca o arquivo todo.

---

## 5. Regras de truncamento (não negociáveis)

1. **Cabeça + cauda, com marcador explícito.** Nunca corte silenciosamente:
   `… 412 linhas omitidas (ref: .cache/tool-output/test.log) …`
2. **Erro e stacktrace têm prioridade.** Se houver `Error`, `Exception`, `FAIL` ou
   `Traceback`, preserve o bloco inteiro e corte o resto.
3. **Guarde o bruto.** Arquivo local fora do repositório versionado (`.cache/`,
   já no `.gitignore`) e passe o caminho — o agente pode voltar sem reexecutar.
4. **Redija antes de compactar.** Aplique `security/vibeguard.yaml` primeiro; resumir
   um payload com chave dentro é vazamento, não economia.
5. **Nada de "resumo" inventado.** Se a ferramenta não suporta resumo estruturado,
   trunque de forma determinística (linhas/bytes) — não peça ao modelo para resumir o
   que ele não leu.

---

## 6. Orçamento e configuração

**Já ativo:** o filtro local [`security/scripts/vibeguard.mjs`](../security/scripts/vibeguard.mjs)
lê `security/vibeguard.yaml` e aplica redação + truncamento + handle de verdade:

```bash
meu-comando 2>&1 | node security/scripts/vibeguard.mjs            # usa os padrões
meu-comando | node security/scripts/vibeguard.mjs --max-lines 80  # aperta o limite
node security/scripts/vibeguard.mjs --check                       # valida a configuração
```

O template [`config.example.yaml`](config.example.yaml) continua sendo a referência
para **proxies externos** (ShrinkWrap e afins): limites por sessão, estratégia de
resumo, overrides por comando. Copie para `token-optimization/config.local.yaml`
(não versionado) e ajuste.

Relação com as outras camadas:

| Camada | Papel |
|---|---|
| `security/vibeguard.yaml` | redação de PII/segredo **antes** da compactação |
| `security/rules/security-rules.md` | menor privilégio e confirmação humana |
| `token-optimization/config.example.yaml` | quanto e como cortar |

---

## 7. Como medir (sem achismo)

| Medida | Como |
|---|---|
| Tamanho | `wc -l arquivo`, `wc -c arquivo` |
| Estimativa de tokens | ~4 bytes por token em inglês/código; ~3 em pt-BR — **heurística**, não verdade |
| Economia do proxy | `shrinkwrap benchmark` |
| Economia do wrapper | `rtk gain` |
| Contexto real | contador de tokens do próprio harness (quando existir) |

Meça antes e depois. "Deve economizar" não é resultado; número no terminal é.

---

## 8. Tabela de decisão

| Situação | Estratégia |
|---|---|
| Saída de comando de terminal (`ls`, `git`, `grep`) | wrapper (RTK) ou fallback manual |
| JSON/HTML/API grande vindo de MCP | proxy (ShrinkWrap) → resumo + handle |
| Arquivo de código | leitura fatiada (`grep` → `read` com offset) |
| Log de teste/build | `tail` + `grep` do erro; bruto em `.cache/` |
| Payload com PII/segredo | `vibeguard.yaml` **primeiro**, depois comprimir |
| Dúvida se o dado importa | guardar bruto, passar referência e perguntar |

---

## 9. Falhas comuns

| Sintoma | Causa provável | Correção |
|---|---|---|
| Agente "esquece" o começo da tarefa | contexto estourou | orçamento por sessão + resumo de estado no `tasks.md` |
| Agente inventa a causa do erro | resumo comeu o stacktrace | preservar bloco de erro; voltar ao bruto |
| Economia zero após instalar | wrapper não está interceptando | `rtk gain` / `shrinkwrap status`; conferir `init` do harness |
| Segredo apareceu no resumo | redação rodou depois | redigir **antes** de compactar (`fail_closed: true`) |
