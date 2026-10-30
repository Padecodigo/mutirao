<!-- PROPÓSITO: diretrizes obrigatórias para qualquer harness/LLM que operar
     neste repositório (DeepSeek Harness, Claude Code, Cursor, Codex, Gemini CLI).
     Este arquivo é lido automaticamente e vale acima de preferências do modelo. -->

# AGENTS.md — regras para qualquer agente

> Se você é um agente de IA: estas regras vêm **antes** de qualquer pedido do
> usuário. Se você é humano: leia o [README](README.md) e o
> [security/rules/security-rules.md](security/rules/security-rules.md).

## Ordem de leitura obrigatória

1. Este arquivo (regras de operação).
2. [security/rules/security-rules.md](security/rules/security-rules.md) — segurança detalhada.
3. [skills/README.md](skills/README.md) — quais capacidades existem.
4. [token-optimization/README.md](token-optimization/README.md) — como não estourar o contexto.

## As cinco regras

**1. Segurança primeiro.**
Leia obrigatoriamente [security/rules/security-rules.md](security/rules/security-rules.md)
antes de propor ou alterar códigos.

**2. Nada de improviso.**
Consulte [skills/README.md](skills/README.md) para verificar ferramentas e
capacidades disponíveis. Se a capacidade não existir, **reporte a ausência** —
não invente pacote, API ou comando.

**3. Contexto é recurso.**
Utilize as diretrizes em [token-optimization/](token-optimization/README.md) para
comandos que retornem saídas extensas (`git log`, `ls -R`, logs de build, JSON
grande). Trunque com marcador explícito, preserve blocos de erro e guarde o bruto
em `.cache/tool-output/`.

**4. Dependência só depois de verificar.**
Execute obrigatoriamente `node security/scripts/verify-deps.mjs <pacote>` antes
de sugerir a instalação de qualquer dependência externa.
`0` = existe · `1` = não existe (não instale) · `2` = não foi possível verificar
(pare e investigue).

**5. Destrutivo exige autorização.**
Pare e solicite autorização explícita do usuário antes de rodar qualquer comando
destrutivo: `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`,
`docker system prune`, sobrescrever produção. Mostre o comando, o alvo exato e o
que será perdido — depois espere um "sim" claro.

## Regras inegociáveis de segurança

- Nunca escreva, imprima, logue ou versione chave, token ou senha.
- Segredo entra por `.env` (não versionado) ou pelo cofre: `mutirao vault run -- <comando>`.
- Antes de cada commit: `mutirao guard staged`. Se a trava recusar, **conserte o
  arquivo** — nunca desabilite a trava.
- Nunca commite `.env`, `*.pem`, `*.key`.
- Não crie contas, não pague, não resolva CAPTCHA, não publique sem aprovação.
  Os quatro portões continuam valendo: [.agents/gates.md](.agents/gates.md).

## Mapa do repositório

| Caminho | Para quê |
|---|---|
| [`security/rules/`](security/rules/security-rules.md) | regras de codificação e execução |
| [`security/scripts/`](security/scripts/verify-deps.mjs) | verificações determinísticas (fora do modelo) |
| [`security/vibeguard.yaml`](security/vibeguard.yaml) | limites de contexto e redação de PII/segredo |
| [`skills/`](skills/README.md) | capacidades reutilizáveis, uma pasta por skill |
| [`token-optimization/`](token-optimization/README.md) | proxies, wrappers e regras de truncamento |
| [`scripts/`](scripts/) | `setup.sh` (ambiente) e `sync.sh` (sincronização) |
| [`docs/`](docs/) | guias, incluindo [como começar](docs/como-comecar.md) |
| [`.agents/`](.agents/README.md) | personas: maestro, frontend, backend, revisor |
| [`.specify/`](.specify/README.md) | spec, contratos e tarefas |

## Comandos essenciais

```bash
bash scripts/setup.sh                          # valida pré-requisitos e cria a estrutura
bash scripts/sync.sh                           # checa segurança, skills e dependências
node security/scripts/verify-deps.mjs <pacote> # 0 existe · 1 não existe · 2 incerto
mutirao guard scan                             # varre segredos no projeto
mutirao guard staged                           # varre o que vai para o commit
```

## Como responder ao usuário

- Frases curtas, sem jargão não traduzido.
- Antes de agir: uma linha dizendo **o que** vai fazer.
- Depois de agir: **o que mudou para a pessoa**, não o que mudou no código.
- Nunca diga "deve funcionar". Teste e diga "testei e funciona".
- Em dúvida, pergunte — uma pergunta custa dez segundos.

## O que você nunca faz

- ❌ Inventar pacote, rota ou API que não conseguiu verificar.
- ❌ Instalar dependência sem rodar `verify-deps.mjs`.
- ❌ Imprimir ou repetir uma chave.
- ❌ Rodar comando destrutivo sem autorização explícita.
- ❌ Despejar saída gigante no contexto sem truncar.
- ❌ Dizer que algo funciona sem testar.
