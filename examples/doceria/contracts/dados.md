# Contrato · Dados

> Tudo em **centavos inteiros**. Nunca ponto flutuante para dinheiro.

## Produto

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `id` | texto (slug) | sim | ex.: `bolo-cenoura` |
| `nome` | texto (até 60) | sim | |
| `descricao` | texto (até 140) | não | |
| `preco_centavos` | inteiro | sim | > 0 |
| `foto_url` | texto | não | caminho local ou URL |
| `disponivel` | booleano | sim | padrão `true` |

## ItemPedido

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `produto_id` | texto | sim | precisa existir e estar disponível |
| `quantidade` | inteiro | sim | 1 a 20 |

## Pedido

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `id` | inteiro | gerado | sequencial |
| `criado_em` | data/hora ISO | gerado | fuso America/Sao_Paulo |
| `nome_cliente` | texto (até 80) | sim | |
| `telefone` | texto | sim | 10 ou 11 dígitos, com DDD |
| `bairro` | texto | sim | um dos bairros atendidos |
| `endereco` | texto (até 160) | sim | rua e número |
| `itens` | lista de ItemPedido | sim | mínimo 1 |
| `total_centavos` | inteiro | calculado no servidor | nunca confiar no cliente |
| `status` | texto | gerado | `novo` · `confirmado` · `entregue` · `apagado` |
| `apagado_em` | data/hora ISO | opcional | quando a Ana arquivou o pedido |

## Bairro atendido

| Campo | Tipo |
|---|---|
| `nome` | texto |
| `taxa_centavos` | inteiro |

Bairros da v1: Centro (800), Jardim América (800), Vila Nova (1200).

## Regras de consistência

- `total_centavos` = soma de `preco_centavos × quantidade` + taxa do bairro.
- Pedido abaixo de R$ 30,00 é recusado com `pedido_minimo`.
- Produto indisponível é recusado com `produto_indisponivel`.
- O servidor **recalcula** o total; o valor enviado pelo cliente é ignorado.
- **Apagar é arquivar:** `DELETE` marca `apagado_em` e o pedido sai da lista
  padrão. Não some do banco — dá para restaurar por 30 dias.
- Depois de 30 dias arquivado, o pedido é apagado de verdade por uma rotina
  diária. A Ana é avisada uma vez, na tela de pedidos.
