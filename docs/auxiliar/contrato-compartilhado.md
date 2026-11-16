# Contrato compartilhado entre agentes

Único ponto de acoplamento entre agentes que rodam em paralelo e isolados. Toda convenção que atravessa documentos está aqui. Se algo não está aqui nem nas suas entradas, não presuma: registre como DUVIDA no relato.

## 0. Escopo estrito
- Faça exatamente o que o `desafio.md` pede para o SEU documento. Não crie seções, documentos, requisitos, métricas, ADRs ou arquivos além dos exigidos. Os números do desafio ("pelo menos N") são pisos: só exceda se a reunião realmente discutiu o item (com origem).
- A entrega é puramente documental. Nunca altere `src/`, `prisma/`, `tests/`, configs, `TRANSCRICAO.md` ou `desafio.md`.
- O `README.md` da raiz DEVE ser substituído (requisito 6 do desafio); apenas o agente `redator-readme` o toca. `docs/adrs/README.md` existente não é tocado.
- Toda informação registrada precisa de origem na transcrição ou no código. Sem origem, não entra.

## 1. Fontes e hierarquia
1. `TRANSCRICAO.md` (verdade da reunião; consulta por `Grep`, formato `[hh:mm] Nome: fala`).
2. `docs/auxiliar/fatos-reuniao.md` (consolidação: DECIDIDO/DESCARTADO/ADIADO/QUESTÃO ABERTA). Em conflito com a transcrição, vale a transcrição e o conflito vai para CONFLITOS_ENTRE_FONTES.
3. `docs/auxiliar/contexto-codigo.md` (fatos do código extraídos na onda 0).
4. Código real (`src/`, `prisma/`), só via `Grep`/`Read` cirúrgico, para confirmar caminho ou assinatura.

Divergência já conhecida: `fatos-reuniao.md` diz que o worker "compartilha o pool"; a transcrição ([09:30] Bruno) diz instância separada de `PrismaClient`, mesmo banco e mesma `DATABASE_URL`. Vale a transcrição.

## 2. Origem, marcadores e arquivos que não existem
- Todo item identificável termina com origem entre parênteses: `(src: [09:17] Diego)` ou `(src: src/modules/orders/order.service.ts)`. Mais de uma origem: separar por `;`.
- Timestamp sempre `[hh:mm] Nome`, exatamente como na transcrição (conferir por `Grep`).
- `[PROPOSTA]`: detalhe de design que a reunião não definiu (ex.: nomes de colunas, códigos `WEBHOOK_*`, nomes de métricas). Citar a decisão que o motiva: `[PROPOSTA] (src: [09:18] Diego)`. Nunca apresentar proposta como decisão da reunião.
- `[NEEDS INPUT: pergunta]`: lacuna que exige humano. Também listar em DUVIDAS no relato.
- **Critério do desafio: "Nenhum arquivo de código mencionado nos documentos é inexistente no repositório."** Portanto: só escreva caminhos de arquivo (`src/...ts`, `prisma/...`, `tests/...`) que passam em `ls`. Código novo (entrypoint do worker, arquivos do módulo de webhooks, script `npm run worker`, tabelas) é descrito por NOME LÓGICO em prosa ("entrypoint do worker, ao lado de `src/server.ts`", "módulo `webhooks` sob `src/modules`"), nunca como caminho completo de arquivo inexistente. Diretórios existentes (`src/modules`) podem ser citados. Símbolos (`publishWebhookEvent`, `changeStatus`) e nomes de tabelas/colunas propostos são permitidos.

## 3. IDs (estáveis, no texto, em negrito)
| Doc | IDs |
|---|---|
| PRD | `PRD-FR-nn` (func.), `PRD-NFR-nn`, `PRD-OBJ-nn`, `PRD-OUT-nn` (fora de escopo), `PRD-RISCO-nn`, `PRD-AC-nn` |
| RFC | `RFC-ALT-nn`, `RFC-ABERTA-nn`, `RFC-RISCO-nn` |
| FDD | `FDD-FLUXO-nn`, `FDD-CONTRATO-nn`, `FDD-ERR-nn`, `FDD-RES-nn`, `FDD-OBS-nn`, `FDD-INT-nn`, `FDD-AC-nn`, `FDD-RISCO-nn` |
| ADR | `ADR-00N` (decisão), `ADR-00N-ALT-nn` (cada alternativa) |
Numeração começa em 01 e é contínua por prefixo. Só itens com ID entram no Tracker.

## 4. Mapa fixo de ADRs (6 ADRs, nomes imutáveis, usados em links)
São as 6 decisões principais do requisito 4 do desafio, uma por ADR. Decisões secundárias (payload, timeouts, headers, HTTPS, 64KB) ficam no FDD.
| ID | Arquivo em `docs/adrs/` | Decisão | Fontes-chave (fatos-reuniao) |
|---|---|---|---|
| ADR-001 | `ADR-001-outbox-transacional-no-mysql.md` | Padrão Outbox no MySQL, gravação atômica dentro da transação de `changeStatus`, índices status/created_at, payload pré-renderizado (snapshot) | 09:04, 09:06, 09:07, 09:08, 09:40, 09:41, 09:51, 09:52 |
| ADR-002 | `ADR-002-retry-backoff-exponencial-e-dlq.md` | 5 tentativas (1m, 5m, 30m, 2h, 12h), DLQ em tabela separada, replay admin | 09:15 a 09:18, 09:35, 09:36 |
| ADR-003 | `ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md` | HMAC-SHA256 em `X-Signature`, secret por endpoint, rotação com 24h de transição | 09:20, 09:21 |
| ADR-004 | `ADR-004-entrega-at-least-once-com-x-event-id.md` | At-least-once com `X-Event-Id` para deduplicação no cliente | 09:24, 09:25 |
| ADR-005 | `ADR-005-worker-separado-com-polling.md` | Worker em processo Node separado, polling de 2s, único worker, ordem por `created_at`, `PrismaClient` próprio | 09:09 a 09:13, 09:29, 09:30 |
| ADR-006 | `ADR-006-reuso-dos-padroes-do-projeto.md` | Reuso de módulo por domínio, `AppError` com prefixo `WEBHOOK_`, Pino, error middleware, Zod, `requireRole` | 09:27 a 09:30, 09:36, 09:40 |

Links relativos: de `docs/RFC.md` e `docs/FDD.md` para `adrs/ADR-00N-....md`; de ADR para `../RFC.md` e `../FDD.md`; entre ADRs `ADR-00M-....md`.

## 5. Fronteiras de conteúdo (sem duplicação)
| Doc | Responde | Contém | Não contém |
|---|---|---|---|
| PRD | Por quê e o quê | problema, público, objetivos/métricas, escopo, RF/RNF em linguagem de produto, riscos, aceite, testes | tabelas, colunas, endpoints detalhados, códigos de erro, algoritmos |
| RFC (2 a 4 páginas) | Como pretendemos resolver e o que está aberto | metadados, TL;DR, contexto, proposta em alto nível, alternativas descartadas, questões abertas, impacto e riscos, links de ADR | payloads, schemas, matriz de erros, fluxos passo a passo |
| FDD | Como construir | fluxos, contratos HTTP, matriz de erros, resiliência, observabilidade, integração com código | justificativa longa de decisão (linkar ADR), narrativa de negócio |
| ADR | Por que exatamente assim | 1 decisão, contexto, alternativas, consequências | detalhes de implementação do FDD |
Regra: conteúdo que cabe em outro doc é linkado, não copiado.

## 6. Itens que NÃO entram como requisito (só em Fora de escopo, Alternativas ou Questões em aberto)
- DESCARTADO: Redis Cluster/Streams como fila; triggers de banco como notificador; dashboard/painel no frontend; truncar payload; fluxo inbound.
- Alternativas rejeitadas na reunião: envio síncrono no `changeStatus`; apenas 3 retries; retries infinitos; entrega exactly-once.
- ADIADO: arquivamento da outbox após 30 dias; múltiplos workers (partição por `order_id` ou lock pessimista); e-mail ao cliente após 3 falhas consecutivas.
- QUESTÃO ABERTA: rate limiting de saída por cliente.
- Limitação conhecida: ordenação garantida só por `order_id` e enquanto houver um único worker ([09:13] Larissa).

## 7. Números citáveis (somente se confirmados por Grep na transcrição)
Entrega "tempo real" abaixo de 10s ([09:10]), polling 2s ([09:09]), 5 tentativas e janela ~15h ([09:15] a [09:17]), timeout 10s ([09:42]), payload máx. 64KB ([09:23]), últimas 100 entregas ([09:34]), transição de secret 24h ([09:21]), 3 sprints ([09:45] a [09:46]), auditoria de segurança de 2 dias úteis ([09:46], [09:49]). Outras metas quantitativas só como `[PROPOSTA]`.

## 8. Estilo
Português do Brasil, Markdown, sem emojis, sem travessão longo "—" em prosa. Nomes de código em `crase`. Datas `AAAA-MM-DD`; data do pacote: 2026-11-15. Responsável/autor: `[a definir]` (listar em DUVIDAS).

## 9. Escrita e isolamento
- Cada agente escreve somente os arquivos listados na sua missão. Antes de sobrescrever um stub existente, fazer `Read` dele (exigência da ferramenta).
- Agentes de redação não leem saídas de outros agentes da mesma onda. Não há canal entre agentes: dúvidas vão para o relato; só o orquestrador consolida.
- Autoverificação: cada agente roda `bash docs/auxiliar/validar-entrega.sh <modo>` do seu documento (modos: `prd`, `rfc`, `fdd`, `adrs`, `tracker`, `readme`), corrige as FALHAS, repete até zerar (máx. 3 ciclos) e só então reporta. O script lê apenas o arquivo do próprio modo.

## 10. Formato obrigatório do relato (última mensagem do agente, máx. 50 linhas, sem conteúdo dos documentos)
```
## RELATO <nome-do-agente>
STATUS: OK | OK_COM_RESSALVAS | FALHA
ARQUIVOS: <caminhos criados/alterados>
CHECKLIST_DESAFIO: <cada critério do seu documento: [x] atende / [ ] não atende, com 3 a 8 palavras de evidência>
AUTOVERIFICACAO: <modo do script, ciclos executados, FALHAS restantes>
ERROS: - <o que falhou ou contradiz fonte; "nenhum" se vazio>
DUVIDAS: - <pergunta objetiva para o humano; inclui cada [NEEDS INPUT]>
PRESSUPOSTOS: - <o que foi assumido e onde, inclui cada [PROPOSTA] relevante>
ITENS_SEM_FONTE: - <item e o que foi feito (removido ou mantido como [PROPOSTA])>
CONFLITOS_ENTRE_FONTES: - <ex.: fatos x transcrição>
```
