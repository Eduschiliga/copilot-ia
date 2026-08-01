# Conversão e avaliação — GitHub Copilot

Data: 2026-08-01

## Entrega

O pacote contém duas representações complementares exigidas pelo GitHub Copilot:

- seis Agent Skills em `.github/skills/<nome>/SKILL.md`;
- seis custom agents autocontidos em `.github/agents/<nome>.agent.md`.

As versões Codex originais permaneceram inalteradas.

## Estrutura

```text
.github/
├── skills/
│   ├── spec-writer/SKILL.md
│   ├── spec-to-tasks/SKILL.md
│   ├── spec-implementer/SKILL.md
│   ├── task-implementer/SKILL.md
│   ├── task-test-guardian/SKILL.md
│   └── task-code-reviewer/SKILL.md
└── agents/
    ├── spec-writer.agent.md
    ├── spec-to-tasks.agent.md
    ├── spec-implementer.agent.md
    ├── task-implementer.agent.md
    ├── task-test-guardian.agent.md
    └── task-code-reviewer.agent.md
```

Os agentes são gerados por `tools/generate-agents.ps1` a partir das skills. Cada agente inclui o corpo integral da skill correspondente, evitando depender de includes que não são uniformes entre VS Code, Copilot CLI e cloud agent.

## Adaptações realizadas

- `agents/openai.yaml` não foi copiado porque é específico do Codex.
- `display_name`, descrições e prompts foram convertidos para frontmatter e handoffs dos custom agents.
- As Agent Skills receberam `argument-hint`, `user-invocable` e `disable-model-invocation` conforme o formato Copilot.
- `allowed-tools` foi omitido nas skills para não pré-aprovar shell ou outras operações.
- Os custom agents receberam tool scopes explícitos; após a auditoria final, o revisor perdeu acesso ao shell.
- Modelos e `target` foram omitidos para portabilidade entre planos e superfícies.
- Os handoffs usam `send: false` e existem somente entre as macroetapas `spec-writer → spec-to-tasks → spec-implementer`.
- Especialistas não possuem handoffs diretos: o `spec-implementer` continua sendo o único dono do loop.
- O orquestrador deixou de usar `spawn_agent`, `fork_turns`, `followup_task`, modelos `gpt-5.6-*` e paths de skills do Codex.
- A delegação agora usa o alias oficial `agent`, com nova invocação nomeada para cada fase ou correção.

## Tool scopes

| Custom agent | Tools |
|---|---|
| `spec-writer` | `read`, `search`, `edit` |
| `spec-to-tasks` | `read`, `search`, `edit` |
| `spec-implementer` | `read`, `search`, `execute`, `agent` |
| `task-implementer` | `read`, `search`, `edit`, `execute` |
| `task-test-guardian` | `read`, `search`, `edit`, `execute` |
| `task-code-reviewer` | `read`, `search` |

O orquestrador não possui `edit`; o revisor não possui `edit`, `execute` nem `agent`. Somente o orquestrador possui `agent`, impedindo delegação pelos especialistas no nível de ferramentas. O alias `execute` do orquestrador continua amplo e deve ser usado somente para inspeções não mutantes de status/diff.

## Validação estática

`tools/validate-package.py` analisou os 12 artefatos com parsing YAML e aprovou:

- nomes, limites e campos de frontmatter;
- paridade de `description` e `argument-hint` entre skill e agent;
- seis diretórios e seis IDs esperados;
- tool scopes e ownership;
- conteúdo exato, targets e `send: false` dos handoffs;
- corpo autocontido dos agents idêntico ao corpo das skills;
- limite de 30.000 caracteres dos agents;
- UTF-8 e ausência de mojibake;
- ausência de resíduos específicos do Codex.

Resultado: **6/6 skills e 6/6 custom agents aprovados**.

## Avaliação de roteamento

Dois classificadores independentes receberam apenas o frontmatter:

- classificador de Agent Skills: 30/30;
- classificador de custom agents: 30/30.

A matriz continha 18 casos positivos, 6 casos de fronteira e 6 casos negativos. Resultado agregado: **60/60 classificações corretas**.

## Forward-test do orquestrador

O `spec-implementer` convertido foi executado contra uma spec com duas tasks. O ciclo concluiu apenas a Task 01:

1. implementação restrita a `CalculadoraDesconto.java`;
2. guardião restrito a `CalculadoraDescontoTest.java`;
3. review somente leitura com `VEREDITO: APROVADO`;
4. nenhuma antecipação de RN03, endpoint, DTO ou Task 02;
5. parada no gate de aprovação antes da Task 02.

Resultados:

- testes focais: 10/10;
- testes unitários: 114/114;
- testes de integração: 31/31;
- `mvn verify`: 145 testes, zero falhas;
- `git diff --check`: sucesso.

O harness local atingiu o limite global de nós depois da fase de implementação. Para concluir a prova, o guardião reutilizou um agente concluído com contexto, perfil e ownership redefinidos; o review foi executado em leitura pelo agente raiz seguindo o custom agent convertido. Essa limitação pertence ao harness Codex e não ao formato do GitHub Copilot.

## Instalação pessoal

Os arquivos foram instalados nos caminhos oficiais:

- `C:\Users\eschi\.copilot\skills\<nome>\SKILL.md`;
- `C:\Users\eschi\.copilot\agents\<nome>.agent.md`.

No momento da conversão, a comparação SHA-256 confirmou paridade em **12/12 arquivos** entre o pacote inicial e a instalação pessoal. O repositório foi posteriormente endurecido para remover o shell do revisor; a instalação pessoal não foi sobrescrita automaticamente. Use `install-personal.ps1 -Force` para sincronizá-la, com backup prévio automático.

## Endurecimento do repositório

Antes do commit inicial, uma auditoria adicional introduziu estes controles sem alterar o roteamento dos papéis:

- reviewer com `read` e `search`, sem shell;
- validador cobrindo nome de exibição, descrição, argument hint e handoffs exatos;
- gerador compatível com Windows PowerShell 5.1 quando executado via `-File`;
- instalador respeitando `COPILOT_HOME`, com backup e substituição limpa em `-Force`;
- Actions fixadas por SHA e PyYAML fixado em versão exata;
- documentação das diferenças entre superfícies e da amplitude do alias `execute`.

## Limitação da validação local

Os executáveis `copilot` e `gh` não estão instalados nesta máquina. Portanto, não foi possível executar descoberta real no Copilot CLI nem `gh skill publish --dry-run`. O pacote foi validado por schema, por roteamento independente e por forward-test do workflow. Após instalar ou abrir o Copilot, reinicie a CLI ou recarregue a IDE para descobrir os novos agentes.

## Referências oficiais

- [Adding agent skills for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [Creating custom agents for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)
- [Copilot CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference)
- [Custom agents and subagents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents)
- [Subagents in VS Code](https://code.visualstudio.com/docs/agents/subagents)
