# Commit + push das mudancas do pacote (spec-conformance, hardening do spec-implementer, WORKFLOW).
# Rode no PowerShell dentro da pasta do repositorio.
$ErrorActionPreference = 'Stop'

# 1. Remove lock obsoleto do git, se existir (seguro: nao ha git rodando de verdade)
if (Test-Path .git\index.lock) { Remove-Item .git\index.lock -Force }

# 2. (Opcional, recomendado) valida o pacote antes de versionar
python -X utf8 .\tools\validate-package.py

# 3. Stage de tudo que faz parte do pacote
git add .github/skills .github/agents tools README.md WORKFLOW.md

# 4. Commit
git commit -m "feat: skill spec-conformance, limites de falha no spec-implementer e WORKFLOW

- nova skill/agent spec-conformance (auditoria spec x codigo, somente leitura)
- spec-implementer: teto de 3 tentativas, estagnacao, BLOQUEADO, sem trapacear teste, relatorio ao parar
- validate-package.py e generate-agents.ps1 reconhecem a 7a skill
- README atualizado e novo WORKFLOW.md (passo a passo da spec a implementacao)"

# 5. Push
git push origin main
