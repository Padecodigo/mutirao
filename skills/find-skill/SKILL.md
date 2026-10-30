---
name: find-skill
description: Busca e instala novas capacidades a partir de registros públicos quando o repositório não possuir uma skill necessária.
license: MIT
---

<!-- PROPÓSITO: skill de descoberta. Ensina o agente a procurar uma capacidade
     ausente em registros públicos e a instalá-la via skillshare CLI, em vez de
     inventar código ou pacote. Se não achar, deve reportar a ausência. -->

# find-skill

Use esta skill quando o repositório **não tiver** a capacidade necessária para a tarefa
e existir a tentação de "improvisar" uma solução.

## Regra central

> **Não invente.** Se a capacidade não estiver no repositório nem em um registro
> público verificável, o resultado correto é **reportar a ausência** — nunca gerar
> um pacote, comando ou API que você não conseguiu confirmar.

## Passo a passo

1. **Procurar no repositório primeiro.** Verifique `skills/` (veja `skills/README.md`)
   e as instruções do `AGENTS.md`.
2. **Procurar nos registros públicos** (os dois canônicos, verificados):
   - `VoltAgent/awesome-agent-skills` — https://github.com/VoltAgent/awesome-agent-skills
   - `ComposioHQ/awesome-claude-skills` — https://github.com/ComposioHQ/awesome-claude-skills
   - alternativas: `travisvn/awesome-claude-skills`, `heilcheng/awesome-agent-skills`
3. **Selecionar um candidato** e checar reputação/atividade do repositório antes de instalar.
4. **Instalar com a CLI `skillshare`** (https://github.com/runkids/skillshare):
   ```bash
   # formato: github.com/<owner>/<repo>/skills  (caminho da pasta de skills)
   skillshare install github.com/<owner>/<repo>/skills
   skillshare audit            # revisa o que foi instalado antes de usar
   skillshare sync             # distribui para as ferramentas de IA configuradas
   ```
5. **Verificar o resultado**: a skill apareceu em `skills/` (ou no local que o
   `skillshare sync` indicar) e o `SKILL.md` tem `name` + `description` válidos.
6. **Registrar**: se a skill passar a ser dependência do projeto, anote no
   `AGENTS.md` ou na spec em andamento — não deixe a instalação invisível.

## Exemplo prático de uso

Situação: o projeto precisa gerar diagramas de arquitetura e não há skill para isso.

```text
Agente:  Vou procurar uma skill de diagramas nos registros públicos.
         1) grep em skills/ → nada.
         2) VoltAgent/awesome-agent-skills → "diagram-maker" (owner/repo).
         3) skillshare install github.com/owner/repo/skills
         4) skillshare audit → 0 alertas.
         5) skillshare sync → disponível no harness.
Resposta ao usuário: "Instalei a skill diagram-maker a partir do registro
          público X. Ela desenha diagramas a partir de texto."
```

## Exemplo de tratamento de falha

Situação: nenhum registro tem a capacidade pedida, ou a instalação falha.

```text
Agente:  Procurei em skills/ e nos registros públicos (VoltAgent, ComposioHQ).
         Não encontrei uma skill para "conectar ao ERP legado via SOAP".
         Não vou inventar essa integração.

Resposta ao usuário: "Não existe skill pública verificável para isso. As opções são:
         (a) você me indica o repositório/skill correto;
         (b) eu escrevo a integração do zero como tarefa de spec, com contrato e testes."
```

Falhas comuns e o que fazer:

| Falha | Ação |
|---|---|
| `skillshare: command not found` | Instalar: `curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh \| sh` (ou `brew install skillshare`) |
| Registro online fora do ar | Tentar o outro registro; se ambos falharem, reportar e sugerir caminho offline |
| Skill instala mas `audit` acusa risco | **Não usar**; reportar o alerta ao usuário e propor alternativa |
| Skill exige chave/credencial | Parar — Portão 4 do `AGENTS.md`: pedir autorização e nunca imprimir o valor |

## Não faça

- ❌ Instalar pacote de origem desconhecida sem `skillshare audit`.
- ❌ Escrever no `SKILL.md` uma URL ou comando que você não abriu/verificou.
- ❌ Dizer "instalei" sem conferir que a skill existe no diretório após o sync.
