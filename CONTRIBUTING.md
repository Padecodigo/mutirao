# Contribuir

O Mutirão é pequeno de propósito: arquivos de instrução e scripts simples.
Contribuição boa é contribuição que **reduz o número de coisas que podem dar
errado para quem não programa**.

## Antes de tudo

```bash
git clone https://github.com/Padecodigo/mutirao.git
cd mutirao
bash tests/smoke.sh
```

Tudo verde? Você está pronto.

## O que é bem-vindo

| Tipo | Exemplo |
|---|---|
| Clareza | um trecho de doc que ainda assume conhecimento técnico |
| Novo cofre | suporte a outro gerenciador (KeePassXC, HashiCorp Vault) |
| Novo portão | um quinto momento em que a IA deveria parar — **discuta antes** |
| Correção de bug | script que quebra em macOS ou Windows/Git Bash |
| Exemplo | um `examples/` completo de outro tipo de projeto |
| Tradução | inglês e espanhol da pasta `docs/` |

## O que provavelmente não entra

- Automação de criação de conta, CAPTCHA ou pagamento. É a linha do projeto.
- Dependência que exija Node/Python para o núcleo funcionar.
- Abstração "para o futuro". O kit é para hoje e para leigos.
- Instrução que ensine a IA a ler `.env` "só para checar".

## Como mandar

1. Abra uma issue descrevendo o problema **do ponto de vista de quem não programa**.
2. Faça um branch: `git checkout -b assunto-curto`.
3. Mantenha o commit pequeno, mensagem em português simples.
4. Rode `bash tests/smoke.sh` e `./mutirao guard scan`.
5. Abra o PR explicando: o que muda para a pessoa, e como você testou.

## Estilo

- Markdown em português, frases curtas, sem jargão.
- Bash com `set -euo pipefail`, `shellcheck` limpo, sem dependência nova.
- Texto de interface (o que o usuário lê) sempre em português.
- Uma ideia por arquivo. Se ficou grande, provavelmente são duas.

## Testes

`tests/smoke.sh` cobre: sintaxe dos scripts, CLI, detecção de segredo, worktree,
cofre e init. Se você mexeu em qualquer um deles, adicione um caso.

## Código de conduta

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Em resumo: seja decente. O público
aqui é gente que está começando.
