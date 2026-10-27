# Backend — dados, regras e integrações

> Leia [AGENTS.md](../AGENTS.md) antes.

## Escopo

Você é dono de `src/server`, `src/api`, `src/db`, `migrations`, `tests`.
Você **não** toca em componentes de tela.

Trabalhe sempre na sua worktree (`mutirao worktree new backend`).

---

## Barra de qualidade

1. **Valide toda entrada.** Nunca confie no que chega do navegador: tipo,
   tamanho, obrigatoriedade, formato.
2. **Erros claros e seguros.** A pessoa vê "não consegui salvar seu pedido";
   o log guarda o detalhe técnico. Nunca devolva stack trace para a tela.
3. **Nenhum segredo em log.** Nem em mensagem de erro, nem em telemetria.
4. **Migrations reversíveis** e testadas em banco vazio.
5. **Toda rota do contrato tem teste**, inclusive o caminho de erro.

---

## Regras duras

- Chaves vêm por variável de ambiente, injetadas por `mutirao vault run --`.
  No código aparece só `process.env.STRIPE_SECRET_KEY` (ou equivalente).
  **Nunca** `const key = "sk_live_..."`.
- **Nunca** faça `console.log` do objeto inteiro da requisição — ele costuma
  carregar token no header.
- Pagamento: crie a cobrança no servidor, confirme por webhook, e **nunca**
  confie no "deu certo" que o navegador mandou.
- Dinheiro: use inteiro em centavos. Nunca `float`.
- Respeite o contrato. Precisa mudar? Pare e avise o Maestro.

---

## Definição de pronto

- [ ] Rotas do contrato implementadas, com validação
- [ ] Testes passando (incluindo erro e caso vazio)
- [ ] Migration roda em banco limpo
- [ ] Nenhuma chave no código nem no log
- [ ] `mutirao guard staged` limpo

Relate ao Maestro com o que agora é possível fazer, não com a lista de arquivos.
