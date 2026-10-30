<!-- PROPÓSITO: visão geral da arquitetura do repositório base de vibecoding —
     os pilares (segurança, economia de tokens, skills), a estrutura de pastas,
     as ferramentas verificadas e o passo a passo de inicialização em 3 comandos. -->

# Mutirão — base de vibecoding assistida por LLM

Ambiente de desenvolvimento para trabalhar com agentes de IA sem sustos: regras de
segurança aplicadas por ferramentas (não por "bom senso" do modelo), contexto que
não estoura e capacidades reutilizáveis em vez de instruções coladas no chat.

Funciona com **DeepSeek Harness, Claude Code, Cursor, Codex e Gemini CLI** — todos
leem o [`AGENTS.md`](AGENTS.md) deste repositório.

---

## Os três pilares

| Pilar | Problema que resolve | Onde |
|---|---|---|
| **Segurança determinística** | segredo vazado, pacote alucinado, prompt injection oculto, comando destrutivo | [`security/`](security/rules/security-rules.md) |
| **Economia de tokens** | saída de terminal gigante comendo a janela de contexto | [`token-optimization/`](token-optimization/README.md) |
| **Skills** | agente improvisando o que já deveria saber | [`skills/`](skills/README.md) |

A cola entre os três é a **orquestração**: [`scripts/setup.sh`](scripts/setup.sh)
prepara o ambiente e [`scripts/sync.sh`](scripts/sync.sh) mantém tudo em dia.

---

## Início rápido — 3 comandos

```bash
bash scripts/setup.sh     # 1. valida Node/Git/Bash, cria pastas, marca scripts como executáveis
bash scripts/sync.sh      # 2. confere segurança, skills e dependências
cat AGENTS.md             # 3. leia as regras que o agente vai seguir
```

Nada é instalado sem você mandar: o `setup.sh` só **mostra** os comandos das
ferramentas auxiliares (skillshare, ShrinkWrap, VibeGuard, RTK).

---

## Estrutura

```text
.
├── AGENTS.md                  # regras obrigatórias para qualquer harness
├── security/
│   ├── rules/security-rules.md    # as 5 regras (segredo, pacote, zero-width, privilégio, destrutivo)
│   ├── scripts/verify-deps.mjs    # confere pacote no npm antes de instalar (exit 0/1/2)
│   └── vibeguard.yaml             # limites de contexto + redação de PII/segredo
├── skills/
│   ├── README.md                  # convenção de SKILL.md e como registrar capacidade
│   └── find-skill/SKILL.md        # busca e instala skills; se não achar, reporta a ausência
├── token-optimization/
│   ├── README.md                  # proxy MCP, wrappers de CLI, regras de truncamento
│   └── config.example.yaml        # template de limites e estratégias
├── scripts/                       # setup.sh, sync.sh
├── docs/                          # guias existentes (como começar, segurança, FAQ)
├── .agents/                       # personas: maestro, frontend, backend, revisor
└── .specify/                      # spec, contratos e tarefas
```

---

## Ferramentas auxiliares (todas verificadas)

| Ferramenta | Para quê | Instalação |
|---|---|---|
| [skillshare](https://github.com/runkids/skillshare) | sincronizar skills entre harnesses | `curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh \| sh` ou `brew install skillshare` |
| [ShrinkWrap](https://github.com/lucronn/shrinkwrap) | proxy MCP: resume payload grande e devolve handle | `pip install shrinkwrap-cli` |
| [RTK](https://github.com/rtk-ai/rtk) | comprime saída de comandos de terminal | `brew install rtk` (confirme com `rtk gain`) |
| [VibeGuard](https://github.com/zeroFhacker/vibeguard) | linter de segurança para código gerado por IA | `git clone` + `pip install -r requirements.txt` |

Nenhuma é dependência obrigatória: o repositório funciona offline com Node 18+ e Bash.

---

## Segurança em 30 segundos

1. **Pacote?** `node security/scripts/verify-deps.mjs <pacote>` — `1` significa "não existe, não instale".
2. **Commit?** `mutirao guard staged` — a trava recusa se houver segredo.
3. **Comando destrutivo?** pare e peça autorização explícita ([regra 5](security/rules/security-rules.md)).
4. **Payload com e-mail/CPF/chave?** redija antes de compactar ([`vibeguard.yaml`](security/vibeguard.yaml)).

Detalhes: [security/rules/security-rules.md](security/rules/security-rules.md).

---

## Compatibilidade com harnesses

| Harness | Como consome as regras |
|---|---|
| DeepSeek Harness | lê `AGENTS.md` na raiz |
| Codex / Cursor / Gemini CLI | leem `AGENTS.md` automaticamente |
| Claude Code | lê [`CLAUDE.md`](CLAUDE.md), que aponta para `AGENTS.md` |
| Qualquer outro | cole o conteúdo de `AGENTS.md` na primeira mensagem |

---

## Documentação

- [AGENTS.md](AGENTS.md) — regras obrigatórias para agentes
- [security/rules/security-rules.md](security/rules/security-rules.md) — segurança
- [skills/README.md](skills/README.md) — convenção de skills
- [token-optimization/README.md](token-optimization/README.md) — economia de contexto
- [docs/como-comecar.md](docs/como-comecar.md) — guia para quem não programa
- [START.md](START.md) — primeiro contato (usar ou desenvolver o Mutirão)
- [CONTRIBUTING.md](CONTRIBUTING.md) — como contribuir
- [SECURITY.md](SECURITY.md) — como reportar falha de segurança

---

## Licença

MIT — veja [LICENSE](LICENSE). O que você constrói com o Mutirão é seu.
