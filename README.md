# copilot-ia

Repositório central das configurações de GitHub Copilot usadas no fluxo contract-first para projetos Java/Spring Boot.

O pacote contém nove Agent Skills e nove custom agents equivalentes. As skills são a fonte de verdade; os agents são gerados a partir delas para oferecer seleção explícita de persona no GitHub Copilot.

## Estrutura

```text
copilot-ia/
├── .github/
│   ├── agents/                  # Custom agents gerados
│   ├── skills/                  # Agent Skills (fonte de verdade)
│   ├── workflows/validate.yml   # Validação contínua do pacote
│   └── copilot-instructions.md  # Instruções no escopo do repositório
├── tools/
│   ├── generate-agents.ps1      # Regenera agents a partir das skills
│   └── validate-package.py      # Valida estrutura, escopos e paridade
├── EVAL-RESULTS.md              # Evidências do eval das skills
├── WORKFLOW.md                  # Passo a passo da spec à implementação
└── install-personal.ps1         # Instala/atualiza em ~/.copilot
```

O passo a passo completo (da spec à implementação, com prompts de exemplo e os gates humanos) está em [WORKFLOW.md](WORKFLOW.md).

## Papéis disponíveis

| Skill/agent | Responsabilidade |
|---|---|
| `spec-writer` | Criar ou refinar uma spec técnica contract-first |
| `spec-to-tasks` | Decidir a decomposição de uma spec em tasks (plano + README), delegando a escrita |
| `spec-task-writer` | Escrever um arquivo de task a partir da spec e do escopo atribuído |
| `spec-implementer` | Orquestrar implementação, testes e review task por task |
| `task-implementer` | Implementar somente o código de produção de uma task |
| `task-test-guardian` | Criar/corrigir testes e validar cenários felizes e tristes |
| `task-code-reviewer` | Revisar uma task de modo somente leitura |
| `spec-conformance` | Auditar, somente leitura, se a spec está refletida no código |
| `quick-task-writer` | Transformar uma demanda pequena (feature/fix) em task pronta, sem spec |

## Usar no escopo de um projeto

Este repositório já está no layout reconhecido pelo GitHub Copilot. Para reutilizar a configuração em outro repositório, copie estas entradas para a pasta `.github` desse projeto:

- `skills/`
- `agents/`
- `copilot-instructions.md`, caso as instruções gerais também devam ser aplicadas

## Instalar no escopo pessoal

No PowerShell, execute:

```powershell
.\install-personal.ps1
```

Se já houver versões instaladas e você quiser atualizá-las conscientemente:

```powershell
.\install-personal.ps1 -Force
```

Com `-Force`, o instalador cria primeiro um backup em `<destino>\.backup\<data-id>` e substitui integralmente cada uma das nove skills, evitando arquivos obsoletos. Ele não remove outras skills ou agents pessoais.

Por padrão, o destino respeita `COPILOT_HOME`; quando a variável não existe, usa `%USERPROFILE%\.copilot`. Para usar outro local:

```powershell
.\install-personal.ps1 -DestinationRoot 'D:\config\copilot'
```

## Manutenção

Edite primeiro o `SKILL.md` correspondente e depois regenere os custom agents:

```powershell
.\tools\generate-agents.ps1
```

Valide o pacote antes de versionar:

```powershell
python -m pip install "PyYAML==6.0.2"
python -X utf8 .\tools\validate-package.py
```

O workflow `.github/workflows/validate.yml` repete esses controles no GitHub e falha se um agent gerado estiver desatualizado. Actions e dependências Python estão fixadas em versões imutáveis/reprodutíveis.

## Compatibilidade e permissões

- O corpo completo de cada papel está presente tanto na skill quanto no custom agent.
- `argument-hint` e `handoffs` dependem da superfície do Copilot; no cloud agent do GitHub.com esses campos podem ser ignorados, mas o comportamento principal continua descrito no corpo do agent.
- O `task-code-reviewer` recebe apenas `read` e `search`, tornando o custom agent tecnicamente sem edição ou shell.
- O `spec-implementer` mantém `execute` para inspecionar estado e diff do Git. Como esse alias representa acesso amplo ao shell, a proibição de editar diretamente também é uma regra comportamental; as alterações devem ser delegadas aos especialistas.

## Qualidade

O relatório [EVAL-RESULTS.md](EVAL-RESULTS.md) registra a avaliação estrutural, de roteamento e integrada das nove skills e dos nove agents.
