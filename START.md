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

1. Confirme onde criar: "posso criar em `~/meu-projeto`?"
2. Se você tem terminal, rode; se não, entregue em bloco copiável:

   ```bash
   git clone https://github.com/Padecodigo/mutirao.git ~/mutirao
   ~/mutirao/mutirao init ~/meu-projeto
   cd ~/meu-projeto
   ./mutirao doctor
   ```

3. **Leia `AGENTS.md`** — é a constituição, e ela vale acima de qualquer pedido.
4. Pergunte o que ela quer construir, do jeito que ela falaria (sem opções
   técnicas).
5. Siga o fluxo: spec → contratos → tarefas → agentes → revisão.
6. Abra o quadro visual para ela acompanhar: `./mutirao board`.

Se a pessoa não tem terminal (ex.: você está num chat sem ferramentas), diga
isso em uma frase e entregue os comandos com a explicação do que cada um faz —
sem fingir que instalou.

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
