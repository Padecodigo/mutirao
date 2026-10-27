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

**Ações** (é um painel de gestão: as cinco são obrigatórias)

| Ação | Como aparece | O que acontece |
|---|---|---|
| abrir | clique no pedido | detalhe com itens e endereço |
| editar | botão "Marcar como entregue" | `PATCH /api/pedidos/{id}` |
| excluir um | botão "Excluir" | modal "Apagar o pedido de **Maria**?" · confirma · some da lista · aviso "pedido apagado · desfazer" por 5s (`DELETE .../{id}` e `POST .../restaurar`) |
| limpar todos | botão "Limpar lista" | modal com campo para digitar `APAGAR` + link "baixar CSV antes" · `DELETE /api/pedidos` · tela vazia |

Estados: carregando, vazio ("nenhum pedido ainda · os pedidos aparecem aqui
assim que um cliente enviar"), erro, não autorizado ("token inválido").

Detalhes de segurança da tela:

- O botão de excluir fica separado dos outros e em cor de alerta — nunca ao lado
  do "marcar como entregue".
- Enquanto apaga, o botão fica desabilitado (evita clique duplo).
- Se a rede falhar, o pedido **volta** para a lista e aparece "não consegui
  apagar, tente de novo" — a tela nunca mente sobre o que aconteceu.

---

## Regras duras

- Nenhuma chave no bundle do navegador. `ADMIN_TOKEN` chega ao servidor por
  variável de ambiente.
- Todo botão que dispara rede mostra estado de carregamento e evita clique duplo.
- Textos em português, sem emoji no meio do preço.
- Funciona em 375px de largura, com uma mão.
