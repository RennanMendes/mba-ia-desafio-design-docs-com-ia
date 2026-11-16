---
status: aceito
date: 2026-11-15
tags: [webhooks, outbox, mysql]
---

# ADR-001: Padrão Outbox transacional no MySQL para o registro de eventos de webhook

ID: **ADR-001**

## Status
Aceito (decidido na reunião técnica) (src: [09:08] Larissa)

## Contexto
Três clientes B2B pediram notificação quando o status de seus pedidos muda (src: [09:00] Marcos). A transação de mudança de status já é pesada: atualiza `orders`, insere em `order_status_history` e decrementa `stock_quantity` (src: [09:04] Bruno; src/modules/orders/order.service.ts). No código, `OrderService.changeStatus` executa tudo dentro de `this.prisma.$transaction` (src: src/modules/orders/order.service.ts). Uma chamada HTTP no meio dessa transação deixaria clientes lentos travarem a mudança de status de outros pedidos, e um cliente fora do ar não pode causar rollback da mudança (src: [09:04] Bruno). O time é pequeno e subir infraestrutura nova foi considerado excessivo (src: [09:07] Diego). Não existe hoje nenhuma estrutura de fila ou outbox no código (src: src/modules/orders/order.service.ts).

## Decisão
Adotar o padrão Outbox no MySQL existente. Na mesma transação SQL que atualiza `orders` e `order_status_history`, o sistema insere uma linha na tabela `webhook_outbox` com o evento; um worker separado lê a tabela e dispara as chamadas HTTP (src: [09:06] Diego). Se a transação der rollback, o evento some junto; se confirmar, o evento está registrado (src: [09:06] Diego; [09:40] Bruno). A inserção ocorre em `changeStatus` por meio de `publishWebhookEvent(tx, order, fromStatus, toStatus)`, que recebe o cliente de transação (src: [09:41] Bruno). A tabela tem índices em status e em `created_at` (src: [09:08] Diego), usa UUID como identificador (src: [09:51] Larissa) e guarda o payload já renderizado, como snapshot do momento da mudança (src: [09:52] Larissa).

## Alternativas Consideradas
### ADR-001-ALT-01: Envio síncrono dentro do service de pedidos
- Descrição: chamar o endpoint do cliente dentro de `changeStatus`.
- Prós e contras: simples, mas acopla a latência e a disponibilidade do cliente à transação de pedidos; rollback por cliente fora do ar não é aceitável.
- Motivo do descarte: "síncrono não rola" e "está fora de questão" (src: [09:04] Bruno; [09:06] Diego)

### ADR-001-ALT-02: Redis Streams ou Redis Cluster como fila
- Descrição: publicar o evento em um broker externo.
- Prós e contras: broker dedicado a filas, mas exige subir e operar infraestrutura nova, sem atomicidade com a transação do MySQL.
- Motivo do descarte: "overengineering" para um time pequeno; outbox no MySQL existente resolve (src: [09:07] Larissa; [09:07] Diego)

## Consequências
### Positivas
- Atomicidade: não existe caso de status mudar sem evento, nem de evento sem mudança (src: [09:40] Bruno; [09:41] Diego).
- Nenhuma infraestrutura nova além do MySQL já em uso (src: [09:07] Diego).
- O payload em snapshot mantém o evento fiel ao estado no momento da mudança (src: [09:52] Larissa).
- Índices por status e `created_at` permitem ao worker ler só pendentes em lotes pequenos (src: [09:08] Diego).

### Negativas
- Falha ao inserir na outbox reverte a mudança de status do pedido (src: [09:40] Bruno).
- A transação de pedidos passa a gravar uma linha a mais por mudança de status.
- Limitação conhecida: o arquivamento de linhas entregues (cerca de 30 dias) ficou fora do escopo desta entrega, então a tabela cresce até que seja tratado (src: [09:08] Diego).

### Trade-off explícito
O time aceitou acoplar a mudança de status à gravação do evento (e um custo extra de escrita na transação) em troca de consistência garantida sem nova infraestrutura (src: [09:40] Bruno; [09:07] Diego).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-002-retry-backoff-exponencial-e-dlq.md
- ADR-005-worker-separado-com-polling.md
- `src/modules/orders/order.service.ts`
