---
status: aceito
date: 2026-11-15
tags: [webhooks, padroes, codigo-existente]
---

# ADR-006: Reuso dos padrões existentes do projeto no módulo de webhooks

ID: **ADR-006**

## Status
Aceito (decidido na reunião técnica) (src: [09:30] Larissa)

## Contexto
A codebase segue um padrão claro: cada domínio é um módulo sob `src/modules`, com controller, service, repository, routes e schemas (src: [09:27] Bruno). Há uma hierarquia `AppError` em `src/shared/errors/app-error.ts`, com códigos como `INSUFFICIENT_STOCK` e `INVALID_STATUS_TRANSITION`, tratada pelo middleware central em `src/middlewares/error.middleware.ts`, que já cobre `AppError`, Zod e Prisma (src: [09:28] Bruno; [09:29] Bruno). O logger Pino está em `src/shared/logger/index.ts`, e `requireRole` existe em `src/middlewares/auth.middleware.ts` (src: [09:29] Bruno; [09:36] Larissa). A integração com pedidos acontece em `OrderService.changeStatus`, em `src/modules/orders/order.service.ts`.

## Decisão
Reuso máximo do que já existe (src: [09:30] Larissa). O módulo `webhooks` fica em `src/modules` com controller, service, repository, routes e schemas Zod, como os demais (src: [09:27] Bruno). Os erros usam `AppError` com o prefixo `WEBHOOK_` nos códigos (src: [09:28] Bruno; [09:29] Larissa). O logger é o Pino do projeto e os erros passam pelo middleware de erro centralizado, sem alterações (src: [09:29] Bruno). O replay da DLQ reaproveita `requireRole` (src: [09:36] Larissa). A ligação com pedidos é a função `publishWebhookEvent(tx, order, fromStatus, toStatus)`, chamada em `changeStatus` e recebendo o cliente de transação, sem injetar um repository inteiro no `OrderService` (src: [09:41] Bruno; [09:41] Diego).

## Alternativas Consideradas
### ADR-006-ALT-01: Estrutura e estilo próprios para o módulo de webhooks
- Descrição: organizar o módulo e o tratamento de erros e logs de forma independente do restante do projeto. [PLAUSÍVEL, não discutida na reunião]
- Prós e contras: liberdade de desenho, mas quebra a consistência da codebase e duplica mecanismos que já funcionam.
- Motivo do descarte: a decisão foi de reuso máximo do que já existe (src: [09:30] Larissa)

### ADR-006-ALT-02: Injetar um repository de webhook no OrderService
- Descrição: o `OrderService` receberia o repository do módulo de webhooks para gravar a outbox.
- Prós e contras: explícito, mas acopla o serviço de pedidos ao módulo de webhooks.
- Motivo do descarte: uma função pura recebendo o `tx` basta (src: [09:41] Diego)

## Consequências
### Positivas
- Consistência com o restante da codebase e curva de aprendizado menor (src: [09:27] Bruno).
- Nenhuma dependência nova de logger ou de tratamento de erro; o middleware central captura os erros sem mudança (src: [09:29] Bruno).
- Acoplamento mínimo entre pedidos e webhooks (src: [09:41] Diego).

### Negativas
- O módulo herda as convenções e limitações atuais, como o `requireRole` ser hoje usado apenas em rotas de usuários (src: src/middlewares/auth.middleware.ts).
- `OrderService.changeStatus` passa a depender de `publishWebhookEvent`, alterando código crítico de pedidos (src: [09:40] Bruno).

### Trade-off explícito
O time aceitou herdar as convenções e limitações do projeto em troca de consistência, menor esforço e nenhuma dependência nova (src: [09:30] Larissa).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-001-outbox-transacional-no-mysql.md
- ADR-002-retry-backoff-exponencial-e-dlq.md
- ADR-005-worker-separado-com-polling.md
- `src/shared/errors/app-error.ts`
- `src/middlewares/error.middleware.ts`
- `src/middlewares/auth.middleware.ts`
- `src/shared/logger/index.ts`
- `src/modules/orders/order.service.ts`
