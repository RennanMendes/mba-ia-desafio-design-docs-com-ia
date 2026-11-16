---
status: aceito
date: 2026-11-15
tags: [webhooks, worker, polling]
---

# ADR-005: Worker em processo Node separado com polling de 2 segundos

ID: **ADR-005**

## Status
Aceito (decidido na reunião técnica) (src: [09:10] Larissa)

## Contexto
A outbox precisa ser lida e as chamadas HTTP disparadas por alguém. Os clientes consideram "tempo real" qualquer entrega abaixo de 10 segundos (src: [09:02] Marcos). Se o worker rodasse dentro da API, reiniciar a API o derrubaria (src: [09:11] Diego). O projeto tem hoje um único ponto de entrada, `src/server.ts`, e uma instância única de `PrismaClient` por processo em `src/config/database.ts` (src: src/server.ts; src/config/database.ts).

## Decisão
O worker roda como processo Node separado da API, com entrypoint novo ao lado de `src/server.ts` e um script `npm run worker` (src: [09:11] Larissa; [09:11] Diego). Ele lê a outbox por polling em loop a cada 2 segundos, buscando os eventos pendentes mais antigos em lote pequeno (src: [09:09] Diego; [09:10] Larissa). Usa um `PrismaClient` próprio, com o mesmo banco e a mesma `DATABASE_URL` da API (src: [09:30] Bruno). Haverá um único worker, que processa por ordem de `created_at`; a ordenação é garantida apenas por `order_id` e enquanto houver um só worker (src: [09:12] Diego; [09:13] Larissa).

## Alternativas Consideradas
### ADR-005-ALT-01: Triggers ou listener do banco para acionar o worker
- Descrição: notificar o worker de forma reativa a partir do MySQL.
- Prós e contras: menor latência, mas o MySQL não tem listener nativo como o NOTIFY/LISTEN do Postgres; trigger só executa SQL e avisar um processo externo exigiria improviso.
- Motivo do descarte: solução "esquisita" e frágil; polling de 2 segundos atende o requisito de menos de 10 segundos (src: [09:09] Diego)

### ADR-005-ALT-02: Worker dentro da mesma instância da API
- Descrição: iniciar o laço de entrega no processo da API.
- Prós e contras: um só processo para operar, mas reiniciar a API perde o worker.
- Motivo do descarte: "só não pode ser o mesmo processo" (src: [09:11] Diego)

## Consequências
### Positivas
- O worker sobrevive a reinícios da API (src: [09:11] Diego).
- Polling simples, sem componentes novos; latência de até 2 segundos, dentro do limite de 10 segundos (src: [09:10] Larissa).
- Mesma stack e mesmo banco (src: [09:11] Bruno).
- Ordem por `created_at` entrega os eventos de um mesmo pedido na sequência (src: [09:12] Diego).

### Negativas
- Latência de até 2 segundos no pior caso, aceita pelo time (src: [09:10] Larissa).
- Um processo a mais para implantar e monitorar.
- Limitação conhecida: sem garantia de ordenação global, e a ordem por pedido só vale com um único worker; escalar para múltiplos workers ficou para o futuro (src: [09:13] Diego; [09:13] Larissa).

### Trade-off explícito
O time aceitou até 2 segundos de latência e a limitação de um único worker em troca de simplicidade e de ordenação por pedido sem coordenação adicional (src: [09:10] Larissa; [09:13] Larissa).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-001-outbox-transacional-no-mysql.md
- ADR-002-retry-backoff-exponencial-e-dlq.md
- `src/server.ts`
- `src/config/database.ts`
