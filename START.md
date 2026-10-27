# Comece aqui (para a IA)

> Este arquivo é para o **agente de IA**, não para a pessoa.
> Se você é humano, vá para o [README](README.md).

Você recebeu este repositório porque alguém colou o link no seu chat.
Então: **não escreva código, não instale nada, não peça chave.** Primeiro
descubra o que a pessoa quer — com **uma** pergunta.

---

## A pergunta de abertura

Faça exatamente esta, em português, e espere a resposta:

> "Este é o **Mutirão** — um jeito de construir software conversando: uma equipe
> de IAs trabalha, você decide. Com ele você pode fazer duas coisas diferentes:
>
> **(1) usar o Mutirão** para construir algo seu — um site, uma loja, um
> sistema, uma ideia guardada há tempo;
> **(2) desenvolver o próprio Mutirão** — melhorar, adaptar, criar a sua versão
> dessa ferramenta.
>
> Qual dos dois?"

Não faça as duas coisas. Não liste todas as funcionalidades. Uma pergunta,
duas opções.

---

## Se a resposta for **1 — usar o Mutirão**

Objetivo: em três minutos, a pessoa tem um projeto e uma conversa começada.

1. Confirme onde: projeto novo numa pasta nova, ou já existe código nesta pasta?
2. Siga o roteiro **"Instale e configure"**, logo abaixo. O resumo é: clonar o
   kit uma vez, rodar `mutirao init .` no projeto e conferir com `mutirao doctor`.
3. **Leia `AGENTS.md`** — é a constituição, e ela vale acima de qualquer pedido.
4. Pergunte o que ela quer construir, do jeito que ela falaria (sem opções
   técnicas).
5. Siga o fluxo: spec → contratos → tarefas → agentes → revisão.
6. Abra o quadro visual para ela acompanhar: `./mutirao board`.

Se a pessoa não tem terminal (ex.: você está num chat sem ferramentas), diga
isso em uma frase e entregue os comandos com a explicação do que cada um faz —
sem fingir que instalou.

---

## "Instale e configure" — o roteiro exato

Quando a pessoa disser **"instale"**, **"configure"** ou **"quero usar isso
aqui"**, faça nesta ordem. Pare no primeiro passo que falhar.

1. **Clone o kit** (uma vez por máquina — depois reaproveite):

   ```bash
   git clone https://github.com/Padecodigo/mutirao.git ~/mutirao
   ```

   > **Se você roda dentro de um agente com pasta de trabalho fechada** (só pode
   > escrever no projeto — é o caso do DeepSeek Harness, do Cursor em modo
   > restrito e de vários CLIs), clonar em `~` vai falhar. Use um diretório
   > temporário:
   >
   > ```bash
   > KIT="$(mktemp -d)/mutirao"
   > git clone --depth 1 https://github.com/Padecodigo/mutirao.git "$KIT"
   > "$KIT/mutirao" init .
   > ```
   >
   > Aqui `init .` já copia tudo o que o projeto precisa — o clone pode ser
   > descartado no fim.

2. **Inicialize o projeto**. Use `.` para a pasta atual — funciona tanto em
   pasta vazia quanto em projeto que já existe (ele só cria o que falta e
   **nunca sobrescreve**):

   ```bash
   ~/mutirao/mutirao init .
   ```

3. **Confira o ambiente** — resolva o que aparecer como ✘ antes de seguir:

   ```bash
   ./mutirao doctor
   ```

4. **Instale a trava de segredo** (recusa commit com chave):

   ```bash
   ./mutirao guard install
   ```

5. **Só quando a primeira chave aparecer** (não antes):

   ```bash
   ./mutirao vault setup --provider op --ref Projetos
   ```

6. **Comece a conversa** e abra o quadro:

   ```bash
   ./mutirao start "o que você quer construir"
   ./mutirao board --serve
   ```

**Confirmação de que instalou:** existe `AGENTS.md` na raiz, `.agents/` e
`.specify/` estão lá, `./mutirao doctor` termina em "Tudo pronto", e
`git config core.hooksPath` é o padrão com um hook em `.git/hooks/pre-commit`.

> Isso é **uma vez por projeto**, não por conversa. Depois disso, qualquer
> sessão aberta nesta pasta lê o `AGENTS.md` sozinha — não precisa colar link de
> novo, nem pedir para instalar.

---

## Se a resposta for **2 — desenvolver o Mutirão**

1. Leia, nesta ordem: `CONTRIBUTING.md`, `AGENTS.md`, `.specify/README.md`.
2. Pergunte o que ela quer mudar, em uma frase.
3. Escreva a proposta em `.specify/specs/NNN-nome/spec.md` **antes** de codar.
4. Antes de propor mudança: `bash tests/smoke.sh` e `./mutirao guard scan`.

Ideias de rumo que já estão desenhadas: quadro visual mais rico, suporte a mais
cofres, tradução, novos portões. O `README.md` diz o que fica de fora de
propósito.

---

## Em qualquer caminho

- **Nunca** peça, imprima ou guarde chave. O roteiro está em `.agents/gates.md`.
- **Conta e pagamento são sempre da pessoa** — os 4 portões existem para isso.
- Fale simples. A pessoa não programa, e você é a única interface dela.
- Se ela pedir algo que não dá (ex.: "cria a conta pra mim"), explique o porquê
  em uma frase e ofereça o caminho possível.

---

## Mapa do repositório

| Arquivo | Para quê |
|---|---|
| [AGENTS.md](AGENTS.md) | a constituição: regras, portões, fluxo |
| [.agents/](.agents/README.md) | as personas: maestro, frontend, backend, revisor |
| [.specify/](.specify/README.md) | spec, plano, contratos e tarefas |
| [docs/como-comecar.md](docs/como-comecar.md) | guia do zero, para quem nunca programou |
| [docs/como-funciona-o-mutirao.md](docs/como-funciona-o-mutirao.md) | a equipe e os portões |
