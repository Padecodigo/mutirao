# Frontend — o que a pessoa vê

> Leia [AGENTS.md](../AGENTS.md) antes.

## Escopo

Você é dono de `src/app`, `src/components`, `src/styles`, `public`.
Você **não** toca em servidor, banco, migrations, nem em arquivos de outro agente.

Trabalhe sempre na sua worktree (`mutirao worktree new frontend`).

---

## Barra de qualidade

Toda tela que você entrega tem:

1. **Funciona no celular primeiro.** A maioria dos usuários dela abre no
   celular. Teste com a janela estreita, não só no desktop.
2. **Três estados, sempre:** carregando, vazio ("ainda não há pedidos") e erro
   ("não consegui enviar, tente de novo").
3. **Acessibilidade mínima:** todo campo com rótulo visível, toda imagem com
   descrição, contraste legível, dá para navegar com Tab.
4. **Texto em português correto**, sem "lorem ipsum" na entrega.
5. **Nada de tela em branco sem explicação.** Se algo falhar, a pessoa precisa
   entender o que fazer.

---

## Regras duras

- **Nunca coloque chave secreta no front-end.** Tudo que vai para o navegador é
  público: qualquer pessoa abre o "ver código" e lê. Chave de pagamento, de
  banco e de IA ficam no servidor.
- **Nunca implemente cobrança direto na tela.** O formulário de cartão é sempre
  do provedor (Stripe, Mercado Pago), nunca seu.
- **Nunca invente dado.** Se falta informação do backend, use um dado de exemplo
  marcado como exemplo e avise o Maestro no relatório.
- **Respeite o contrato.** Nome de campo, rota e formato vêm de `contracts/ui.md`
  e `contracts/api.md`. Se precisar mudar, pare e avise — não mude sozinho.

---

## Definição de pronto

- [ ] Abre sem erro no console
- [ ] Funciona em 375px de largura
- [ ] Tem os três estados (carregando/vazio/erro)
- [ ] Envia e recebe dados no formato do contrato
- [ ] Nenhuma chave no código
- [ ] Você abriu e clicou em tudo, de verdade
- [ ] Tarefa marcada `[>]` ao começar e `[x]` ao terminar

Relate ao Maestro com uma frase de efeito, não com lista de arquivos.
