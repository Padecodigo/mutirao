# `.agents/` — a equipe do mutirão

Cada arquivo aqui é uma **persona**: um jeito de trabalhar, com escopo e regras
próprias. Você pode usar uma pessoa só (o Maestro fazendo tudo) ou várias em
worktrees separadas.

| Arquivo | Papel | Use quando |
|---|---|---|
| [maestro.md](maestro.md) | fala com a pessoa, escreve spec, divide trabalho | sempre — é o ponto de entrada |
| [frontend.md](frontend.md) | telas, componentes, estilo | a tarefa é visível |
| [backend.md](backend.md) | rotas, banco, integrações | a tarefa é de dados/regra |
| [revisor.md](revisor.md) | confere, testa, junta | antes de entregar ou juntar branch |
| [gates.md](gates.md) | roteiro das 4 paradas | sempre que for tocar em conta/pagamento/deploy/chave |

---

## Como acionar uma persona

Depende da ferramenta. O padrão é: **a persona vai no prompt, o projeto vai no
diretório**.

**Claude Code / Codex / Gemini CLI** (na pasta do agente):

```
Leia AGENTS.md e .agents/frontend.md. Atue como o Frontend.
Sua tarefa está em .specify/specs/001-doceria/tasks.md, itens T2 e T3.
Contrato: .specify/specs/001-doceria/contracts/ui.md
```

**Cursor / Copilot / Windsurf:** cole o mesmo texto no chat do editor, ou
referencie os arquivos com `@AGENTS.md @.agents/frontend.md`.

**Qualquer ferramenta:** o conteúdo de `AGENTS.md` + da persona pode ser colado
no início da conversa. Nada aqui depende de plugin.

---

## Por que trabalho paralelo precisa de worktree

Dois agentes no mesmo diretório se atropelam: um salva por cima do outro, o
`git status` vira ruído e ninguém sabe quem quebrou o quê. Com worktree, cada
agente tem a sua cópia e a sua branch, e a junção é um ato consciente do Revisor.

```bash
mutirao worktree new frontend
mutirao worktree new backend
mutirao worktree status
mutirao worktree remove frontend
```

---

## O que não é negociável

1. Contrato antes de paralelo.
2. Um dono por pasta.
3. Ninguém imprime chave.
4. Ninguém junta branch vermelha.
