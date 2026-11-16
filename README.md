# Design Docs de Webhooks de Notificação de Pedidos (OMS)

Enunciado original: [desafio.md](desafio.md)

## Sobre o desafio

A tarefa foi transformar a transcrição de uma reunião técnica (`TRANSCRICAO.md`) em um pacote de design docs para o Sistema de Webhooks de Notificação de Pedidos do OMS: um PRD, um RFC, um FDD, entre 5 e 8 ADRs e um Tracker de rastreabilidade, tudo em `docs/`. Cada informação precisa ter origem na transcrição ou no código existente, o que a reunião descartou ou adiou não pode virar requisito e nenhum arquivo de código citado pode ser inexistente.

Além dos documentos, o desafio pede que este README descreva o processo de produção com IA: ferramentas, workflow, prompts, iterações e como navegar a entrega. Por isso, o foco aqui é a jornada, e não o enunciado.

## Ferramentas de IA utilizadas

- Claude Code (Sonnet 5.5, modelo da sessão): orquestrador. Dispara os agentes, roda o gate mecânico e consolida os relatos. Não redige os documentos.
- Haiku 5.5 em subagente: `investigador-codigo`, extração mecânica de fatos do código para `docs/auxiliar/contexto-codigo.md`.
- Sonnet 5.5 em subagentes: `redator-prd`, `redator-adrs`, gerador do Tracker e `redator-readme` (este README).
- Opus 5.5 em subagentes: `redator-rfc`, `redator-fdd` e o revisor independente.

Os arquivos de `.claude/agents` não foram reconhecidos como `subagent_type` na sessão. Os agentes foram executados via `general-purpose`, com o parâmetro de modelo e a instrução de seguir o arquivo do agente (plano B do runbook).

## Workflow adotado

A estratégia completa está em `docs/auxiliar/estrategia-execucao.md`. Em resumo: multiagente com contexto isolado, em que cada agente recebe só o próprio prompt e as entradas listadas, e o único acoplamento entre eles é `docs/auxiliar/contrato-compartilhado.md` (IDs, nomes dos ADRs, marcadores, fronteiras entre documentos). Um script sem modelo (`docs/auxiliar/validar-entrega.sh`) verifica estrutura e contagens do desafio, e cada agente o roda no seu modo antes de reportar. Todo agente encerra com um bloco `RELATO`; só o orquestrador consolida.

Ordem lógica do pacote: PRD, RFC, FDD, ADRs, Tracker, com README e revisão ao final. Ondas de execução:

| Onda | Conteúdo | Execução |
|---|---|---|
| 0 | `investigador-codigo` gera o contexto do código | sequencial |
| 1 | PRD, RFC, FDD e ADRs | 4 agentes em paralelo |
| gate | `validar-entrega.sh wave1` | script |
| 2 | Tracker e README | 2 agentes em paralelo |
| gate | `validar-entrega.sh full` | script |
| 3 | revisor independente | 1 agente |

| Agente | Modelo | Saída |
|---|---|---|
| investigador-codigo | Haiku 5.5 | `docs/auxiliar/contexto-codigo.md` |
| redator-prd | Sonnet 5.5 | `docs/PRD.md` |
| redator-rfc | Opus 5.5 | `docs/RFC.md` |
| redator-fdd | Opus 5.5 | `docs/FDD.md` |
| redator-adrs | Sonnet 5.5 | `docs/adrs/ADR-001` a `ADR-006` |
| gerador-tracker | Sonnet 5.5 | `docs/TRACKER.md` |
| redator-readme | Sonnet 5.5 | `README.md` |
| revisor-independente | Opus 5.5 | relatório de revisão |

No momento da escrita deste README, o log do processo registra as ondas 0 e 1 e o gate da onda 1. Os resultados do Tracker, do revisor e da revisão humana não constam do log e, portanto, não são descritos aqui.

## Prompts customizados

Os prompts foram reescritos antes da execução para trazer os requisitos e os critérios de aceite literais do desafio e a autoverificação por script. Cada um é um arquivo em `.claude/agents/`. Abaixo, trechos fiéis de dois deles.

### redator-prd: persona, escopo e instruções negativas

```markdown
## 1. Persona e escopo
Você é um(a) Product Manager técnico(a) sênior que escreve PRDs de feature: fala de problema, valor, público e escopo, não de solução. Escreve apenas `docs/PRD.md`, sem nada além do que o desafio pede para o PRD.

## 2. Objetivo
Produzir o PRD do Sistema de Webhooks de Notificação de Pedidos (apenas saída/outbound, notificação de mudança de status de pedido), rastreável à transcrição e ao código, atendendo literalmente à seção 3 abaixo.

## 9. Instruções negativas
- Não adicionar seções, anexos, documentos ou requisitos além dos exigidos; não alterar nada fora de `docs/PRD.md`.
- Não transformar DESCARTADO, ADIADO ou QUESTÃO ABERTA em requisito.
- Não inventar métricas, SLAs, prazos, equipes ou números.
- Não citar caminho de arquivo que não existe; código novo só por nome lógico (contrato seção 2).
- Não copiar trechos longos da transcrição. Sem travessão longo, sem emojis, sem prosa em inglês.
- Não alterar `src/`, `prisma/`, `tests/`, `TRANSCRICAO.md`, `desafio.md`, `README.md`.

## 10. Tratamento de erro e relato
Faça `Read` do stub atual de `docs/PRD.md` antes de sobrescrever. Se uma fonte obrigatória faltar, escreva o possível e retorne FALHA ou OK_COM_RESSALVAS. Encerre com o bloco `## RELATO redator-prd` (seção 10 do contrato), com CHECKLIST_DESAFIO e AUTOVERIFICACAO preenchidos.
```

### redator-adrs: persona, objetivo e instruções negativas

```markdown
## 1. Persona e escopo
Você é um(a) arquiteto(a) que mantém o acervo de ADRs. Cada ADR registra UMA decisão já tomada, com contexto, alternativas e consequências. Não é RFC (não delibera) nem FDD (não detalha implementação). Escreve apenas os 6 arquivos de ADR.

## 2. Objetivo
Criar os 6 ADRs do mapa do contrato (um por decisão principal), com nomes idênticos, atendendo literalmente à seção 3.

## 8. Ambiguidades e pressupostos
Quando o racional de negócio não estiver na fonte, escreva `[NEEDS INPUT: pergunta]` (e DUVIDAS) em vez de inventar. Alternativa que só é plausível: `[PLAUSÍVEL, não discutida na reunião]` (e PRESSUPOSTOS). Conflito fatos x transcrição: seguir a transcrição e relatar.

## 9. Instruções negativas
- Não criar ADR extra, renomear arquivos do contrato nem unir decisões.
- Não registrar como decisão o que foi adiado, descartado ou está em aberto.
- Não colar trechos longos de código ou da transcrição; não detalhar implementação (isso é do FDD).
- Não citar caminho de arquivo inexistente; código novo por nome lógico.
- Sem travessão longo, sem emojis, sem prosa em inglês.
- Escrever somente nos 6 arquivos `docs/adrs/ADR-00N-*.md`.
```

## Iterações e ajustes

Segundo o log, houve 1 ciclo principal de geração (onda 1: PRD, RFC, FDD e 6 ADRs, cada um com autoverificação em 1 ciclo e 0 falhas, sem re-execução). A revisão humana pode acrescentar mais ciclos. Os ajustes e problemas reais registrados:

1. Reescrita dos prompts antes da execução. Os prompts iniciais foram corrigidos para trazer requisitos e critérios de aceite literais do desafio e autoverificação por script. Foram removidos itens além do que o desafio pede (ADR-007, mínimos maiores que o pedido, "SEM ORIGEM" no Tracker, diagrama obrigatório no RFC). Também se decidiu citar código novo por nome lógico, para cumprir o critério "nenhum arquivo mencionado é inexistente".
2. Agentes não reconhecidos. Os arquivos de `.claude/agents` não foram reconhecidos como `subagent_type` (o `investigador-codigo` já acusou isso na onda 0). A correção foi usar `general-purpose` com o parâmetro `model` e a instrução de seguir o arquivo do agente.
3. Falha de escrita do `redator-adrs`. A primeira escrita por heredoc no Bash falhou por erro de sintaxe e nada foi gravado. O próprio agente refez a escrita com a ferramenta Write.
4. Conflitos entre `fatos-reuniao.md` e a transcrição, detectados pelos agentes: o worker "compartilha o pool" (a transcrição diz `PrismaClient` próprio, [09:30] Bruno); o HMAC atribuído a [09:20] (o RFC usou [09:22] Sofia); UUID em [09:50] x [09:51]; `customer_id` em [09:32]; e o arquivo de fatos citava um caminho de entrypoint do worker que não existe no repositório. Todos foram resolvidos a favor da transcrição.
5. Falso positivo no gate da onda 1. O script acusou "desafio.md alterado", mas o arquivo nunca foi versionado (`git status` com `??`, sem `M`), e `src`, `prisma`, `tests` e `TRANSCRICAO.md` estavam intactos. Nenhuma re-execução foi necessária.

Ressalvas deixadas pelos agentes para a revisão humana: metas e riscos do PRD marcados como `[PROPOSTA]`; extensão do papel "qualquer autenticada" a rotação de secret e consulta de entregas por inferência (PRD-FR-11); ADR-003-ALT-02 e ADR-006-ALT-01 marcadas como plausíveis, não discutidas na reunião; autor e responsável como `[a definir]`; seis dúvidas do FDD (se as 5 tentativas incluem o envio inicial, formato de `X-Signature` na transição de secret, cifrar o secret, ordem em retry, evento na criação do pedido, responsável).

## Como navegar a entrega

Ordem sugerida de leitura:

1. `README.md`: o processo de produção (este arquivo).
2. [docs/PRD.md](docs/PRD.md): por quê e o quê (problema, objetivos, escopo, requisitos, riscos, aceite).
3. [docs/RFC.md](docs/RFC.md): proposta em alto nível, alternativas descartadas e questões em aberto.
4. [docs/adrs/ADR-001-outbox-transacional-no-mysql.md](docs/adrs/ADR-001-outbox-transacional-no-mysql.md)
5. [docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md](docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md)
6. [docs/adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md](docs/adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md)
7. [docs/adrs/ADR-004-entrega-at-least-once-com-x-event-id.md](docs/adrs/ADR-004-entrega-at-least-once-com-x-event-id.md)
8. [docs/adrs/ADR-005-worker-separado-com-polling.md](docs/adrs/ADR-005-worker-separado-com-polling.md)
9. [docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md](docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md)
10. [docs/FDD.md](docs/FDD.md): como construir (fluxos, contratos, erros, observabilidade, integração com o código).
11. [docs/TRACKER.md](docs/TRACKER.md): rastreabilidade dos itens dos documentos até a transcrição e o código.
