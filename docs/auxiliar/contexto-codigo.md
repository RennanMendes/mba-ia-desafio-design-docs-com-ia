# Contexto do código (extraído em 2026-11-15)

## Caminhos reais confirmados
- `src/modules/orders/order.service.ts`: `OrderService`, criação e mudança de status em `$transaction`
- `src/modules/orders/order.status.ts`: máquina de estados (`canTransition`, `shouldDebitStock`, `shouldReplenishStock`)
- `src/modules/orders/order.repository.ts`: acesso a dados de `Order`
- `src/modules/orders/order.routes.ts`: rotas `/api/v1/orders` com `authenticate` e `validate`
- `src/modules/orders/order.controller.ts`: `OrderController`, handlers que chamam `next(err)`
- `src/modules/orders/order.schemas.ts`: schemas Zod de pedido
- `src/shared/errors/app-error.ts` e `http-errors.ts`: `AppError` e subclasses HTTP
- `src/middlewares/auth.middleware.ts`: `authenticate`, `requireRole`, tipo `AuthUser`
- `src/middlewares/error.middleware.ts`: `errorMiddleware`, serialização de erros
- `src/middlewares/validate.middleware.ts`: `validate({ body, query, params })`
- `src/middlewares/request-logger.middleware.ts`: `requestLogger`, define `req.id` e loga `http_request`
- `src/shared/logger/index.ts`: `logger` (Pino) e `createLogger`
- `src/shared/http/response.ts`: `paginated` e `buildPagination`
- `src/config/database.ts` e `src/config/env.ts`: `prisma` (instância única) e `env` validado por Zod
- `src/routes/index.ts`, `src/app.ts`, `src/server.ts`: registro de rotas, montagem da app e bootstrap
- `src/modules/customers/customer.service.ts`, `customer.routes.ts`, `customer.schemas.ts`: módulo de referência
- `prisma/schema.prisma`, `tests/orders.test.ts`, `tests/setup.ts`, `vitest.config.ts`

## OrderService.changeStatus
- Assinatura: `changeStatus(id: string, input: UpdateOrderStatusInput, userId: string): Promise<OrderWithRelations>` (`order.service.ts`, linha 126)
- Fluxo dentro de `this.prisma.$transaction(async (tx) => ...)` (linha 131):
  1. `tx.order.findUnique` com `items` (linha 132); `NotFoundError('Order')` se ausente (linha 136)
  2. `from === to` gera `ConflictError` `INVALID_STATUS_TRANSITION` (linhas 140 a 146)
  3. `canTransition` falso gera `InvalidStatusTransitionError` (linhas 147 a 149)
  4. `debitStock` se `shouldDebitStock`; `replenishStock` se `shouldReplenishStock` (linhas 151 a 156)
  5. `tx.order.update` do status (linha 158) e `tx.orderStatusHistory.create` (linhas 159 a 167)
  6. Releitura com `items`, `history`, `customer` (linhas 169 a 177)
- Onde inserir `publishWebhookEvent(tx, ...)`: dentro do `$transaction`, após o passo 5 (histórico) e antes da releitura (inferência de leitura do código, sem decisão registrada)
- Erros já lançados: `NotFoundError`, `ConflictError` (`INVALID_STATUS_TRANSITION`), `InvalidStatusTransitionError`, `InsufficientStockError` (em `debitStock`)
- `OrderService.create` (linhas 50 a 124) também usa `$transaction` e grava histórico inicial (`fromStatus: null`, `toStatus: PENDING`)

## Máquina de estados do pedido
- Enum `OrderStatus` (`prisma/schema.prisma`): PENDING, PAID, PROCESSING, SHIPPED, DELIVERED, CANCELLED
- Transições (`order.status.ts`): PENDING para PAID ou CANCELLED; PAID para PROCESSING ou CANCELLED; PROCESSING para SHIPPED ou CANCELLED; SHIPPED para DELIVERED; DELIVERED e CANCELLED são terminais
- Débito de estoque: PENDING para PAID. Reposição: PAID ou PROCESSING para CANCELLED

## Erros
- Hierarquia `AppError` (status, `code` default):
  - `BadRequestError` 400, `BAD_REQUEST`; `ValidationError` 400, `VALIDATION_ERROR`
  - `UnauthorizedError` 401, `UNAUTHORIZED`; `ForbiddenError` 403, `FORBIDDEN`
  - `NotFoundError` 404, `NOT_FOUND`; `ConflictError` 409, `CONFLICT` (aceita `code` e `details`)
  - `InvalidStatusTransitionError` (extends `ConflictError`) 409, `INVALID_STATUS_TRANSITION`
  - `UnprocessableEntityError` 422, `UNPROCESSABLE_ENTITY`; `InsufficientStockError` (extends) 422, `INSUFFICIENT_STOCK`
- Serialização (`error.middleware.ts`): `AppError` gera `{ error: { code, message, details? } }`. `ZodError` gera 400 `VALIDATION_ERROR`. Prisma `P2002` gera 409 `CONFLICT` e `P2025` gera 404. Demais erros geram 500 `INTERNAL_SERVER_ERROR` com log `Unhandled error in request`

## Autenticação/autorização
- `authenticate`: exige `Authorization: Bearer <token>`, verifica com `env.JWT_SECRET`, popula `req.user`
- `requireRole(...roles: AuthUser['role'][])`: retorna `RequestHandler`; `ForbiddenError` se a role não estiver na lista
- Roles (`prisma/schema.prisma`, enum `UserRole`): ADMIN, OPERATOR
- JWT (`auth.service.ts`, `signToken`) carrega `sub`, `email`, `role`; `AuthUser` = `{ id, email, role }`
- `requireRole` é usado só em `src/modules/users/user.routes.ts` (`requireRole('ADMIN')`). Rotas de pedidos usam só `authenticate`

## Padrão de módulo
- Camadas: `<x>.repository.ts`, `<x>.service.ts`, `<x>.controller.ts`, `<x>.routes.ts`, `<x>.schemas.ts` (pedidos têm também `<x>.status.ts`)
- Routes: `router.use(authenticate)` no topo; `validate({ params | query | body })` por rota antes do controller. Controllers são arrow `RequestHandler` com `try/catch` e `next(err)`
- Schemas Zod com `z.object` e tipos por `z.infer`; IDs com `z.string().uuid()`
- `src/routes/index.ts` registra `router.use('/<prefixo>', build<X>Router(controllers.<x>))` (`/auth`, `/users`, `/customers`, `/products`, `/orders`); `src/app.ts` monta em `/api/v1`. Dependências são instanciadas em `buildControllers`

## Persistência
- Models: `User`, `Customer`, `Product`, `Order`, `OrderItem`, `OrderStatusHistory`, `OrderNumberSequence`. Enums: `UserRole`, `OrderStatus`
- Id: `String @id @default(uuid()) @db.Char(36)` nos models de domínio; `OrderNumberSequence.id` é `Int`
- `@@map` em snake_case plural (`orders`, `order_items`, `order_status_history`, `order_number_sequence`); campos em camelCase
- Índices de `Order`: `customerId`, `status`, `createdAt`, `createdById`. De `OrderStatusHistory`: `orderId`, `changedAt`
- Banco MySQL; `DATABASE_URL` e `SHADOW_DATABASE_URL` via `env()`
- `src/config/database.ts`: `new PrismaClient({ log })` exportado como `prisma` (instância única por processo). `server.ts` chama `$disconnect()` no shutdown
- Variáveis de `src/config/env.ts`: `NODE_ENV`, `PORT` (3000), `LOG_LEVEL` (info), `DATABASE_URL`, `JWT_SECRET` (min 16), `JWT_EXPIRES_IN` (8h)

## Logger e resposta HTTP
- Pino em `src/shared/logger/index.ts`: redact de `authorization`, `cookie`, `password`, `passwordHash`, `token`, `accessToken`; `pino-pretty` só em `development`
- Logs existentes: `http_request`, `server_started`, `shutdown_initiated`, `bootstrap_failed`, `Unhandled error in request`
- `pino-http` está em `package.json` mas não é importado em `src/`
- Lista paginada: `{ data, pagination: { page, pageSize, total, totalPages } }` (`response.ts`). Objeto único: JSON direto. Header `X-Request-Id` definido pelo `requestLogger`

## Não existe no código (confirmado por Grep)
- `worker`, `outbox`, `webhook`, `queue`, `fila`, `event` (case-insensitive) em `src/`, `prisma/` e `package.json`: nenhuma ocorrência
- Script npm `worker`: não existe

## Scripts npm e testes
- Scripts: `dev`, `build`, `start`, `db:migrate`, `db:reset`, `db:seed`, `test` (`vitest run`), `test:watch`, `lint`, `format`
- Framework: Vitest 2.1.4, `include: tests/**/*.test.ts`, `setupFiles: tests/setup.ts`, `fileParallelism: false`
- Testes: `tests/auth.test.ts`, `tests/orders.test.ts` (cobre PENDING para PAID com estoque, 409 em transição inválida, 422 sem estoque, reposição PAID para CANCELLED), `tests/helpers/factories.ts`

## DUVIDAS
- Nenhuma dúvida bloqueante. O ponto de inserção de `publishWebhookEvent` é inferência de leitura do código, a confirmar na RFC/FDD.
