# Contrato · Telas

> Uma seção por tela. Se a tela permite **gerenciar** algo (pedidos, clientes,
> produtos, mensagens), ela precisa das cinco ações e das três proteções do
> checklist no fim — senão não está pronta.

---

## Tela `Nome` (`/rota`)

| Recebe | De onde |
|---|---|
| <o que a tela mostra> | `GET /api/...` |

**Mostra:** <o que a pessoa vê, em uma frase>

**Estados**
- carregando: <o que aparece>
- vazio: <mensagem + como criar o primeiro item>
- erro: <mensagem + o que fazer>

### Ações

> Só para telas de gestão. Para tela de leitura, apague esta seção.

| Ação | Como aparece | O que acontece |
|---|---|---|
| listar | lista com busca/filtro | — |
| abrir | clique no item | detalhe em modal ou página |
| editar | botão "Editar" | formulário preenchido |
| excluir um | botão "Excluir" | confirmação **com o nome** + desfazer |
| limpar todos | botão "Limpar lista" | digitar `APAGAR` + oferecer exportar |

---

## Componente `Nome`

| Recebe | Tipo |
|---|---|
| `...` | ... |

**Regras:** <comportamento não óbvio>

---

## Checklist de painel de gestão

Copie para a spec da funcionalidade e marque de verdade:

- [ ] **listar** — a pessoa vê o que existe
- [ ] **abrir** — a pessoa vê o que tem dentro
- [ ] **editar** — a pessoa corrige sem apagar
- [ ] **excluir um** — com confirmação citando o item ("Apagar o pedido de Maria?")
- [ ] **limpar todos** — com palavra de confirmação digitada
- [ ] **desfazer** — 5 segundos para voltar atrás, ou lixeira
- [ ] **aviso do que foi apagado** — "Pedido apagado." nunca silêncio
- [ ] **estado vazio que ensina** — "nenhum pedido ainda · como criar o primeiro"
- [ ] **funciona no celular, com uma mão**

Se o dado é dinheiro, histórico ou cliente, o padrão é **arquivar** (marcar como
apagado) e não apagar de verdade. Exclusão real só a pedido, com aviso.

---

## Regras duras

- Nenhuma chave secreta no navegador.
- Todo botão que dispara rede mostra carregamento e evita clique duplo.
- Textos em português, sem jargão, sem emoji no meio de valor.
- Funciona em 375px de largura.
- Ação destrutiva nunca fica ao lado de ação comum sem separação visual.
