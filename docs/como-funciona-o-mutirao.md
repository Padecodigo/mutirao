# Como funciona o Mutirão

## A ideia em uma frase

Você contrata uma equipe inteira por conversa: um **Maestro** que entende o que
você quer, especialistas que constroem em paralelo, e um **Revisor** que não
deixa passar nada quebrado — com você presente só nas quatro decisões que são
suas por direito.

"Mutirão" é a palavra certa: no mutirão brasileiro, muita gente trabalha junto
numa obra, cada um na sua frente, e a obra fica pronta mais rápido do que se
fosse um só. É exatamente isso.

---

## A equipe

```
                    você
                     │  conversa em português
                     ▼
              ┌─────────────┐
              │   MAESTRO   │  entende · escreve a spec · divide o trabalho
              └──────┬──────┘
                     │  contratos (rotas, campos, telas)
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │FRONTEND │  │ BACKEND │  │  (mais) │   cada um na sua worktree
   └────┬────┘  └────┬────┘  └────┬────┘
        └────────────┼────────────┘
                     ▼
              ┌─────────────┐
              │  REVISOR    │  confere contra a spec · testa · junta
              └──────┬──────┘
                     ▼
                 resultado
```

| Papel | O que faz | Fala com você? |
|---|---|---|
| Maestro | traduz sua ideia em spec, decide a ordem, chama os outros | sim, o tempo todo |
| Frontend | as telas que você vê | não |
| Backend | dados, regras, integrações (pagamento, WhatsApp) | não |
| Revisor | testa tudo e junta o trabalho | só em caso de problema |

---

## Por que "paralelo" não é bagunça

Três pessoas construindo a mesma casa ao mesmo tempo, sem combinar onde vai a
porta, produzem três portas em lugares diferentes. Com agentes é igual.

Por isso o Mutirão exige **contrato antes de paralelo**:

- onde fica cada rota (`/pedidos`, `/contato`);
- como se chama cada campo (`nome`, `telefone`, `itens`);
- o que cada tela recebe e o que dispara.

Com o contrato escrito, cada especialista trabalha isolado — na sua própria
**worktree**, uma cópia do projeto — e o Revisor encaixa as peças no fim.

Sem contrato, o paralelo vira retrabalho. Com contrato, vira velocidade.

---

## As 4 paradas (e por que elas existem)

A IA faz tudo, menos quatro coisas. Não é limitação técnica: é o que mantém o
projeto dela vivo.

| Parada | Por que a IA não faz | O que acontece |
|---|---|---|
| **Conta** | CAPTCHA, SMS e termos de uso proíbem automação | ela abre e preenche; você resolve a verificação |
| **Pagamento** | cartão exige o titular (3DS) e é ato jurídico seu | ela abre o checkout; você paga |
| **Publicar** | é o momento em que o mundo vê | ela testa tudo; você aprova |
| **Chave** | segredo é responsabilidade de quem é dono | ela pede o nome; você guarda no cofre |

Se a IA tentasse fazer isso sozinha, o resultado previsível é: conta banida,
cartão exposto, site quebrado no ar com seu nome, e chave vazada. Em qualquer
um desses casos, o projeto acaba.

---

## Onde ficam as chaves

**Nunca no projeto.** No cofre — 1Password, Bitwarden, Infisical ou Doppler —
e entram no programa na hora de rodar:

```bash
mutirao vault add STRIPE_SECRET_KEY     # declara que o projeto precisa
mutirao vault run -- npm run dev        # injeta sem mostrar
```

O agente de IA sabe o **nome** da chave. Nunca o valor. Assim, mesmo que a IA
faça algo errado, não há o que vazar.

Há ainda uma trava: `mutirao guard install` impede o commit de qualquer arquivo
que pareça conter segredo.

---

## Quanto custa

| Item | Custo |
|---|---|
| Mutirão (este kit) | grátis, MIT |
| Ferramenta de IA | de ~US$ 20/mês (as boas de terminal costumam ser pagas) |
| Hospedagem | grátis em muitos casos (Vercel, Netlify) |
| Domínio próprio | ~R$ 40/ano |
| Serviços (pagamento, banco) | varia; normalmente só taxa por uso |

Aviso honesto: **agentes em paralelo gastam mais** que um agente só — cada um
recomeça lendo o contexto. Use paralelo quando as frentes forem realmente
independentes. Para ajustar um botão, um agente só basta.
