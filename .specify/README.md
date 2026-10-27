# `.specify/` — onde o trabalho é pensado antes de ser escrito

A ideia central: **é mais barato corrigir uma frase do que corrigir um sistema.**
Aqui ficam as decisões em português, antes de virarem código.

```
.specify/
├── memory/
│   └── constitution.md      ← princípios deste projeto (muda pouco)
├── templates/               ← modelos em branco
│   ├── spec.md
│   ├── plan.md
│   └── tasks.md
└── specs/
    └── 001-nome-curto/      ← uma pasta por funcionalidade
        ├── spec.md          ← O QUE e POR QUÊ
        ├── plan.md          ← COMO (tecnologia, riscos)
        ├── tasks.md         ← QUEM faz o quê, em que ordem
        └── contracts/
            ├── api.md       ← rotas e formatos
            ├── ui.md        ← telas e dados que recebem
            └── dados.md     ← entidades e campos
```

## Regras

1. **Uma pasta por funcionalidade**, numerada: `001-doceria`, `002-pagamento`.
   Nome curto, sem espaço, sem acento.
2. **Spec antes de código.** Se a spec não convence, o código não vai convencer.
3. **Contrato antes de paralelo.** Sem contrato, dois agentes produzem dois
   sistemas diferentes.
4. **A spec é a verdade.** Código que contradiz a spec está errado — ou a spec
   precisa mudar, e aí a mudança é explícita.
5. **Escreva para uma pessoa**, não para uma máquina. Se sua avó não entende o
   "o que faz", reescreva.

## Ordem do fluxo

```
constitution (uma vez)  →  spec  →  plan  →  contracts  →  tasks  →  código
```

Pule o `plan.md` em projeto pequeno. Nunca pule `contracts/` se houver mais de
um agente trabalhando.
