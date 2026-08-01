# Instruções do repositório para o GitHub Copilot

- Responda em português do Brasil, salvo quando o solicitante pedir outro idioma.
- Em trabalho Java/Spring Boot orientado por spec, use o papel mais específico disponível em `.github/skills` ou `.github/agents`.
- Não invente regras de negócio ausentes. Registre lacunas bloqueantes e peça a decisão necessária.
- Preserve alterações preexistentes e mantenha o trabalho restrito ao escopo solicitado.
- Trate `.github/skills/*/SKILL.md` como fonte de verdade.
- Não edite manualmente `.github/agents/*.agent.md`; após alterar uma skill, execute `tools/generate-agents.ps1`.
- Mantenha as separações de responsabilidade: implementação de produção, testes e code review são etapas distintas.
- O `task-code-reviewer` não recebe shell nem ferramentas de edição; ele deve revisar os arquivos e as evidências de teste existentes.
- O `spec-implementer` pode usar `execute` somente para inspeções não mutantes, como `git status` e `git diff`; toda edição pertence aos especialistas.
- No fluxo completo, processe uma task por vez e preserve o gate de aprovação humana entre tasks.
- Antes de concluir uma alteração neste pacote, execute `tools/validate-package.py` e relate qualquer limitação ambiental.
