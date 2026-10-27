# Contas e pagamentos (a parte que só você pode fazer)

A IA constrói. Você cria conta e paga. Isso não é preguiça dela: é o único
caminho que não destrói o seu projeto.

---

## Por que a IA não cria conta por você

Todo serviço sério tem três travas contra automação:

1. **CAPTCHA** — aquele quebra-cabeça de "selecione os semáforos". Existe
   exatamente para provar que tem um humano ali.
2. **Verificação** — código por SMS ou e-mail, no seu celular.
3. **Termos de uso** — quase todos proíbem cadastro automatizado ou por
   terceiros. Descumprir dá banimento, e o banimento leva junto o projeto que
   está dentro da conta.

Resultado prático: uma IA que "cria contas" entrega uma conta que dura até a
primeira auditoria. E aí você perde tudo que construiu.

**O que a IA faz em vez disso:** abre a página, preenche nome e e-mail, e te
chama para os 30 segundos que só você pode fazer.

---

## Checklist do dia da conta

Antes de começar, tenha em mãos:

- [ ] O e-mail que você usa de verdade (não um descartável)
- [ ] O celular por perto, para o código de verificação
- [ ] Um gerenciador de senhas (o mesmo do cofre) para guardar a senha
- [ ] Decidir se é conta pessoal ou da empresa

Depois de criar:

- [ ] Ative a verificação em duas etapas (2FA)
- [ ] Guarde a senha no cofre, não no papel nem no WhatsApp
- [ ] Anote o e-mail usado (a IA vai perguntar)

---

## Os serviços que costumam aparecer

| Serviço | Para quê | Custo típico | O que só você faz |
|---|---|---|---|
| **GitHub** | guardar o código | grátis | criar conta, 2FA |
| **Vercel** / Netlify | publicar o site | grátis no começo | login com GitHub |
| **Supabase** / Neon | banco de dados | grátis até certo uso | criar projeto, copiar a chave |
| **Stripe** / Mercado Pago | receber pagamento | % por venda | conta, dados bancários, verificação de identidade |
| **Registro.br** / Namecheap | domínio próprio | ~R$ 40/ano | cadastro com CPF/CNPJ, pagamento |
| **OpenAI** / Anthropic | IA dentro do seu produto | por uso | conta, cartão, limite de gasto |

> **Dica de ouro:** defina um **limite de gasto** em toda conta de API no
> primeiro dia. Sem limite, um bug pode gerar uma fatura de milhares de reais.

---

## Por que pagamento é sempre você

1. **3DS / verificação bancária** — o banco manda código para o seu celular.
   Nenhuma automação passa por isso legalmente.
2. **O cartão é seu** — quem paga responde por aquilo. A IA não tem (nem deve
   ter) acesso ao seu cartão.
3. **Dados de cartão têm regra própria (PCI)** — guardar isso no projeto é um
   passivo que pode custar caro.

**Regra:** a IA abre o checkout, você paga, a IA confere se funcionou.

---

## Checklist do pagamento

- [ ] Entendi **o que** estou comprando e **quanto** custa
- [ ] Sei se é **cobrança única** ou **assinatura mensal**
- [ ] Coloquei **limite de gasto**, quando o serviço permite
- [ ] Confirmei que o e-mail da conta é o certo
- [ ] Depois de pagar, avisei a IA ("paguei") para ela confirmar
- [ ] Guardei o recibo no e-mail

---

## Sinais de alerta

Pare e desconfie se:

- A IA pedir seu cartão, CVV ou senha do banco → **nunca**. Recuse.
- Alguém pedir para você pagar por fora do site oficial → golpe.
- O preço for "muito melhor que o oficial" → provavelmente é.
- Pedirem para instalar algo "para liberar o pagamento" → não.
- Você colou uma chave no chat sem querer → apague a chave no painel do serviço
  e crie outra. Veja [seguranca-e-cofre.md](seguranca-e-cofre.md).

---

## Quanto custa começar (estimativa honesta)

| Cenário | Custo inicial |
|---|---|
| Página de apresentação publicada | R$ 0 (Vercel grátis) + domínio opcional |
| Site com formulário e WhatsApp | R$ 0 a R$ 50/mês |
| Loja com pagamento | R$ 0 de mensalidade + ~3–5% por venda |
| Ferramenta de IA para construir | ~US$ 20/mês |

O Mutirão em si é gratuito. O que custa é a IA que trabalha e os serviços que o
seu projeto usa.
