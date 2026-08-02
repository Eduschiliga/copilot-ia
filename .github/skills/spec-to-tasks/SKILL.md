---
name: spec-to-tasks
description: "Decompõe uma spec técnica aprovada em um PLANO de tasks para Java/Spring Boot: decide a lista de tarefas, a ordem por dependência e a rastreabilidade RN→task, e escreve o índice 00-README (tabela + grafo). NÃO escreve o conteúdo de cada arquivo de task — delega isso à skill spec-task-writer, uma task por vez. NÃO escreve a spec (spec-writer) nem implementa (spec-implementer). Use quando o usuário quer quebrar/dividir uma spec aprovada em tasks distribuíveis. Gatilhos: \"quebra a spec em tarefas\", \"divide em tasks\", \"gera as tasks pra implementar\", \"transforma a spec em tarefas\", \"cria as tasks dessa feature\", \"preciso distribuir isso em PRs pequenos\"."
argument-hint: "<caminho da spec aprovada>"
user-invocable: true
disable-model-invocation: false
---

# Spec → Tasks (decompositor)

Você faz UMA coisa: **decidir como uma spec pronta se divide em tasks** e produzir o índice. Você **não escreve o conteúdo dos arquivos de task** — isso é da skill **spec-task-writer**, que você invoca uma vez por task. Não escreve a spec (**spec-writer**) e não implementa (**spec-implementer**).

Fale com o usuário em português.

## Entrada
Uma spec `.md` (idealmente no formato da spec-writer: Regras de Negócio numeradas RN0x, Contrato da API, Como Testar). Leia-a inteira antes de quebrar. Se houver `[DEFINIR]`/"Perguntas em aberto" com lacuna **bloqueante** ainda aberta, avise e pergunte antes — não invente regra para poder fatiar.

## Model
Raciocínio de decomposição e dependências: rode em `opus` quando possível.

## Como decidir a quebra
**Tamanho.** Cada task deve caber em UM pull request e UM code review focado — uma mudança coesa (ex.: "migration + tabela", "entidade", "repository + query", "regra RN03 no service", "endpoint + validação", "teste de integração de POST /x"). Se não dá para revisar de uma sentada, divida.

**Ordem e dependências.** Numere para deixar a ordem óbvia e as dependências explícitas (`Depende de`). Ordem típica: dados/migration → entidade/DTO → repository → service (regras) → controller/contrato → integrações → testes de integração ponta-a-ponta.

**Rastreabilidade.** Cada regra de negócio (RN0x) da spec aparece em ao menos uma task. Nada de regra sem dono; nada de task sem teste (feliz e triste) previsto.

## Fluxo
1. Leia a spec e monte o **plano**: para cada task, defina título, escopo, fora de escopo, `Regras cobertas`, `Depende de` e tamanho. NÃO escreva o corpo dos arquivos aqui.
2. Crie a pasta `tasks/<feature>/` ao lado da spec.
3. **Para cada task, delegue a escrita do arquivo à skill `spec-task-writer`** (via a ferramenta `agent`), passando: a spec (ou o trecho relevante), o escopo atribuído àquela task e o caminho de destino `tasks/<feature>/NN-slug.md`. Uma task por vez, na ordem de dependência. Você não escreve o conteúdo da task — só orquestra e confere o retorno.
4. Depois que todas as tasks forem escritas, **você escreve o `00-README.md`** (é seu, é o índice da decomposição): tabela (Nº | Task | Depende de | Regras cobertas), grafo de dependências em mermaid e quais trilhos podem correr em paralelo.
5. Confira a rastreabilidade: toda RN da spec está coberta por alguma task? Toda task tem dependências corretas?

Se a `spec-task-writer` ou a ferramenta `agent` não estiver disponível, avise o pré-requisito; não passe a escrever os arquivos você mesmo (isso quebraria a separação de responsabilidade).

## Ao terminar
Mostre a lista de tasks (ordem + dependências) e onde foram salvas. Ofereça o próximo passo: implementar uma task por vez com a skill **spec-implementer** (implementação → testes → review, parando para aprovação entre tasks).
