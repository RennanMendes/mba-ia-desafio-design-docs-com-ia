# RFC: Sistema de Webhooks de Notificação de Pedidos

| Campo | Valor |
|---|---|
| Autor | [a definir] |
| Status | Em revisão |
| Data | 2026-11-15 |
| Revisores | Larissa (Tech Lead), Marcos (Product Manager), Bruno (Engenheiro Pleno, time de Pedidos), Diego (Engenheiro Sênior, time de Plataforma), Sofia (Engenheira de Segurança) |

Esta RFC propõe a arquitetura dos webhooks de saída do OMS e abre a proposta para revisão. As decisões individuais estão registradas nos ADRs da seção 7; o detalhamento de implementação (contratos HTTP, modelo de dados, fluxos passo a passo, matriz de erros) fica no [FDD](FDD.md).

## 1. Resumo executivo (TL;DR)

Propomos notificar os clientes sobre mudanças de status dos seus pedidos por webhooks de saída (outbound), sem fluxo de entrada (src: [09:03] Sofia). O evento é gravado numa tabela outbox no MySQL existente, dentro da mesma transação que muda o status do pedido (src: [09:06] Diego; [09:40] Bruno). Um worker em processo Node separado lê a outbox por polling a cada 2 segundos e entrega os eventos por HTTP, assinados com HMAC-SHA256 e com garantia at-least-once identificada por `X-Event-Id` (src: [09:09] Diego; [09:11] Diego; [09:22] Sofia; [09:26] Larissa). Falhas são retentadas 5 vezes com backoff exponencial e, esgotadas, vão para uma tabela de dead letter com replay manual por administrador (src: [09:17] Larissa; [09:18] Diego). Tudo reaproveita os padrões já existentes no projeto (src: [09:30] Larissa). A estimativa é de 3 sprints, incluindo a revisão de segurança (src: [09:47] Larissa).

## 2. Contexto e problema

Os clientes querem saber quando o status de cada pedido deles muda, com entrega percebida como "tempo real", abaixo de 10 segundos (src: [09:09] Diego; [09:14] Marcos). Hoje o OMS não tem nenhum mecanismo de notificação, fila, worker ou outbox (src: docs/auxiliar/contexto-codigo.md).

A mudança de status acontece em `OrderService.changeStatus`, dentro de um `$transaction` do Prisma que já atualiza o pedido, grava `order_status_history` e debita ou repõe estoque (src: src/modules/orders/order.service.ts; [09:04] Bruno). Essa transação é pesada; acrescentar uma chamada HTTP a sistemas de terceiros nela faria qualquer cliente lento travar mudanças de status de outros pedidos, e um cliente fora do ar não pode provocar rollback do pedido (src: [09:04] Bruno).

Restrições do contexto: o time é pequeno e não quer operar infraestrutura nova (src: [09:07] Diego); a base é MySQL acessado por Prisma, com uma instância de `PrismaClient` por processo (src: src/config/database.ts; [09:30] Bruno); o projeto já tem padrões consolidados de módulo por domínio, erros `AppError`, logger Pino, middleware de erros centralizado, validação Zod e autorização por `requireRole` (src: src/middlewares/auth.middleware.ts; [09:27] Bruno; [09:29] Bruno). O cliente Atlas quer a funcionalidade para o fim de novembro (src: [09:45] Marcos).

## 3. Proposta técnica

A proposta tem cinco blocos, descritos aqui em nível de arquitetura.

**Registro do evento (outbox transacional).** Quando o status muda, `changeStatus` chama uma função pura `publishWebhookEvent(tx, order, fromStatus, toStatus)` que recebe o cliente de transação atual e insere o evento na outbox na mesma transação; se a inserção falhar, a mudança de status sofre rollback (src: [09:40] Bruno; [09:41] Bruno; [09:41] Diego). O payload é gravado já renderizado, como snapshot do momento da mudança (src: [09:52] Larissa). O evento só é inserido se algum webhook do cliente assina aquele status, e a tabela é indexada por status e data de criação para leitura eficiente (src: [09:34] Bruno; [09:08] Diego). Ver [ADR-001](adrs/ADR-001-outbox-transacional-no-mysql.md).

**Processamento (worker separado).** Um novo entrypoint de worker, ao lado de `src/server.ts`, roda como processo Node independente da API, com seu próprio `PrismaClient` apontando para o mesmo banco e a mesma `DATABASE_URL` (src: [09:11] Diego; [09:11] Larissa; [09:30] Bruno). Ele faz polling a cada 2 segundos, lê os eventos pendentes mais antigos em lotes pequenos e os processa em ordem de criação. Com um único worker, a ordem é preservada por pedido; não há garantia de ordem global (src: [09:09] Diego; [09:12] Diego; [09:13] Larissa). Ver [ADR-005](adrs/ADR-005-worker-separado-com-polling.md).

**Entrega HTTP segura.** Cada requisição é assinada com HMAC-SHA256 sobre o corpo, usando uma secret exclusiva por endpoint cadastrado, rotacionável com período de transição de 24 horas (src: [09:22] Sofia). Ver [ADR-003](adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md). A semântica é at-least-once: o cliente pode receber duplicatas e deduplica pelo `X-Event-Id` (src: [09:24] Diego; [09:25] Diego). Ver [ADR-004](adrs/ADR-004-entrega-at-least-once-com-x-event-id.md). Os requisitos complementares de entrega discutidos na reunião (HTTPS obrigatório, timeout, limite de tamanho, payload enxuto e cabeçalhos) são tratados no FDD (src: [09:23] Sofia; [09:42] Diego; [09:44] Diego).

**Resiliência.** Falhas de entrega são retentadas até 5 vezes com backoff exponencial de 1m, 5m, 30m, 2h e 12h, cobrindo cerca de 15 horas (src: [09:17] Diego; [09:17] Larissa). Eventos que esgotam as tentativas vão para uma tabela de dead letter separada, preservando payload, motivo e momento da falha, e podem ser reprocessados manualmente por um endpoint administrativo (src: [09:18] Diego). Ver [ADR-002](adrs/ADR-002-retry-backoff-exponencial-e-dlq.md).

**Superfície de API e encaixe no código.** O módulo `webhooks` sob `src/modules` segue o padrão de controller, service, repository, routes e schemas Zod, com códigos de erro prefixados por `WEBHOOK_`, reaproveitando Pino e o middleware de erros (src: [09:27] Bruno; [09:29] Larissa; [09:30] Larissa). Ele expõe: CRUD de configuração de webhooks, autenticado por JWT do operador, com `customer_id` informado explicitamente e lista de status desejados (src: [09:31] Marcos; [09:32] Larissa; [09:33] Bruno); consulta das últimas 100 entregas de um webhook (src: [09:34] Marcos); e replay da dead letter restrito à role `ADMIN` via `requireRole`, com log de auditoria de quem executou (src: [09:36] Sofia; [09:36] Larissa). Ver [ADR-006](adrs/ADR-006-reuso-dos-padroes-do-projeto.md).

Fluxo geral: o operador muda o status do pedido; a transação grava pedido, histórico, estoque e, se houver assinante, o evento na outbox; o worker encontra o evento no próximo ciclo de polling, entrega assinado ao endpoint do cliente e registra a tentativa; em falha, reagenda conforme o backoff; após a quinta falha, move para a dead letter, de onde um administrador pode reenfileirá-lo.

## 4. Alternativas consideradas

### RFC-ALT-01: Envio síncrono dentro de `changeStatus`
- Trade-off que levou ao descarte: seria a solução mais direta, mas acopla a transação de pedido à latência e disponibilidade do cliente; um cliente lento trava mudanças de status de outros pedidos e um cliente fora do ar não pode justificar rollback (src: [09:04] Bruno; [09:06] Diego).

### RFC-ALT-02: Fila em Redis Streams ou Redis Cluster
- Trade-off que levou ao descarte: ofereceria uma fila dedicada, mas exige subir e operar infraestrutura nova, o que foi considerado overengineering para um time pequeno quando o MySQL existente resolve (src: [09:07] Larissa; [09:07] Diego).

### RFC-ALT-03: Trigger de banco para notificar o worker
- Trade-off que levou ao descarte: deixaria o worker mais reativo que o polling, mas o MySQL não tem listener nativo como `NOTIFY/LISTEN` do Postgres; a trigger só executa SQL e avisar um processo externo exigiria improvisos frágeis; o polling de 2s já atende o limite de 10s (src: [09:09] Bruno; [09:09] Diego).

### RFC-ALT-04: Apenas 3 tentativas de retry
- Trade-off que levou ao descarte: seria mais agressivo, mas as três tentativas se esgotariam em cerca de 30 minutos, insuficiente para indisponibilidades já observadas de duas horas em manutenção planejada (src: [09:16] Bruno; [09:16] Diego).

### RFC-ALT-05: Retry indefinido com backoff
- Trade-off que levou ao descarte: nunca desistiria do evento, mas o deixaria pendurado para sempre se o cliente sumisse (src: [09:15] Diego).

### RFC-ALT-06: Entrega exactly-once
- Trade-off que levou ao descarte: eliminaria duplicatas no cliente, mas exigiria coordenação dos dois lados e complexidade muito maior; at-least-once com identificador de evento é o padrão de mercado e resolve a maioria dos casos (src: [09:25] Diego; [09:25] Sofia).

## 5. Questões em aberto

### RFC-ABERTA-01: Rate limiting de envio por cliente
- Situação (não decidida): rajadas, como 50 pedidos de um cliente mudando de status em um minuto, podem sobrecarregar o endpoint dele; ficou fora do escopo, para observar em produção e decidir depois (src: [09:38] Diego; [09:39] Diego; [09:39] Larissa).

### RFC-ABERTA-02: Múltiplos workers em paralelo
- Situação (adiada): escalar para mais de um worker perde a garantia de ordem por pedido; particionar por `order_id` ou usar lock pessimista foram citados como caminhos, mas tratados como problema do futuro e registrados como limitação conhecida (src: [09:12] Diego; [09:13] Diego; [09:13] Larissa).

### RFC-ABERTA-03: Arquivamento das linhas entregues da outbox
- Situação (adiada): arquivar linhas entregues depois de cerca de 30 dias foi mencionado, mas declarado fora do escopo desta funcionalidade (src: [09:08] Diego).

### RFC-ABERTA-04: Aviso por e-mail ao cliente após falhas seguidas
- Situação (adiada): avisar o cliente por e-mail quando o webhook falhar 3 vezes seguidas ficou fora desta fase, podendo voltar numa próxima após medir o impacto (src: [09:37] Marcos; [09:37] Larissa; [09:38] Marcos).

## 6. Impacto e riscos

**Impacto no sistema existente.**
- A transação de `changeStatus` ganha uma escrita adicional e passa a falhar se a outbox falhar; é o ponto de alteração crítico no código atual (src: src/modules/orders/order.service.ts; [09:40] Bruno).
- Um novo processo passa a ser implantado e operado ao lado da API, com conexões próprias ao mesmo banco (src: [09:11] Diego; [09:30] Bruno).
- Novas tabelas de outbox, dead letter e configuração de webhooks no MySQL, seguindo o padrão de identificadores UUID do projeto (src: [09:18] Diego; [09:21] Bruno; [09:51] Larissa).
- Os clientes precisam validar a assinatura e deduplicar eventos; isso será comunicado no portal de desenvolvedor (src: [09:25] Sofia; [09:26] Marcos).

**Riscos.**
- **RFC-RISCO-01**: crescimento contínuo da outbox degradando o worker enquanto o arquivamento estiver adiado; mitigado pelos índices por status e data de criação (src: [09:07] Bruno; [09:08] Diego).
- **RFC-RISCO-02**: clientes que não implementarem deduplicação processarão eventos repetidos, efeito aceito da semântica at-least-once (src: [09:24] Diego; [09:25] Sofia).
- **RFC-RISCO-03**: vazamento de secret pelo cliente, já ocorrido no passado; limitado pela secret por endpoint e pela rotação (src: [09:21] Sofia; [09:22] Diego).
- **RFC-RISCO-04**: rajadas de eventos sobrecarregando endpoints de clientes sem rate limiting, ver **RFC-ABERTA-01** (src: [09:38] Diego).
- **RFC-RISCO-05**: perda da ordenação por pedido se houver mais de um worker ativo antes de resolver **RFC-ABERTA-02** (src: [09:12] Diego; [09:13] Larissa).
- **RFC-RISCO-06**: prazo apertado; a estimativa de 3 sprints inclui pelo menos 2 dias úteis de revisão de segurança antes do deploy, que precisa ser agendada (src: [09:45] Marcos; [09:46] Sofia; [09:47] Larissa; [09:49] Sofia).

## 7. Decisões relacionadas

- [ADR-001: Outbox transacional no MySQL](adrs/ADR-001-outbox-transacional-no-mysql.md): evento gravado na mesma transação da mudança de status, com snapshot do payload.
- [ADR-002: Retry com backoff exponencial e DLQ](adrs/ADR-002-retry-backoff-exponencial-e-dlq.md): 5 tentativas, dead letter em tabela separada e replay administrativo.
- [ADR-003: Autenticação HMAC-SHA256 com secret por endpoint](adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md): assinatura do corpo, secret exclusiva e rotação com 24h de transição.
- [ADR-004: Entrega at-least-once com X-Event-Id](adrs/ADR-004-entrega-at-least-once-com-x-event-id.md): duplicatas possíveis, deduplicação no cliente.
- [ADR-005: Worker separado com polling](adrs/ADR-005-worker-separado-com-polling.md): processo próprio, polling de 2s, worker único e ordem por pedido.
- [ADR-006: Reuso dos padrões do projeto](adrs/ADR-006-reuso-dos-padroes-do-projeto.md): módulo por domínio, `AppError` com prefixo `WEBHOOK_`, Pino, Zod e `requireRole`.
