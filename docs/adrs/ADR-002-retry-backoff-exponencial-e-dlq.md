---
status: aceito
date: 2026-11-15
tags: [webhooks, retry, dlq]
---

# ADR-002: Retry com backoff exponencial de 5 tentativas e DLQ em tabela separada

ID: **ADR-002**

## Status
Aceito (decidido na reunião técnica) (src: [09:17] Larissa)

## Contexto
Clientes podem ficar indisponíveis ao receber o webhook. Já houve cliente com indisponibilidade de duas horas em manutenção planejada (src: [09:16] Diego). É preciso definir quantas vezes tentar de novo, em que intervalos, e o que fazer com o evento que esgota as tentativas (src: [09:14] Larissa; [09:15] Diego).

## Decisão
Aplicar backoff exponencial com 5 tentativas, nos intervalos de 1 minuto, 5 minutos, 30 minutos, 2 horas e 12 horas, cobrindo cerca de 15 horas entre a primeira falha e a última tentativa (src: [09:17] Diego; [09:17] Larissa). Esgotadas as tentativas, o evento vai para uma tabela separada `webhook_dead_letter`, com o payload, o motivo da falha e o timestamp (src: [09:18] Diego). O reprocessamento é manual, por `POST /admin/webhooks/dead-letter/:id/replay`, que recoloca o evento na outbox como pendente (src: [09:18] Diego). O replay exige role `ADMIN` e registra em log quem o executou, para auditoria (src: [09:36] Sofia; [09:36] Larissa).

## Alternativas Consideradas
### ADR-002-ALT-01: Apenas 3 retries
- Descrição: política mais agressiva, com 3 tentativas.
- Prós e contras: descarta mais cedo e libera o worker, mas a janela é curta.
- Motivo do descarte: três tentativas em cerca de 30 minutos encerrariam o evento durante uma indisponibilidade de manhã ou uma manutenção de 2 horas (src: [09:16] Diego)

### ADR-002-ALT-02: Retry indefinido com backoff
- Descrição: tentar para sempre, com intervalos crescentes.
- Prós e contras: nunca perde evento, mas deixa evento pendurado para sempre se o cliente sumiu.
- Motivo do descarte: risco de evento pendente eternamente (src: [09:15] Diego)

### ADR-002-ALT-03: Marcar como falho na própria outbox, sem tabela separada
- Descrição: manter o evento morto na tabela principal com status de falha.
- Prós e contras: menos uma tabela, mas polui a leitura da outbox.
- Motivo do descarte: tabela separada deixa a leitura da outbox mais limpa e serve de evidência para debug e reprocessamento (src: [09:17] Larissa; [09:18] Diego)

## Consequências
### Positivas
- Cobre indisponibilidades longas do cliente, como manutenções de até 2 horas (src: [09:16] Diego).
- Evento não fica pendente para sempre.
- A outbox principal fica limpa; a DLQ serve de histórico para debug (src: [09:18] Diego).
- O replay admin com auditoria dá controle sobre reprocessamento (src: [09:36] Sofia).

### Negativas
- Um evento pode levar quase 15 horas para ser dado como falho definitivo; um cliente fora por mais tempo depende de replay manual (src: [09:17] Marcos).
- Há uma tabela adicional para manter e operar.
- O aviso ao cliente por e-mail após falhas consecutivas ficou fora de escopo; hoje a visibilidade é só pelo histórico de entregas (src: [09:37] Larissa).

### Trade-off explícito
O time aceitou uma janela longa até o descarte (cerca de 15 horas) e o replay manual em troca de tolerar quedas prolongadas sem deixar eventos pendentes indefinidamente (src: [09:17] Marcos; [09:15] Diego).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-001-outbox-transacional-no-mysql.md
- ADR-005-worker-separado-com-polling.md
- `src/middlewares/auth.middleware.ts` (`requireRole`)
