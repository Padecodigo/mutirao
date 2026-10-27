# Exemplo · Doceria da Ana

Um exemplo completo de como o Mutirão trabalha, do zero até a entrega. Serve
para você ver **o formato** antes de fazer o seu.

O pedido original foi:

> "Quero um site para a minha doceria que recebe pedido pelo WhatsApp."

Repare no que o Maestro fez antes de escrever qualquer código:

```
spec.md              o que a pessoa quer, em português, sem tecnologia
contracts/dados.md   as entidades e os campos
contracts/api.md     as rotas, entradas e saídas
contracts/ui.md      as telas e o que cada uma recebe
tasks.md             quem faz o quê, em que ordem, e como saber se terminou
```

Só depois disso o trabalho foi dividido entre frontend e backend — e por isso os
dois lados encaixaram na primeira tentativa.

## Arquivos

- [spec.md](spec.md) — o combinado com a dona da doceria
- [contracts/dados.md](contracts/dados.md) — o que fica guardado
- [contracts/api.md](contracts/api.md) — as rotas
- [contracts/ui.md](contracts/ui.md) — as telas
- [tasks.md](tasks.md) — o plano de execução

## O que este exemplo ensina

1. **A spec fala de gente, não de código.** "A Ana vê o pedido chegar no
   WhatsApp" — não "integração com a API do WhatsApp Business".
2. **O contrato é o que permite paralelo.** Com `POST /pedidos` definido (campos,
   resposta, erros), o frontend e o backend puderam ser feitos ao mesmo tempo.
3. **O "não faz" é tão importante quanto o "faz".** Sem ele, a Ana esperaria
   receber pagamento online na primeira versão.
4. **Cada tarefa tem uma prova.** "Abre no celular e o botão aparece" é prova.
   "Implementar componente responsivo" não é.
