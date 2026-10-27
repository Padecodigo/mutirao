# Contrato · Telas

> Regra: o frontend nunca calcula dinheiro para cobrar — só para exibir. O
> servidor é quem manda no total.

---

## Tela `Cardapio` (`/`)

| Recebe | De onde |
|---|---|
| lista de produtos | `GET /api/produtos` |

Mostra: nome da doceria, uma frase de apresentação, grade de produtos (foto,
nome, preço, botão "adicionar").

Estados:
- carregando: esqueleto com 3 blocos
- erro: "não consegui carregar o cardápio. Tente de novo." + botão
- vazio: "cardápio sendo atualizado, volte em breve"

---

## Componente `Carrinho` (barra fixa no rodapé)

| Recebe | Tipo |
|---|---|
| `itens` | lista de `{ produto, quantidade }` |
| `totalCentavos` | inteiro |
| `onMudarQuantidade` | função `(produtoId, novaQtd)` |
| `onIrParaEntrega` | função |

Regras: some quando vazio. Mostra "N itens · R$ X". O botão só habilita com
total ≥ R$ 30.

---

## Tela `Entrega` (`/entrega`)

Campos: nome, telefone, bairro (select), endereço.
Validação no cliente (aviso imediato) **e** no servidor (verdade).

Estados de envio: `ocioso` → `enviando` → `erro` | `sucesso`.

Ao dar certo: abre o WhatsApp com `whatsapp_url` e mostra "pedido enviado".

---

## Tela `Pedidos da Ana` (`/admin`)

Pede o `ADMIN_TOKEN` uma vez e guarda só na memória da aba (nunca em `localStorage`
nem no código). Lista os pedidos com data, cliente, itens e total.

Estados: carregando, vazio ("nenhum pedido ainda"), erro, não autorizado
("token inválido").

---

## Regras duras

- Nenhuma chave no bundle do navegador. `ADMIN_TOKEN` chega ao servidor por
  variável de ambiente.
- Todo botão que dispara rede mostra estado de carregamento e evita clique duplo.
- Textos em português, sem emoji no meio do preço.
- Funciona em 375px de largura, com uma mão.
