# Constituição do projeto · <nome do projeto>

> Princípios que valem para **todas** as decisões deste projeto. Muda pouco,
> mas quando mudar, mude aqui primeiro.
> O Maestro lê este arquivo antes de planejar qualquer coisa.

## 1. Para quem é isto

<Uma pessoa que não programa. Ela julga pela tela. Se ela se perder, o projeto
falhou — mesmo que o código esteja correto.>

## 2. Simplicidade vence

A opção mais simples que resolve o problema. Cada peça a mais (serviço, banco,
biblioteca) é uma peça a mais para quebrar quando ela estiver sozinha.
Se der para resolver com uma página e um formulário, não construa um sistema.

## 3. Dinheiro é sagrado

- Nenhum dado de cartão passa por este projeto.
- Cobrança só por provedor reconhecido, com confirmação por webhook no servidor.
- Valor em centavos inteiros.
- Toda cobrança tem recibo e histórico visível para a pessoa.

## 4. Chave nunca aparece

- Chave vive no cofre, entra por variável de ambiente, morre com o processo.
- Nada de chave em código, log, mensagem de erro ou front-end.
- Vazou? Troca no serviço na hora — antes de qualquer outra coisa.

## 5. Português claro

Textos da interface, mensagens de erro e commits em português. Sem jargão na
frente de quem não programa.

## 6. Nada some

A pessoa nunca perde trabalho: backup antes de mudança grande, histórico no git,
e todo passo destrutivo pede confirmação.

## 7. Testado ou não entregue

"Não testei" é resposta aceitável. "Deve funcionar" não é entrega.

## 8. O que este projeto não é

- Não é um produto para programadores.
- Não é uma demonstração técnica.
- Não é infinito: o escopo de cada versão está escrito na spec.
