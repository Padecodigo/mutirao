# Tarefas · Doceria da Ana v1

> Regra: cada tarefa tem prova objetiva e cabe em uma sessão.

## Rodada 1 — o caminho principal

- [ ] **T1** · backend · Modelo `Produto` + seed com 6 bolos
      → `GET /api/produtos` devolve 6 itens com preço em centavos
- [ ] **T2** · backend · `POST /api/pedidos` calculando total no servidor
      → pedido válido devolve `201` com `total_centavos` correto; total abaixo de R$ 30 devolve `pedido_minimo`
- [ ] **T3** · frontend · Tela `Cardapio` lendo `GET /api/produtos`
      → abro em 375px e vejo 6 produtos com foto, nome e preço
- [ ] **T4** · frontend · `Carrinho` com quantidade e total
      → adiciono 2 itens e o total bate com a conta na mão

## Rodada 2 — fechar o pedido

- [ ] **T5** · backend · `GET /api/entrega/bairros` + validação de bairro
      → bairro fora da lista devolve `bairro_nao_atendido`
- [ ] **T6** · frontend · Tela `Entrega` com validação e envio
      → preencho, envio, e o WhatsApp abre com a mensagem completa
- [ ] **T7** · backend · `whatsapp_url` montada no servidor com os itens
      → a mensagem contém itens, quantidades, endereço e total

## Rodada 3 — a Ana precisa ver

- [ ] **T8** · backend · `GET /api/pedidos` protegido por `ADMIN_TOKEN`
      → sem header devolve `401`; com header devolve os pedidos
- [ ] **T9** · frontend · Tela `/admin` com lista e estados
      → pedido de teste aparece; token errado mostra "token inválido"

## Rodada 4 — a Ana gerencia a lista

- [ ] **T10** · backend · `DELETE /api/pedidos/{id}` (arquiva) e `POST .../restaurar`
      → apagar some da lista padrão; restaurar traz de volta com o status anterior
- [ ] **T11** · backend · `DELETE /api/pedidos` exigindo `confirmar: "APAGAR"`
      → sem a palavra devolve `confirmacao_invalida`; com a palavra, a lista fica vazia
- [ ] **T12** · frontend · botões excluir e limpar, com modal, desfazer e estado vazio
      → apago e vejo "desfazer" por 5s; limpar só funciona digitando APAGAR

## Rodada 5 — entrega

- [ ] **T13** · revisor · Testar caminho feliz + erro em 375px e desktop
- [ ] **T14** · revisor · `mutirao guard scan` limpo, build passando
- [ ] **T15** · maestro · Mostrar para a Ana e publicar (Portão 3)

## Bloqueios

| Tarefa | Espera por | Desde |
|---|---|---|
| T7 | telefone definitivo da Ana para o `wa.me` | início |
