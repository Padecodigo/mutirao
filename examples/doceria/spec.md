# Spec · Doceria da Ana

## Em uma frase

Uma página da Doceria da Ana onde o cliente monta o pedido e ele chega
organizado no WhatsApp dela, sem ela precisar copiar mensagem.

## Quem usa

**Cliente** — chega pelo Instagram, abre no celular, quer pedir rápido e saber
quanto custa. Não vai criar conta.

**Ana (dona)** — recebe o pedido no WhatsApp, já com itens, quantidade, endereço
e total. Confere e responde confirmando.

## O que a pessoa consegue fazer

### H1 · Ver o cardápio

- **Como** cliente, **quero** ver os bolos disponíveis com preço, **para** decidir
  o que pedir sem perguntar.
- **Como sei que funcionou:** abro a página e vejo foto, nome e preço de cada bolo.
- **Prioridade:** essencial

### H2 · Montar o pedido

- **Como** cliente, **quero** escolher itens e quantidades, **para** saber o total
  antes de enviar.
- **Como sei que funcionou:** escolho 2 itens, o total muda na hora, e aparece
  "3 itens · R$ 87,00".
- **Prioridade:** essencial

### H3 · Enviar pelo WhatsApp

- **Como** cliente, **quero** mandar o pedido num clique, **para** não digitar tudo.
- **Como sei que funcionou:** toco no botão, o WhatsApp abre com a mensagem já
  escrita ("Pedido: 1 bolo de cenoura, 2 brigadeiros — total R$ 87,00 — entrega
  na Rua X, 123").
- **Prioridade:** essencial

### H4 · Ana vê os pedidos numa lista

- **Como** Ana, **quero** uma página simples com os últimos pedidos, **para**
  conferir quando o WhatsApp falhar ou o cliente esquecer de enviar.
- **Como sei que funcionou:** faço um pedido de teste e ele aparece na lista em
  menos de 1 minuto, com data e hora.
- **Prioridade:** importante

### H5 · Ana apaga um pedido e limpa a lista

- **Como** Ana, **quero** apagar um pedido errado e limpar os pedidos de teste,
  **para** a lista mostrar só o que é de verdade.
- **Como sei que funcionou:** toco em "excluir" num pedido e ele pergunta
  "Apagar o pedido de Maria?"; confirmo, o pedido some e aparece "pedido
  apagado · desfazer" por 5 segundos. Em "limpar lista", preciso digitar
  `APAGAR` antes; depois a lista mostra "nenhum pedido ainda".
- **Prioridade:** essencial

## O que NÃO faz (nesta versão)

- Não recebe pagamento online (a Ana combina Pix pelo WhatsApp)
- Não tem login de cliente
- Não calcula frete por distância (taxa fixa por bairro, escrita na página)
- Não tem painel de estoque
- Não envia e-mail nem SMS

## Regras do negócio

- Pedido mínimo: R$ 30,00
- Entrega só nos bairros: Centro, Jardim América, Vila Nova — taxa R$ 8,00
- Encomendas para o dia seguinte precisam ser feitas até 18h
- Bolo inteiro exige 24h de antecedência (aviso na tela)

## Conteúdo e identidade

- Nome: Doceria da Ana
- Cores: rosa queimado (#B5654A) e creme (#FBF6F0)
- Textos prontos: não — usar exemplo e a Ana troca depois
- Fotos: sim, 6 fotos enviadas por ela

## Pronto quando

- [ ] A cliente monta e envia um pedido no celular sem ajuda
- [ ] A Ana recebe a mensagem completa no WhatsApp
- [ ] O total nunca erra
- [ ] A Ana apaga um pedido, se arrepende e desfaz — sem ajuda
- [ ] A página abre em menos de 3 segundos no 4G

## Perguntas em aberto

| Pergunta | Quem responde | Prazo |
|---|---|---|
| A taxa de entrega é por bairro ou fixa? | Ana | antes de começar |
| Precisa de aviso de "fora do horário"? | Ana | depois da v1 |
