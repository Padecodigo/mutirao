# Tarefas · <nome curto>

> Cada tarefa cabe em uma sessão de agente e tem um jeito objetivo de saber se
> terminou. Máximo ~8 por rodada.

## Como ler

`T1 · <quem> · <o quê> → <como sei que terminou>`

Quem: `maestro` · `frontend` · `backend` · `revisor`

## Como marcar

O quadro visual (`mutirao board`) lê estas marcas. Mantenha atualizado — quadro
desatualizado engana a pessoa.

| Marca | Significado |
|---|---|
| `- [ ]` | a fazer |
| `- [>]` | fazendo agora (o agente marca ao começar) |
| `- [x]` | concluído (só depois do teste da tarefa) |

## Rodada 1

- [ ] **T1** · backend · Criar rota `POST /pedidos` que salva nome, telefone e itens
      → `curl` com dados válidos devolve `201` e o pedido aparece no banco
- [ ] **T2** · frontend · Tela de pedido com nome, telefone e itens + botão enviar
      → preencho, envio e vejo "pedido enviado" (contra a API real)
- [ ] **T3** · frontend · Estado de erro quando a API falha
      → desligo a API, envio, e vejo "não consegui enviar, tente de novo"

## Rodada 2

- [ ] **T4** · backend · Validação: telefone com DDD, mínimo 1 item
- [ ] **T5** · revisor · Testar tudo em 375px + caminho de erro
- [ ] **T6** · maestro · Publicar (Portão 3)

## Bloqueios

| Tarefa | Espera por | Desde |
|---|---|---|
| ... | ... | ... |
