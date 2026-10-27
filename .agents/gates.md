# Portões — o texto exato de cada parada

> Leia [AGENTS.md](../AGENTS.md) antes. Este arquivo é o roteiro das 4 únicas
> situações em que você, agente, para e chama o humano.

Regra geral dos portões:

- **Uma pergunta por vez.** Nunca empilhe "quer que eu crie a conta, confirme o
  e-mail e aceite os termos?".
- **Diga o que vai acontecer depois.** A pessoa precisa saber o que ganha.
- **Espere resposta explícita.** Silêncio, "ok" solto ou "acho que sim" não
  valem para os portões 2 e 3.
- **Não explique o mecanismo, explique o efeito.**

---

## Portão 1 · Criar conta

**Quando:** a pessoa precisa de uma conta em qualquer serviço (Stripe, Vercel,
Supabase, OpenAI, domínio, e-mail…).

**Fale assim:**

> Para {benefício concreto}, você precisa de uma conta no {serviço}.
> Eu abri a página e preenchi o que dava.
> Falta você: resolver a verificação (código no celular/e-mail) e aceitar os termos.
> São 30 segundos. Quando terminar, me diga "pronto".

**Passos seus:**
1. Abra a página de cadastro.
2. Preencha apenas o que a pessoa já te deu (nome, e-mail). Não invente dados.
3. **Não** tente resolver CAPTCHA. **Não** crie e-mail temporário. **Não** use
   dados falsos.
4. Espere.
5. Confirme: faça login de teste, veja se aparece o painel.

**Como você confirma que passou:** existe sessão ativa / aparece o painel / a
chave foi criada.

**Erros comuns:**
- Tentar automatizar o CAPTCHA → a conta é banida e o projeto morre ali.
- Usar e-mail descartável → a pessoa perde acesso para sempre.
- Criar a conta no nome de outra pessoa → risco jurídico.

---

## Portão 2 · Pagar

**Quando:** qualquer cobrança, plano pago, domínio, crédito de API.

**Fale assim:**

> Para {benefício}, o {serviço} cobra {valor}/{período}.
> Eu abri a página de pagamento. Você paga direto lá — eu não tenho e não quero
> acesso ao seu cartão.
> Quando terminar, me diga "paguei" e eu confirmo.

**Passos seus:**
1. Abra o checkout.
2. Diga valor e período. Se for assinatura, **diga que é assinatura**.
3. Espere.
4. Confirme pelo painel/API que o plano mudou. Não confie no "paguei".

**Nunca:**
- Pedir número de cartão, CVV, validade ou senha do banco.
- Guardar dado de cartão em qualquer lugar, nem no cofre.
- Pagar com cartão da empresa/sua conta.

**Se a pessoa mandar o cartão no chat:** recuse, apague da conversa se possível,
e recomende bloquear/trocar. Isso é sério.

---

## Portão 3 · Publicar

**Quando:** colocar o projeto na internet (Vercel, Netlify, Railway, VPS).

**Antes de falar com ela, você já fez:**
- [ ] `npm run build` passou
- [ ] testes passaram
- [ ] `mutirao guard scan` limpo
- [ ] abriu a app e clicou no caminho principal
- [ ] conferiu no celular

**Fale assim:**

> Está tudo testado: as páginas abrem, o formulário salva, o pedido chega no
> WhatsApp. Podem ver {o que qualquer visitante verá}.
> Se eu publicar, o site fica no ar em {endereço previsto}.
> Posso publicar?

**Só publique com "sim" claro.** Se ela não responder, não publique.

**Depois:** mande o link e a frase "abre no celular e me diz o que quer mudar".

---

## Portão 4 · Mexer em chave ou senha

**Quando:** criar, trocar, revogar ou mover uma chave; conectar um serviço que
usa chave.

**Fale assim:**

> Preciso de uma chave do {serviço} com permissão de {escopo}.
> Você cria em {caminho no painel} e guarda no cofre — não me manda pelo chat.
> Depois me diga só o nome: vou usar como `{NOME_DA_CHAVE}`.
> Se essa chave vazar, o risco é {consequência concreta}.

**Passos seus:**
1. Diga o **nome** da variável que o código espera.
2. Peça a permissão mínima (só leitura, só um recurso).
3. Oriente: `mutirao vault add NOME` e depois guardar o valor no app do cofre.
4. Confirme com `mutirao vault get NOME` (sem `--reveal`).
5. Rode o projeto com `mutirao vault run -- npm run dev`.

**Se a pessoa colar a chave no chat:** pare o trabalho imediatamente, diga:

> Essa chave ficou exposta no histórico do chat. Não vou usá-la.
> Apague/revogue ela no painel do {serviço} e crie outra. Depois guarde no cofre.
> Se essa chave estava em uso, eu troco no código — mas ela precisa ser trocada
> no serviço primeiro.

E registre no relatório final que houve exposição.

---

## Resumo mental

| Portão | Pergunta que você faz | Resposta que libera |
|---|---|---|
| 1 Conta | "Resolva a verificação e me diga pronto" | "pronto" |
| 2 Pagar | "Você paga lá; me diga paguei" | "paguei" |
| 3 Publicar | "Posso publicar?" | "sim"/"pode" |
| 4 Chave | "Crie e guarde no cofre; me diga o nome" | nome + `vault get` ok |
