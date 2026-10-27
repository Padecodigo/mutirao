# Segurança e cofre

## A regra que resolve 90% dos problemas

> **Chave nunca entra no projeto. Só o nome dela entra.**

```
        você                    projeto                    código
   ┌──────────┐            ┌──────────────┐          ┌──────────────┐
   │  COFRE   │            │ secrets.list │          │ process.env  │
   │ (1Passw.)│            │ STRIPE_KEY   │          │ STRIPE_KEY   │
   └────┬─────┘            └──────┬───────┘          └──────┬───────┘
        │  valor                 │  só o nome               │  valor em memória
        └──────── mutirao vault run -- npm run dev ─────────┘
                   (nunca aparece na tela, nunca no git)
```

---

## Por que isso importa mais do que parece

Um agente de IA tem três furos possíveis:

1. **Ele imprime.** Pede para "ver a configuração", lê o `.env` e cola no chat.
   Aquilo fica no histórico para sempre.
2. **Ele commita.** Faz `git add .` e o `.env` vai junto para o GitHub.
3. **Ele é enganado.** Um texto malicioso no projeto (um comentário, uma
   dependência) pode instruir a IA a mandar a chave para fora. Isso tem nome:
   **prompt injection**.

Nenhum desses furos existe se a chave nunca estiver no disco do projeto.

---

## Configurar o cofre (uma vez por projeto)

### 1Password (recomendado)

```bash
# 1. crie o cofre no app do 1Password: ex. "Projetos"
# 2. instale a CLI e entre na conta
op signin

# 3. diga ao Mutirão para usar esse cofre
mutirao vault setup --provider op --ref Projetos

# 4. declare o que o projeto precisa
mutirao vault add STRIPE_SECRET_KEY
mutirao vault add WHATSAPP_TOKEN

# 5. crie no app: item tipo "Senha", título = STRIPE_SECRET_KEY,
#    campo "senha" = o valor

# 6. confira
mutirao vault doctor
mutirao vault list
```

No dia a dia:

```bash
mutirao vault run -- npm run dev
```

### Bitwarden Secrets Manager

```bash
bws --version
mutirao vault setup --provider bws
mutirao vault add MINHA_CHAVE
```

O valor é lido do cofre online; o nome do segredo precisa ser igual ao nome
declarado.

### Infisical

```bash
infisical login
mutirao vault setup --provider infisical
mutirao vault set STRIPE_SECRET_KEY      # ele pergunta o valor sem mostrar
```

### Doppler

```bash
doppler login
mutirao vault setup --provider doppler
mutirao vault set STRIPE_SECRET_KEY
```

### Modo estudo (`env`)

Guarda em `.mutirao/vault.env` (texto puro, fora do git). Serve para aprender.

```bash
mutirao vault setup --provider env
mutirao vault set MINHA_CHAVE
```

**Não use em projeto de verdade.** Se o computador for invadido, está tudo lá.

---

## A trava do commit

```bash
mutirao guard install     # uma vez
mutirao guard scan        # quando quiser
```

A partir daí, qualquer commit com cara de segredo é **recusado**. Se a trava
barrar:

1. **Não** desabilite a trava.
2. Apague o valor do arquivo.
3. Guarde no cofre (`mutirao vault set`).
4. Declare (`mutirao vault add NOME`).
5. Rode de novo.

O que ela procura: chaves privadas, AWS, GitHub, OpenAI, Anthropic, Stripe,
Google, Slack, JWT, `.env`, `.pem`, `.key`, e atribuições suspeitas do tipo
`password = "..."`. Veja tudo com `mutirao guard rules`.

---

## O que a IA pode e não pode

| Pode | Não pode |
|---|---|
| saber o **nome** da chave | ler o valor |
| rodar `mutirao vault run -- ...` | ler `.env` ou `vault.env` |
| pedir para você criar/trocar | imprimir, logar, repetir |
| ver `vault list` (✔/✘) | commitar segredo |

Isso está escrito em [AGENTS.md](../AGENTS.md), seção 4. Um agente que desobedece
essas regras não está seguindo o Mutirão.

---

## Vazou. E agora?

Ordem importa. **Primeiro revogar, depois limpar.**

1. **Revogue/crie outra** no painel do serviço. A chave antiga morre em segundos.
2. Troque no cofre (`mutirao vault set`).
3. Se foi commitada: remova do git e **considere o histórico comprometido**
   (a chave já foi copiada — por isso o passo 1 vem primeiro).
4. Se foi colada no chat: aquela conversa fica no histórico da ferramenta.
   Trate a chave como pública.
5. Verifique uso indevido: faturas, logs de acesso, cobranças.

Lição: **rotação é mais rápida que arrependimento.**

---

## Higiene mínima

- [ ] 2FA em todas as contas que importam
- [ ] Senha única por serviço (gerador do cofre)
- [ ] `mutirao guard install` em todo projeto
- [ ] Limite de gasto nas APIs
- [ ] Nunca colar chave no chat, no WhatsApp, no issue, no print
- [ ] Revisar quem tem acesso ao repositório e ao cofre
