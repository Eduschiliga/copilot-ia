# Fluxo de trabalho — da spec à implementação

Este pacote cobre o ciclo completo, contract-first, para features Java/Spring Boot. Cada fase é uma skill/agent com responsabilidade única; você aprova entre as fases.

```text
spec-writer  →  (aprovar)  →  spec-to-tasks  →  spec-implementer  →  spec-conformance
                                                   │
                                                   └── por task: task-implementer → task-test-guardian → task-code-reviewer
```

Modelos recomendados: spec, testes, review e auditoria em **Opus**; implementação de código em **Sonnet**.

---

## Passo a passo (implementação do zero)

### 1. Escrever a spec — `spec-writer`
Entrada: um épico `.md`, um pedido funcional, ou só a ideia no prompt.
Exemplo de prompt:
> "Cria uma spec contract-first pra feature de cupom de desconto no checkout. Segue o épico em `docs/epico-cupom.md`."

- Consulta o código só para alinhar contrato e impacto.
- **Não inventa regra**: pergunta diante de lacunas. Se a lacuna for **bloqueante** (regra do caminho feliz/contrato indefinida), ela **para e pergunta** — responda antes de seguir. Lacuna periférica é entregue marcada com `[DEFINIR — pergunta N]`.
- Saída: `spec-<feature>.md` (Resumo, Regras de Negócio RN0x, Contrato da API, Fluxo, Como Testar).

### 2. Revisar e aprovar a spec
Leia as RNs e o contrato; ajuste o que for preciso (refino pela própria `spec-writer`, Modo C). A spec é a **fonte da verdade** de todo o resto — só avance quando ela refletir a regra real.

### 3. Quebrar em tarefas — `spec-to-tasks`
> "Quebra `spec-cupom.md` em tasks."

- Gera `tasks/<feature>/NN-slug.md` (uma por PR, em ordem de dependência) + `00-README.md` com tabela e grafo.
- Confira ordem, tamanho e rastreabilidade (cada RN aparece em alguma task) antes de implementar.

### 4. Implementar uma tarefa por vez — `spec-implementer`
> "Implementa as tasks de `tasks/cupom/`, uma por vez."

Para **cada** task, o orquestrador encadeia:
1. `task-implementer` (Sonnet) — implementa só o escopo da task.
2. `task-test-guardian` (Opus) — escreve e **roda** os testes, caminho feliz **e** triste.
3. `task-code-reviewer` (Opus) — revisa implementação **e** testes; veredito APROVADO / AJUSTES NECESSÁRIOS.

A task só fecha com review APROVADO e testes verdes cobrindo todas as RNs.

### 5. Aprovar entre as tarefas (gate humano)
O orquestrador **para** ao fim de cada task com um resumo (arquivos, review, testes, RNs). Você aprova e ele segue. Se travar, ele **para e escala** com relatório — sem trapacear teste nem inventar regra:
- teto de 3 tentativas no ciclo de testes / 3 ciclos de review;
- `BLOQUEADO` (ex.: regra `[DEFINIR]`, dependência faltando) em qualquer fase;
- conflito com a spec → decisão do usuário.

### 6. Repetir até a fila de tasks zerar

### 7. Auditar no fim — `spec-conformance`
> "A spec `spec-cupom.md` está refletida no código em `src/`?"

Auditoria **somente leitura**: matriz RN↔código↔teste, tabela do contrato e veredito CONFORME / NÃO CONFORME. Pendências (ausente, divergente, sem teste) viram novas tasks — volte ao passo 3/4.

### 8. Git (fora das skills)
Cada task tende a virar um PR pequeno — exatamente o que a quebra visou. Faça branch/commit/PR por task.

---

## Atalhos
- **Tarefa muito pequena:** pule a spec completa — a `spec-writer` faz uma "spec mínima", ou escreva um único `NN-*.md` à mão e chame direto o `task-implementer`.
- **Passo isolado:** cada especialista roda sozinho — ex.: "revisa esse PR" (`task-code-reviewer`), "cobre essa classe com testes" (`task-test-guardian`), "audita a conformidade" (`spec-conformance`).

## Princípios que valem em todas as fases
- Nunca deduzir regra de negócio: perguntar diante de lacunas (bloqueante para; periférica marca `[DEFINIR — pergunta N]`).
- Spec profissional e limpa, sem herança de processo.
- Uma responsabilidade por skill; uma task por vez na implementação.
- Testes cobrem caminho feliz e triste; o review olha código e testes.
