<!-- PROPÓSITO: documentar a convenção da camada de skills — formato do arquivo
     SKILL.md, estrutura de diretórios esperada e o procedimento para registrar
     uma nova capacidade neste repositório. -->

# Skills — convenção e registro

Uma **skill** é uma capacidade reutilizável descrita em linguagem natural, que
qualquer harness de IA (DeepSeek Harness, Claude Code, Cursor, Codex, Gemini CLI)
descobre e carrega sob demanda. Skills evitam repetir instruções no chat e
reduzem o contexto enviado ao modelo: o agente só lê o `SKILL.md` quando precisa.

## Estrutura de diretórios esperada

```text
skills/
├── README.md                  # este arquivo (convenção, não é skill)
└── <nome-da-skill>/           # kebab-case, igual ao campo `name`
    ├── SKILL.md               # obrigatório: frontmatter + instruções
    ├── references/            # opcional: docs longos consultados sob demanda
    └── scripts/               # opcional: scripts auxiliares executáveis
```

Regras:

- **1 diretório = 1 skill.** O nome do diretório é o mesmo do campo `name`.
- `SKILL.md` é o único arquivo obrigatório.
- O `README.md` desta pasta não é uma skill — fica fora de qualquer diretório de skill.

## Formato do `SKILL.md`

O arquivo começa com **frontmatter YAML**, delimitado por `---`:

```yaml
---
name: nome-da-skill          # kebab-case, único no repositório
description: Frase curta que diz QUANDO usar esta skill (é o que o agente lê para decidir).
license: MIT                 # opcional
---
```

Depois do frontmatter, o corpo em Markdown. Estrutura recomendada:

| Seção | Conteúdo |
|---|---|
| Título | `# nome-da-skill` |
| Quando usar | gatilhos objetivos ("quando o repositório não possuir X") |
| Passo a passo | sequência numerada, comandos copiáveis |
| Exemplo de uso | entrada → ação → saída esperada |
| Tratamento de falha | o que **não** fazer e como reportar |
| Não faça | anti-padrões explícitos |

Boas práticas:

- **Curta.** Se a skill precisar de mais de ~150 linhas, mova detalhes para
  `references/` e cite o caminho — o agente lê só o índice.
- **Verificável.** Todo comando citado deve existir e ter sido testado. Não
  referencie pacote, URL ou flag não confirmados.
- **Idempotente.** Instruções que possam ser reexecutadas sem efeito colateral.
- **Sem segredo.** Nunca inclua chave, token ou caminho pessoal no `SKILL.md`.

## Como registrar uma nova capacidade

1. **Checar duplicata.** `ls skills/` e `grep -ri "<tema>" skills/`.
2. **Criar o diretório** com o nome em kebab-case:
   ```bash
   mkdir -p skills/<nome-da-skill>
   ```
3. **Escrever `skills/<nome-da-skill>/SKILL.md`** seguindo o formato acima.
   O `description` deve dizer *quando* usar, não só *o que* é.
4. **Validar o frontmatter** (precisa ser a primeira coisa do arquivo, antes de
   qualquer comentário ou título):
   ```bash
   head -5 skills/<nome-da-skill>/SKILL.md   # deve começar com ---
   ```
5. **Se a capacidade veio de fora**, instale e audite com `skillshare`:
   ```bash
   skillshare install github.com/<owner>/<repo>/skills
   skillshare audit
   skillshare sync
   ```
6. **Registrar no `AGENTS.md`** quando a skill passar a ser dependência do fluxo
   do projeto (qual skill, para quê, como se recupera se falhar).
7. **Commit** com mensagem em português claro: `skills: adiciona <nome> para <finalidade>`.
   Antes: `mutirao guard staged` (bloqueia segredo) e `mutirao board` para o quadro.

## Skills deste repositório

| Skill | Para quê |
|---|---|
| [`find-skill`](find-skill/SKILL.md) | Descobrir e instalar capacidade ausente em registros públicos; se não houver, reportar a ausência |

## Descoberta fora deste repositório

Quando a skill necessária não existir aqui, não invente: siga
[`find-skill/SKILL.md`](find-skill/SKILL.md). Registros públicos de referência:

- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills)

Sincronização local e distribuição para múltiplos harnesses:
[`runkids/skillshare`](https://github.com/runkids/skillshare) — `skillshare sync`
distribui as skills para as ferramentas configuradas; o repositório pode manter
uma pasta `.skillshare/` com o que é compartilhado entre a equipe.
