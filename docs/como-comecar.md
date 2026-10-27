# Como começar (do zero absoluto)

Este guia assume que você **nunca programou** e nunca abriu um terminal.
Leva uns 15 minutos até a primeira conversa com a IA.

---

## Antes de tudo: o que você vai precisar

| Item | Para quê | Onde |
|---|---|---|
| Um computador | óbvio | o seu |
| Internet | baixar e conversar com a IA | a sua |
| Uma IA com terminal | é ela que constrói | Claude Code, Codex, Gemini CLI, Cursor… |
| Git | guardar o histórico do projeto | [git-scm.com/downloads](https://git-scm.com/downloads) |
| Conta no GitHub | backup do código na nuvem | [github.com](https://github.com) — grátis |

Conta paga de IA ajuda muito (os agentes de terminal costumam ser pagos), mas o
Mutirão em si é grátis e aberto.

---

## Passo 1 · Abrir o terminal

- **Windows:** menu Iniciar → digite "PowerShell" → Enter. (Se for usar Git,
  instale o "Git for Windows", que já traz tudo.)
- **Mac:** Command + Espaço → digite "Terminal" → Enter.
- **Linux:** Ctrl + Alt + T.

Você vai ver uma linha esperando comando. É só digitar (ou colar) e apertar Enter.

> Dica: no terminal, **colar** costuma ser Ctrl+Shift+V (Linux/Windows) ou
> Cmd+V (Mac). Ctrl+C **não** é copiar ali — é cancelar.

---

## Passo 2 · Baixar o Mutirão

```bash
git clone https://github.com/Padecodigo/mutirao.git ~/mutirao
```

Isso cria a pasta `mutirao` na sua pasta pessoal.

---

## Passo 3 · Criar o seu projeto

```bash
~/mutirao/mutirao init ~/meu-projeto
cd ~/meu-projeto
```

Você verá algo assim:

```
✔ criado: AGENTS.md
✔ criado: .agents
✔ criado: .specify
✔ criado: tools
✔ git inicializado
✔ Projeto criado: /home/voce/meu-projeto
```

Agora você tem um projeto vazio, com as regras e as ferramentas no lugar.

---

## Passo 4 · Conferir se está tudo bem

```bash
./mutirao doctor
```

Ele diz o que falta. Se aparecer ✘ em `git`, instale o Git e repita.

---

## Passo 5 · Conversar com a IA

Abra a sua IA **dentro da pasta do projeto**:

```bash
claude        # ou: codex · gemini · cursor .
```

E cole o pedido inicial (o próprio Mutirão gera ele para você):

```bash
./mutirao start "site de doceria que recebe pedido no WhatsApp"
```

Copie o bloco que aparecer e cole no chat da IA.

---

## Passo 6 · Responder as perguntas

A IA vai fazer até 5 perguntas, sempre com opções. Responda como falaria com
uma pessoa. Ela então escreve a **spec** — um documento dizendo o que vai ser
feito — e pede sua aprovação.

Leia com calma. É o momento mais barato para mudar de ideia.

---

## Passo 7 · Ver o resultado

Quando ela terminar, vai te dizer o que abrir. Normalmente:

```bash
./mutirao vault run -- npm run dev
```

E abrir `http://localhost:3000` no navegador.

Se algo estiver errado, fale com ela em português normal: "o botão está
pequeno no celular", "quero que o texto seja outro". Não precisa saber o nome
técnico de nada.

---

## O que vai acontecer com contas e pagamentos

Em algum momento a IA vai parar e chamar você. São só 4 momentos (veja
`./mutirao gate`):

1. **Criar conta** — você resolve o código do celular e aceita os termos.
2. **Pagar** — você paga no site do serviço. A IA nunca vê seu cartão.
3. **Publicar** — você aprova colocar no ar.
4. **Mexer em chave** — você confirma, e guarda no cofre.

Fora isso, você só conversa.

---

## Se travar

| Situação | O que fazer |
|---|---|
| "command not found" | o programa não está instalado, ou o terminal está na pasta errada. Rode `pwd` (mostra a pasta) e `./mutirao doctor` |
| A IA pediu uma chave no chat | **não mande**. Diga: "guarda no cofre, me diz só o nome" |
| Deu erro no meio | copie o erro e cole no chat da IA — ela entende |
| Perdi o que fiz | `git status` mostra o que mudou; peça para a IA desfazer o último passo |
| Não sei o que a IA fez | peça: "me explica em 3 frases, sem termo técnico" |

Mais: [perguntas-frequentes.md](perguntas-frequentes.md)
