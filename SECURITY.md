# Segurança

## O que este projeto é

Um conjunto de arquivos de instrução (Markdown) e scripts de apoio (bash) que
você roda na sua própria máquina. **Não há servidor, telemetria, coleta de
dados ou conta.** Nada sai do seu computador por causa do Mutirão.

## O que ele faz com os seus segredos

Nada. O `tools/vault.sh` não armazena chaves: ele as repassa do cofre (1Password,
Bitwarden, Infisical, Doppler) para a memória do processo que você mandou rodar.
O repositório guarda apenas **nomes** de chaves em `.mutirao/secrets.list`
(que também não é versionado).

Exceção explícita: o provedor `env`, documentado como **apenas para estudo**,
grava em `.mutirao/vault.env`, que está no `.gitignore`. Não use em projeto real.

## Relatando uma vulnerabilidade

Não abra issue pública para falha de segurança.

- Preferencial: aba **Security → Report a vulnerability** no GitHub.
- Alternativa: abra uma issue pedindo contato privado, sem detalhes técnicos.

Inclua: o que acontece, como reproduzir, e o impacto. Você recebe resposta em
até 7 dias. Se confirmado, a correção sai antes da divulgação pública, e você é
creditado se quiser.

## Escopo

Dentro do escopo:

- `tools/guard.sh` deixar passar um segredo óbvio
- `tools/vault.sh` imprimir valor sem `--reveal`
- injeção de comando via nome de agente/chave em `worktree.sh` ou `vault.sh`
- instruções no `AGENTS.md` que induzam um agente a fazer algo inseguro

Fora do escopo: má configuração do seu cofre, chaves vazadas por você, e
comportamento de ferramentas de terceiros.

## Para quem usa o kit

As regras de segurança do uso estão em [docs/seguranca-e-cofre.md](docs/seguranca-e-cofre.md)
e nas "Regras inegociáveis de segurança" do [AGENTS.md](AGENTS.md).
