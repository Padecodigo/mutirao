# Contrato · API

Base: `/api`. Formato: JSON. Erros sempre `{ "erro": "codigo", "mensagem": "texto em pt-BR" }`.

---

## `GET /api/produtos`

Lista os produtos disponíveis.

**200**
```json
{
  "produtos": [
    { "id": "bolo-cenoura", "nome": "Bolo de cenoura", "descricao": "cobertura de chocolate",
      "preco_centavos": 4500, "foto_url": "/fotos/cenoura.jpg", "disponivel": true }
  ]
}
```

---

## `GET /api/entrega/bairros`

**200**
```json
{ "bairros": [ { "nome": "Centro", "taxa_centavos": 800 } ] }
```

---

## `POST /api/pedidos`

**Entrada**
```json
{
  "nome_cliente": "Ana",
  "telefone": "11987654321",
  "bairro": "Centro",
  "endereco": "Rua das Flores, 123",
  "itens": [ { "produto_id": "bolo-cenoura", "quantidade": 1 } ]
}
```

**201**
```json
{
  "pedido": { "id": 12, "total_centavos": 4500, "status": "novo" },
  "whatsapp_url": "https://wa.me/5511999998888?text=..."
}
```

**Erros**

| Status | `erro` | Quando |
|---|---|---|
| 400 | `dados_invalidos` | campo faltando ou tipo errado |
| 400 | `pedido_minimo` | total < 3000 (sem a taxa) |
| 400 | `produto_indisponivel` | produto não existe ou `disponivel:false` |
| 400 | `bairro_nao_atendido` | bairro fora da lista |
| 500 | `erro_interno` | falha ao salvar |

Regra: `total_centavos` é calculado **no servidor**. Se o cliente mandar total,
é ignorado.

---

## `GET /api/pedidos?limite=20`

Página da Ana. Exige header `x-admin-token` com o valor da variável
`ADMIN_TOKEN` (nunca no código; vem do cofre).

**200**
```json
{ "pedidos": [ { "id": 12, "criado_em": "2026-10-27T14:02:00-03:00",
                 "nome_cliente": "Ana", "total_centavos": 4500,
                 "status": "novo", "itens": [ { "nome": "Bolo de cenoura", "quantidade": 1 } ] } ] }
```

**401** `{ "erro": "nao_autorizado" }` sem header válido.
