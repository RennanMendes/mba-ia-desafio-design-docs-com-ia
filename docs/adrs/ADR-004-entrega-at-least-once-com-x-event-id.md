---
status: aceito
date: 2026-11-15
tags: [webhooks, entrega, idempotencia]
---

# ADR-004: Entrega at-least-once com X-Event-Id para deduplicação no cliente

ID: **ADR-004**

## Status
Aceito (decidido na reunião técnica) (src: [09:26] Larissa)

## Contexto
Com retry e outbox, o mesmo evento pode chegar mais de uma vez ao cliente (src: [09:24] Diego). É preciso definir a garantia de entrega oferecida e como o cliente distingue duplicatas (src: [09:25] Bruno).

## Decisão
Garantir entrega at-least-once. Cada evento recebe um UUID gerado quando entra na outbox, enviado no header `X-Event-Id`. O cliente deduplica por esse identificador do lado dele (src: [09:24] Diego; [09:25] Diego; [09:26] Larissa). A responsabilidade de lidar com duplicatas é do cliente, e o time de produto documentará isso de forma destacada no portal de desenvolvedor (src: [09:26] Marcos).

## Alternativas Consideradas
### ADR-004-ALT-01: Entrega exactly-once
- Descrição: garantir que cada evento seja entregue exatamente uma vez.
- Prós e contras: elimina duplicatas para o cliente, mas exige coordenação dos dois lados e é muito mais complexo.
- Motivo do descarte: complexidade; at-least-once com event_id "resolve 99% dos casos" e é o padrão de mercado (src: [09:25] Diego)

## Consequências
### Positivas
- Garantia simples de implementar e alinhada ao que o mercado pratica (src: [09:25] Diego).
- Nenhum evento é perdido por falha transitória, combinando com o retry do ADR-002.
- O `X-Event-Id` é único por evento (src: [09:25] Diego).

### Negativas
- O cliente pode receber o mesmo evento duas vezes e precisa estar preparado (src: [09:24] Diego).
- A responsabilidade de deduplicação passa para o cliente (src: [09:25] Sofia).

### Trade-off explícito
O time aceitou transferir ao cliente a deduplicação em troca de evitar a coordenação bilateral exigida pelo exactly-once (src: [09:25] Diego).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-001-outbox-transacional-no-mysql.md
- ADR-002-retry-backoff-exponencial-e-dlq.md
