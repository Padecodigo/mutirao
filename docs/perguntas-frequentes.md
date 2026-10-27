# Perguntas frequentes

### Preciso saber programar?
Não. O Mutirão existe para quem não sabe. Você precisa saber dizer o que quer e
responder perguntas simples. Ler o que aparece na tela ajuda, mas não é
obrigatório — a IA é instruída a explicar em português comum.

### Qual IA eu uso?
Qualquer uma que consiga ler arquivos e rodar comandos na sua pasta: Claude
Code, Codex, Gemini CLI, Cursor, Copilot no modo agente. O Mutirão não é preso a
nenhuma — as regras estão em `AGENTS.md`, que todas leem.

### Isso é de graça?
O kit é grátis e aberto (MIT). A IA que trabalha costuma ser paga (a maioria
tem plano de ~US$ 20/mês). Hospedagem e domínio variam.

### A IA vai criar minhas contas e pagar?
Não. E isso é de propósito. Contas exigem CAPTCHA, SMS e aceite de termos —
automatizar dá banimento. Pagamento exige o titular do cartão. A IA faz todo o
resto e te chama só nesses momentos (veja `./mutirao gate`).

### Por que a IA não pode só "ver" minha chave uma vez?
Porque o que aparece no chat fica no histórico. E o que fica no histórico é
lido por qualquer pessoa com acesso àquela conta, para sempre. Por isso a chave
entra no programa por variável de ambiente, sem passar pela tela.

### Onde ficam minhas senhas?
No cofre que você escolher (1Password, Bitwarden, Infisical, Doppler). O projeto
só guarda os **nomes** das chaves, nunca os valores.

### E se eu não tiver cofre?
Tem um modo de estudo que guarda num arquivo local fora do git
(`mutirao vault setup --provider env`). Serve para aprender, não para projeto
real.

### Dois agentes ao mesmo tempo não vão se atrapalhar?
Não, se usarem `mutirao worktree new <nome>`: cada um trabalha numa cópia
separada, com a sua branch. O que evita retrabalho é o contrato escrito antes.

### Quanto custa rodar 3 agentes em paralelo?
Mais ou menos 2 a 4 vezes o custo de um agente só — cada um relê o contexto.
Use paralelo quando as frentes forem de fato independentes (telas × servidor).
Para ajuste pequeno, um agente basta.

### Ele funciona no meu computador fraco?
Sim. O trabalho pesado acontece nos servidores da IA. Você precisa de internet
e de um navegador.

### Funciona no Windows?
Sim. Use o PowerShell. O Git para Windows já traz os programas necessários. O
kit é escrito em bash, que vem junto com o Git.

### E se a IA fizer besteira?
Cada tarefa termina com commit — dá para voltar. O Revisor confere antes de
juntar. E nada destrutivo acontece sem confirmação. Se algo der errado, peça:
"volta para o último commit que funcionava".

### Preciso publicar? Posso só usar no meu computador?
Pode. Publicar (`Portão 3`) é opcional. Muita coisa útil roda local.

### Como sei que o projeto é meu?
O código fica na sua máquina e no seu repositório. O cofre é seu. Nada passa
pelos servidores do Mutirão — ele é só um conjunto de arquivos e regras.

### Posso usar em projeto de cliente?
Sim. A licença MIT permite. Só lembre: contas e pagamentos do cliente são dele.

### O Mutirão substitui aprender a programar?
Não. Ele substitui a **necessidade** de aprender para conseguir o resultado.
Se um dia você quiser aprender, o projeto que ele construiu é um bom lugar
para começar a ler.
