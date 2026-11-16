# Relatório para revisão humana
Data: 2026-11-15   Gate mecânico final (`full`): FALHAS=1 (falso positivo: `desafio.md` não versionado) AVISOS=0

## 1. Resumo
| Agente | Modelo | Status | Re-execuções |
|---|---|---|---|
| investigador-codigo | Haiku | OK | 0 |
| redator-prd | Sonnet | OK_COM_RESSALVAS | 0 |
| redator-rfc | Opus | OK | 0 |
| redator-fdd | Opus | OK_COM_RESSALVAS | 0 |
| redator-adrs | Sonnet | OK | 0 |
| gerador-tracker | Sonnet | OK | 0 |
| redator-readme | Sonnet | OK_COM_RESSALVAS | 0 (2 ciclos internos de autoverificação) |
| revisor-independente | Opus | OK_COM_RESSALVAS | 0 |

- Execução via `general-purpose` com `model` explícito: os agentes de `.claude/agents` não foram reconhecidos como `subagent_type` na sessão (plano B do runbook).
- Veredito do revisor independente: **APROVADO_COM_RESSALVAS**. Nenhum achado BLOQUEANTE. 38 critérios: 35 atendem, 0 não atendem, 3 parciais (autor da RFC `[a definir]`, consistência geral, origem das informações).
- Critérios não atendidos segundo os agentes: nenhum `[ ]`, exceto a ressalva de README (F4 depende de iterações reais da revisão humana).

## 2. Falhas do gate mecânico remanescentes
- `arquivos proibidos alterados: desafio.md`: falso positivo do script. O arquivo nunca foi versionado (`??`); `src/`, `prisma/`, `tests/` e `TRANSCRICAO.md` estão intactos.
- Observação: o modo `full` do script leva alguns minutos (um `grep` por linha do Tracker).

## 3. Dúvidas para o humano (DUVIDAS)
**Todos os documentos**
- Responsável/autor (PRD, RFC, FDD) está `[a definir]`.
**PRD**
- PRD-OBJ-02 (zero perdas) e PRD-OBJ-04 (3 de 3 clientes) são `[PROPOSTA]`: confirmar com Marcos.
**FDD (6 dúvidas; 5 `[NEEDS INPUT]`)**
- "5 tentativas" inclui o envio inicial? O FDD adotou envio inicial + 5 reenvios (coerente com "quase 15h").
- Formato de `X-Signature` durante a transição de 24h (proposta: duas assinaturas separadas por vírgula; validar com Sofia).
- Secret cifrada em repouso? Com qual chave?
- Eventos seguintes do mesmo pedido devem esperar um anterior em retry? Hoje a ordem pode se inverter.
- A criação do pedido (status inicial `PENDING`) deve emitir evento?
**Tracker**
- FDD-RES-07 (erro inesperado em item do lote): remover do FDD ou dar origem?
- Origens atribuídas pelo tracker a FDD-OBS-01/03/05/06/07/09 e FDD-ERR-03/04/10 (itens sem `(src)` próprio) valem?
**Revisor**
- Estourar 64KB deve reverter a mudança de status (como está no FDD) ou apenas registrar falha e não enviar? (ver achado 2)
- A permissão "qualquer role autenticada" vale para rotação de secret e `GET /webhooks/:id/deliveries`?
- O que publicar no repositório (ver seção 8)?

## 4. Erros e conflitos entre fontes
- `fatos-reuniao.md` x transcrição (resolvidos a favor da transcrição): worker "compartilha o pool" (transcrição: `PrismaClient` próprio, [09:30] Bruno); HMAC em [09:20] (RFC usa [09:22] Sofia); UUID em [09:50] (transcrição: [09:51] Larissa); correção do `customer_id` em [09:32] (decisão de Larissa); `fatos-reuniao.md` cita `src/worker.ts`, inexistente.
- Fala x fala: "5 tentativas" ([09:48] Larissa) x "quase 15h entre primeira falha e última tentativa" ([09:17] Diego).
- Interno: FDD (payload > 64KB reverte `changeStatus`: passo 6 de FDD-FLUXO-01, FDD-ERR-05, FDD-AC-03) conflita com PRD-NFR-04 e com a afirmação do FDD de que contratos de `/api/v1/orders` não mudam.
- Erro de processo corrigido pelo agente: `redator-adrs` falhou numa escrita por heredoc e refez com `Write`.
- `docs/adrs/README.md` (pré-existente) manda nomenclatura `0001-titulo.md`, em conflito com `ADR-NNN-*` do desafio.

## 5. Pressupostos e [PROPOSTA] a validar
- PRD: probabilidade/impacto dos 7 riscos; metas PRD-OBJ-02/04; seção de testes; PRD-FR-11 estende "qualquer role autenticada" por inferência; PRD-FR-12 (64KB) tratado como RF.
- FDD: tabelas `webhooks`, `webhook_outbox`, `webhook_deliveries`, `webhook_dead_letter`; rota `POST /webhooks/:id/rotate-secret` e bloqueio de nova rotação (409); códigos `WEBHOOK_*` além dos citados em [09:28]; lote de 10; recuperação de `PROCESSING` órfão; 3xx/4xx como falha; replay mantém `eventId` e responde 202; `DELETE` físico; métricas por logs/consultas; tracing por correlação via `eventId`; ponto de inserção de `publishWebhookEvent` em `changeStatus` (inferência de leitura do código).
- ADRs: `ADR-003-ALT-02` e `ADR-006-ALT-01` marcadas `[PLAUSÍVEL, não discutida na reunião]`; nomes `webhook_outbox` e `webhook_dead_letter` vêm da transcrição ([09:06], [09:18]).
- RFC: 6 alternativas e 4 questões abertas, todas com fonte.

## 6. Itens sem fonte
- `FDD-RES-07`: sem origem, sem linha no Tracker.
- 3 citações com `(src: docs/auxiliar/contexto-codigo.md)` (RFC.md:18, FDD.md:13, FDD.md:81): fonte inválida (deveria ser CODIGO ou TRANSCRICAO).
- `PRD-OBJ-04`, alerta de 10s por 5 minutos (FDD.md:420), lote N=10 (FDD.md:91), `WEBHOOK_ADMIN_ROLE_REQUIRED` (nunca vai na resposta HTTP): `[PROPOSTA]` sem origem na reunião.
- Itens sem ID (Incluso do PRD, Dependências, Invariantes, modelo de dados do FDD) não têm linha no Tracker.

## 7. Achados do revisor independente
| # | Sev. | Tipo | Local | Problema |
|---|---|---|---|---|
| 2 | MEDIA | CONTRADICAO | FDD.md:85, FDD-ERR-05, FDD-AC-03 x PRD.md:116 | 64KB reverte `changeStatus`; reunião só pediu erro ([09:23] Sofia, [09:24] Larissa) e Bruno é contra travar a mudança de status ([09:04]) |
| 1 | MEDIA | INVENCAO (fonte inválida) | RFC.md:18; FDD.md:13, 81 | fonte `docs/auxiliar/...` |
| 8 | MEDIA | EXCESSO | raiz | arquivos de processo não versionados; README depende deles |
| 3 | BAIXA | CONTRADICAO | PRD-FR-11; FDD-CONTRATO-05/06 | permissão estendida além do que a reunião disse |
| 4 | BAIXA | TRACKER_INCORRETO | FDD.md:386 | FDD-RES-07 sem linha |
| 5 | BAIXA | TRACKER_INCORRETO | TRACKER.md:102, 103, 105 | FDD-RES-06, OBS-01, OBS-03 ligados a falas que não os sustentam |
| 6 | BAIXA | EXCESSO | PRD.md:47; FDD.md:420, 91 | metas/números sem origem (marcados `[PROPOSTA]`) |
| 7 | BAIXA | EXCESSO | FDD-ERR-07 | código que nunca chega ao cliente |
| 9 | BAIXA | QUALIDADE | README.md:46, 96, 104 | desatualizado (Tracker e revisor "não constam do log", só 1 ciclo, "seis dúvidas" x 5 `[NEEDS INPUT]`) |
| 10 | BAIXA | QUALIDADE | FDD.md | todos os títulos em H3 (vem do esqueleto do curso) |
| 11 | BAIXA | QUALIDADE | docs/adrs/README.md:5 | nomenclatura divergente |
| 12 | BAIXA | QUALIDADE | RFC.md:18 | "abaixo de 10s" citado em [09:09]/[09:14]; origem é [09:02] Marcos |

## 8. Pendências conhecidas
- README: acrescentar as iterações reais desta execução e da revisão humana; atualizar contagem de ciclos (hoje 1) e mencionar Tracker e revisão independente (achado 9).
- Decidir o que entra no commit (`docs/auxiliar`, `.claude`, `.gemini`, `GEMINI.md`, `CLAUDE.MD`, `desafio.md`): o desafio só pede `README.md`, `docs/PRD.md`, `RFC.md`, `FDD.md`, `TRACKER.md` e `docs/adrs/`. Se `docs/auxiliar` não for publicado, trocar as 3 citações do achado 1 e as referências do README.
- Autor/Responsável dos documentos estão `[a definir]`.
- Nenhum commit foi feito.
