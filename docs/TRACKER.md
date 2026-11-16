# TRACKER

| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |
|---|---|---|---|---|---|
| PRD-OBJ-01 | docs/PRD.md | Objetivo | Notificar o cliente em tempo real, com entrega em menos de 10 segundos | TRANSCRICAO | [09:02] Marcos |
| PRD-OBJ-02 | docs/PRD.md | Objetivo | Nunca perder nem gerar evento fantasma na mudança de status | TRANSCRICAO | [09:40] Bruno |
| PRD-OBJ-03 | docs/PRD.md | Objetivo | Tolerar indisponibilidade do cliente com janela de cerca de 15 horas em 5 tentativas | TRANSCRICAO | [09:17] Diego |
| PRD-OBJ-04 | docs/PRD.md | Objetivo | Reduzir o polling dos clientes sobre GET /orders com adoção dos 3 clientes | TRANSCRICAO | [09:00] Marcos |
| PRD-OUT-01 | docs/PRD.md | Fora de escopo | Dashboard visual no frontend para webhooks (descartado) | TRANSCRICAO | [09:40] Larissa |
| PRD-OUT-02 | docs/PRD.md | Fora de escopo | E-mail ao cliente após 3 falhas consecutivas (adiado) | TRANSCRICAO | [09:37] Larissa |
| PRD-OUT-03 | docs/PRD.md | Fora de escopo | Arquivamento da outbox após cerca de 30 dias (adiado) | TRANSCRICAO | [09:08] Diego |
| PRD-OUT-04 | docs/PRD.md | Fora de escopo | Múltiplos workers com partição por pedido ou lock pessimista (adiado) | TRANSCRICAO | [09:13] Diego |
| PRD-OUT-05 | docs/PRD.md | Fora de escopo | Rate limiting de envio por cliente (adiado, ponto em aberto) | TRANSCRICAO | [09:39] Larissa |
| PRD-OUT-06 | docs/PRD.md | Fora de escopo | Fluxo inbound de webhooks (descartado) | TRANSCRICAO | [09:02] Marcos |
| PRD-OUT-07 | docs/PRD.md | Fora de escopo | Ordenação global e entrega exactly-once (descartado) | TRANSCRICAO | [09:13] Larissa |
| PRD-FR-01 | docs/PRD.md | Requisito Funcional | Cadastro, edição, remoção e listagem de webhooks por cliente com URL HTTPS | TRANSCRICAO | [09:32] Larissa |
| PRD-FR-02 | docs/PRD.md | Requisito Funcional | Filtro por status de interesse aplicado na geração do evento | TRANSCRICAO | [09:34] Bruno |
| PRD-FR-03 | docs/PRD.md | Requisito Funcional | Evento gravado na mesma transação da mudança de status, como snapshot | TRANSCRICAO | [09:40] Bruno |
| PRD-FR-04 | docs/PRD.md | Requisito Funcional | Entrega assíncrona por processo separado, ordenada por pedido | TRANSCRICAO | [09:09] Diego |
| PRD-FR-05 | docs/PRD.md | Requisito Funcional | Notificação em JSON enxuto com cabeçalhos de identificação e assinatura | TRANSCRICAO | [09:43] Diego |
| PRD-FR-06 | docs/PRD.md | Requisito Funcional | Assinatura HMAC-SHA256 com secret própria de cada webhook | TRANSCRICAO | [09:20] Sofia |
| PRD-FR-07 | docs/PRD.md | Requisito Funcional | Rotação de secret com a anterior válida por 24 horas | TRANSCRICAO | [09:21] Sofia |
| PRD-FR-08 | docs/PRD.md | Requisito Funcional | Cinco tentativas com backoff 1m, 5m, 30m, 2h, 12h e DLQ | TRANSCRICAO | [09:17] Larissa |
| PRD-FR-09 | docs/PRD.md | Requisito Funcional | Reprocessamento manual da DLQ por ADMIN com registro do autor | TRANSCRICAO | [09:36] Larissa |
| PRD-FR-10 | docs/PRD.md | Requisito Funcional | Histórico das últimas 100 entregas de um webhook | TRANSCRICAO | [09:34] Marcos |
| PRD-FR-11 | docs/PRD.md | Requisito Funcional | CRUD e consultas para qualquer role autenticada, replay somente ADMIN | TRANSCRICAO | [09:37] Sofia |
| PRD-FR-12 | docs/PRD.md | Requisito Funcional | Evento acima de 64KB não é enviado e gera erro explícito | TRANSCRICAO | [09:24] Larissa |
| PRD-NFR-01 | docs/PRD.md | Requisito Não Funcional | Latência abaixo de 10 segundos com polling de 2 segundos | TRANSCRICAO | [09:10] Larissa |
| PRD-NFR-02 | docs/PRD.md | Requisito Não Funcional | Entrega at-least-once com deduplicação pelo identificador do evento | TRANSCRICAO | [09:26] Larissa |
| PRD-NFR-03 | docs/PRD.md | Requisito Não Funcional | Somente HTTPS, assinatura HMAC-SHA256 e secret por endpoint | TRANSCRICAO | [09:22] Sofia |
| PRD-NFR-04 | docs/PRD.md | Requisito Não Funcional | Entrega isolada da mudança de status, e reiniciar a API não interrompe o worker | TRANSCRICAO | [09:11] Diego |
| PRD-NFR-05 | docs/PRD.md | Requisito Não Funcional | Timeout de 10 segundos por chamada, falha de rede vai ao backoff | TRANSCRICAO | [09:42] Diego |
| PRD-NFR-06 | docs/PRD.md | Requisito Não Funcional | Consultas do worker apoiadas em índices por status e data de criação | TRANSCRICAO | [09:08] Diego |
| PRD-NFR-07 | docs/PRD.md | Requisito Não Funcional | Reuso dos padrões do projeto (módulo, WEBHOOK_, Pino, Zod, UUID) | TRANSCRICAO | [09:30] Larissa |
| PRD-NFR-08 | docs/PRD.md | Requisito Não Funcional | Replay registra o autor em log para auditoria | TRANSCRICAO | [09:36] Sofia |
| PRD-RISCO-01 | docs/PRD.md | Risco | Rajada de eventos sobrecarrega o servidor do cliente | TRANSCRICAO | [09:38] Diego |
| PRD-RISCO-02 | docs/PRD.md | Risco | Ordenação perdida se houver mais de um worker | TRANSCRICAO | [09:13] Larissa |
| PRD-RISCO-03 | docs/PRD.md | Risco | Crescimento da tabela de eventos sem arquivamento degrada o desempenho | TRANSCRICAO | [09:08] Diego |
| PRD-RISCO-04 | docs/PRD.md | Risco | Cliente indisponível além de cerca de 15 horas perde a entrega automática | TRANSCRICAO | [09:17] Marcos |
| PRD-RISCO-05 | docs/PRD.md | Risco | Vazamento de secret pelo cliente, já ocorrido antes | TRANSCRICAO | [09:22] Diego |
| PRD-RISCO-06 | docs/PRD.md | Risco | Cliente processa eventos duplicados por não deduplicar | TRANSCRICAO | [09:25] Sofia |
| PRD-RISCO-07 | docs/PRD.md | Risco | Prazo de 3 sprints pressionado pela data da Atlas | TRANSCRICAO | [09:46] Larissa |
| PRD-AC-01 | docs/PRD.md | Critério de aceite | Webhook ativo para o novo status recebe a notificação em menos de 10 segundos | TRANSCRICAO | [09:02] Marcos |
| PRD-AC-02 | docs/PRD.md | Critério de aceite | Webhook que não inclui o novo status não gera evento | TRANSCRICAO | [09:34] Bruno |
| PRD-AC-03 | docs/PRD.md | Critério de aceite | Falha na gravação do evento desfaz a mudança de status | TRANSCRICAO | [09:40] Bruno |
| PRD-AC-04 | docs/PRD.md | Critério de aceite | URL HTTP no cadastro é recusada com erro de validação | TRANSCRICAO | [09:23] Sofia |
| PRD-AC-05 | docs/PRD.md | Critério de aceite | Notificação carrega assinatura HMAC-SHA256 válida com a secret do endpoint | TRANSCRICAO | [09:20] Sofia |
| PRD-AC-06 | docs/PRD.md | Critério de aceite | Secret anterior permanece válida por 24 horas após a rotação | TRANSCRICAO | [09:21] Sofia |
| PRD-AC-07 | docs/PRD.md | Critério de aceite | Cliente sem resposta gera 5 tentativas e depois DLQ | TRANSCRICAO | [09:17] Larissa |
| PRD-AC-08 | docs/PRD.md | Critério de aceite | Chamada acima de 10 segundos é falha e reagendada | TRANSCRICAO | [09:42] Diego |
| PRD-AC-09 | docs/PRD.md | Critério de aceite | Replay de evento da DLQ por ADMIN com log, não ADMIN é recusado | TRANSCRICAO | [09:36] Larissa |
| PRD-AC-10 | docs/PRD.md | Critério de aceite | Cliente lista as últimas 100 entregas com resultado, resposta e tempo | TRANSCRICAO | [09:34] Marcos |
| PRD-AC-11 | docs/PRD.md | Critério de aceite | Evento acima de 64KB não é enviado e gera erro explícito | TRANSCRICAO | [09:24] Larissa |
| PRD-AC-12 | docs/PRD.md | Critério de aceite | Eventos do mesmo pedido chegam na ordem de criação | TRANSCRICAO | [09:12] Diego |
| RFC-ALT-01 | docs/RFC.md | Alternativa descartada | Envio síncrono dentro de changeStatus acopla a transação ao cliente | TRANSCRICAO | [09:04] Bruno |
| RFC-ALT-02 | docs/RFC.md | Alternativa descartada | Redis Streams ou Cluster exigiria infraestrutura nova (overengineering) | TRANSCRICAO | [09:07] Diego |
| RFC-ALT-03 | docs/RFC.md | Alternativa descartada | Trigger de banco não notifica processo externo no MySQL | TRANSCRICAO | [09:09] Diego |
| RFC-ALT-04 | docs/RFC.md | Alternativa descartada | Apenas 3 tentativas seria insuficiente para indisponibilidades de 2 horas | TRANSCRICAO | [09:16] Diego |
| RFC-ALT-05 | docs/RFC.md | Alternativa descartada | Retry indefinido deixaria o evento pendurado se o cliente sumisse | TRANSCRICAO | [09:15] Diego |
| RFC-ALT-06 | docs/RFC.md | Alternativa descartada | Exactly-once exigiria coordenação dos dois lados | TRANSCRICAO | [09:25] Diego |
| RFC-ABERTA-01 | docs/RFC.md | Questão em aberto | Rate limiting de envio por cliente, observar e decidir depois | TRANSCRICAO | [09:39] Larissa |
| RFC-ABERTA-02 | docs/RFC.md | Questão em aberto | Múltiplos workers em paralelo perdem a ordem por pedido | TRANSCRICAO | [09:13] Larissa |
| RFC-ABERTA-03 | docs/RFC.md | Questão em aberto | Arquivamento das linhas entregues da outbox após cerca de 30 dias | TRANSCRICAO | [09:08] Diego |
| RFC-ABERTA-04 | docs/RFC.md | Questão em aberto | Aviso por e-mail ao cliente após falhas seguidas, próxima fase | TRANSCRICAO | [09:37] Larissa |
| RFC-RISCO-01 | docs/RFC.md | Risco | Crescimento contínuo da outbox degradando o worker | TRANSCRICAO | [09:08] Diego |
| RFC-RISCO-02 | docs/RFC.md | Risco | Clientes sem deduplicação processam eventos repetidos | TRANSCRICAO | [09:25] Sofia |
| RFC-RISCO-03 | docs/RFC.md | Risco | Vazamento de secret pelo cliente, limitado por secret por endpoint e rotação | TRANSCRICAO | [09:22] Diego |
| RFC-RISCO-04 | docs/RFC.md | Risco | Rajadas de eventos sobrecarregando endpoints sem rate limiting | TRANSCRICAO | [09:38] Diego |
| RFC-RISCO-05 | docs/RFC.md | Risco | Perda da ordenação por pedido com mais de um worker | TRANSCRICAO | [09:13] Larissa |
| RFC-RISCO-06 | docs/RFC.md | Risco | Prazo de 3 sprints com 2 dias úteis de revisão de segurança | TRANSCRICAO | [09:46] Sofia |
| FDD-FLUXO-01 | docs/FDD.md | Fluxo | Criação do evento na outbox dentro da transação de changeStatus | TRANSCRICAO | [09:41] Bruno |
| FDD-FLUXO-02 | docs/FDD.md | Fluxo | Worker com polling de 2s processa a outbox em ordem de created_at | TRANSCRICAO | [09:09] Diego |
| FDD-FLUXO-03 | docs/FDD.md | Fluxo | Retry com backoff fixo 1m, 5m, 30m, 2h, 12h | TRANSCRICAO | [09:17] Diego |
| FDD-FLUXO-04 | docs/FDD.md | Fluxo | DLQ em tabela separada e replay administrativo com auditoria | TRANSCRICAO | [09:36] Sofia |
| FDD-CONTRATO-01 | docs/FDD.md | Contrato | POST /webhooks cria webhook e devolve a secret gerada | TRANSCRICAO | [09:31] Marcos |
| FDD-CONTRATO-02 | docs/FDD.md | Contrato | GET /webhooks lista os webhooks de um cliente | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-03 | docs/FDD.md | Contrato | PATCH /webhooks/:id edita url, events e active | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-04 | docs/FDD.md | Contrato | DELETE /webhooks/:id remove a configuração | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-05 | docs/FDD.md | Contrato | POST /webhooks/:id/rotate-secret com transição de 24h | TRANSCRICAO | [09:21] Sofia |
| FDD-CONTRATO-06 | docs/FDD.md | Contrato | GET /webhooks/:id/deliveries retorna as últimas 100 entregas | TRANSCRICAO | [09:34] Marcos |
| FDD-CONTRATO-07 | docs/FDD.md | Contrato | POST /admin/webhooks/dead-letter/:id/replay restrito a ADMIN | TRANSCRICAO | [09:18] Diego |
| FDD-CONTRATO-08 | docs/FDD.md | Contrato | Requisição de saída com headers X-Event-Id, X-Signature, X-Timestamp, X-Webhook-Id | TRANSCRICAO | [09:44] Diego |
| FDD-ERR-01 | docs/FDD.md | Erro | WEBHOOK_NOT_FOUND, webhook inexistente (404) | TRANSCRICAO | [09:28] Bruno |
| FDD-ERR-02 | docs/FDD.md | Erro | WEBHOOK_INVALID_URL, URL malformada ou sem https (400) | TRANSCRICAO | [09:23] Sofia |
| FDD-ERR-03 | docs/FDD.md | Erro | WEBHOOK_INVALID_EVENTS, lista de eventos inválida (400) | TRANSCRICAO | [09:29] Larissa |
| FDD-ERR-04 | docs/FDD.md | Erro | WEBHOOK_CUSTOMER_NOT_FOUND, customer_id inexistente (422) | TRANSCRICAO | [09:29] Larissa |
| FDD-ERR-05 | docs/FDD.md | Erro | WEBHOOK_PAYLOAD_TOO_LARGE, payload acima de 64KB (422) | TRANSCRICAO | [09:24] Larissa |
| FDD-ERR-06 | docs/FDD.md | Erro | WEBHOOK_SECRET_ROTATION_IN_PROGRESS, rotação já em transição (409) | TRANSCRICAO | [09:21] Sofia |
| FDD-ERR-07 | docs/FDD.md | Erro | WEBHOOK_ADMIN_ROLE_REQUIRED, replay sem role ADMIN (403) | TRANSCRICAO | [09:36] Larissa |
| FDD-ERR-08 | docs/FDD.md | Erro | WEBHOOK_DEAD_LETTER_NOT_FOUND, entrada da DLQ inexistente (404) | TRANSCRICAO | [09:18] Diego |
| FDD-ERR-09 | docs/FDD.md | Erro | WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED, entrada já reprocessada (409) | TRANSCRICAO | [09:18] Diego |
| FDD-ERR-10 | docs/FDD.md | Erro | WEBHOOK_INACTIVE, webhook inativo ou removido no envio ou replay | TRANSCRICAO | [09:29] Larissa |
| FDD-ERR-11 | docs/FDD.md | Erro | WEBHOOK_SECRET_REQUIRED, webhook sem secret ao assinar | TRANSCRICAO | [09:28] Bruno |
| FDD-ERR-12 | docs/FDD.md | Erro | WEBHOOK_DELIVERY_TIMEOUT, cliente não respondeu em 10s | TRANSCRICAO | [09:42] Diego |
| FDD-ERR-13 | docs/FDD.md | Erro | WEBHOOK_DELIVERY_FAILED, erro de rede ou status fora de 2xx | TRANSCRICAO | [09:42] Diego |
| FDD-ERR-14 | docs/FDD.md | Erro | WEBHOOK_MAX_ATTEMPTS_EXCEEDED, retries esgotados vão à DLQ | TRANSCRICAO | [09:18] Diego |
| FDD-RES-01 | docs/FDD.md | Requisito Não Funcional | Timeout de 10s por envio sem nova dependência | TRANSCRICAO | [09:42] Diego |
| FDD-RES-02 | docs/FDD.md | Requisito Não Funcional | Cinco reenvios, sem retries infinitos | TRANSCRICAO | [09:15] Diego |
| FDD-RES-03 | docs/FDD.md | Requisito Não Funcional | Backoff em tabela fixa aplicada em nextAttemptAt, janela de quase 15h | TRANSCRICAO | [09:17] Diego |
| FDD-RES-04 | docs/FDD.md | Requisito Não Funcional | Fallback para DLQ e replay manual por ADMIN, sem aviso por e-mail | TRANSCRICAO | [09:18] Diego |
| FDD-RES-05 | docs/FDD.md | Requisito Não Funcional | Worker em processo separado isola API e entregas | TRANSCRICAO | [09:11] Diego |
| FDD-RES-06 | docs/FDD.md | Proposta de design | Linhas PROCESSING órfãs voltam a PENDING na inicialização do worker | TRANSCRICAO | [09:24] Diego |
| FDD-OBS-01 | docs/FDD.md | Proposta de design | Métrica webhook_outbox_pending_total | TRANSCRICAO | [09:08] Diego |
| FDD-OBS-02 | docs/FDD.md | Proposta de design | Métrica webhook_outbox_oldest_pending_seconds para a meta de 10s | TRANSCRICAO | [09:10] Larissa |
| FDD-OBS-03 | docs/FDD.md | Proposta de design | Métrica webhook_delivery_total por resultado | TRANSCRICAO | [09:42] Diego |
| FDD-OBS-04 | docs/FDD.md | Proposta de design | Métrica webhook_delivery_duration_ms do tempo de resposta do cliente | TRANSCRICAO | [09:34] Marcos |
| FDD-OBS-05 | docs/FDD.md | Proposta de design | Métrica webhook_dead_letter_total de entradas e replays | TRANSCRICAO | [09:18] Diego |
| FDD-OBS-06 | docs/FDD.md | Proposta de design | Logs de enqueue e de payload grande na API com Pino | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-07 | docs/FDD.md | Proposta de design | Logs estruturados do worker (início, lote, sucesso, falha, DLQ) | TRANSCRICAO | [09:29] Bruno |
| FDD-OBS-08 | docs/FDD.md | Proposta de design | Log de auditoria do replay com userId, email e requestId | TRANSCRICAO | [09:36] Sofia |
| FDD-OBS-09 | docs/FDD.md | Proposta de design | Correlação ponta a ponta por eventId, sem tracing distribuído | TRANSCRICAO | [09:25] Diego |
| FDD-AC-01 | docs/FDD.md | Critério de aceite | Mudança para status assinado cria linha PENDING por webhook interessado | TRANSCRICAO | [09:34] Bruno |
| FDD-AC-02 | docs/FDD.md | Critério de aceite | Falha forçada no insert da outbox reverte status e histórico | TRANSCRICAO | [09:40] Bruno |
| FDD-AC-03 | docs/FDD.md | Critério de aceite | Payload acima de 64KB faz changeStatus falhar sem envio | TRANSCRICAO | [09:24] Larissa |
| FDD-AC-04 | docs/FDD.md | Critério de aceite | Worker entrega em até 10s com os 5 headers e assinatura verificável | TRANSCRICAO | [09:10] Larissa |
| FDD-AC-05 | docs/FDD.md | Critério de aceite | Cliente que demora mais de 10s gera timeout e retry em 1 minuto | TRANSCRICAO | [09:42] Diego |
| FDD-AC-06 | docs/FDD.md | Critério de aceite | Falhas contínuas aplicam 1m, 5m, 30m, 2h, 12h e depois DLQ | TRANSCRICAO | [09:17] Diego |
| FDD-AC-07 | docs/FDD.md | Critério de aceite | Replay com ADMIN retorna 202 e gera auditoria, OPERATOR recebe 403 | TRANSCRICAO | [09:36] Sofia |
| FDD-AC-08 | docs/FDD.md | Critério de aceite | URL http:// no cadastro retorna 400 com WEBHOOK_INVALID_URL | TRANSCRICAO | [09:23] Sofia |
| FDD-AC-09 | docs/FDD.md | Critério de aceite | Após rotação, secret antiga e nova valem por 24h, depois só a nova | TRANSCRICAO | [09:21] Sofia |
| FDD-AC-10 | docs/FDD.md | Critério de aceite | Deliveries retorna no máximo 100 itens do mais recente ao mais antigo | TRANSCRICAO | [09:34] Marcos |
| FDD-AC-11 | docs/FDD.md | Critério de aceite | Mudanças PAID, PROCESSING, SHIPPED chegam em ordem com um único worker | TRANSCRICAO | [09:12] Diego |
| FDD-AC-12 | docs/FDD.md | Critério de aceite | Suíte atual de tests/orders.test.ts continua passando | CODIGO | tests/orders.test.ts |
| FDD-RISCO-01 | docs/FDD.md | Risco | Inversão de ordem durante retry | TRANSCRICAO | [09:12] Diego |
| FDD-RISCO-02 | docs/FDD.md | Risco | Cliente lento bloqueia o worker único | TRANSCRICAO | [09:42] Diego |
| FDD-RISCO-03 | docs/FDD.md | Risco | Entrega duplicada exige deduplicação por X-Event-Id | TRANSCRICAO | [09:24] Diego |
| FDD-RISCO-04 | docs/FDD.md | Risco | Vazamento de secret, que precisa ficar legível para assinar | TRANSCRICAO | [09:22] Diego |
| FDD-RISCO-05 | docs/FDD.md | Risco | Crescimento da outbox e do histórico de entregas | TRANSCRICAO | [09:08] Diego |
| FDD-RISCO-06 | docs/FDD.md | Risco | Rajada de eventos sobrecarrega o cliente | TRANSCRICAO | [09:38] Diego |
| FDD-RISCO-07 | docs/FDD.md | Risco | Erro de 64KB bloqueia a mudança de status do pedido | TRANSCRICAO | [09:24] Diego |
| FDD-INT-01 | docs/FDD.md | Integração | changeStatus chama publishWebhookEvent dentro do $transaction | CODIGO | src/modules/orders/order.service.ts |
| FDD-INT-02 | docs/FDD.md | Integração | Subclasses de AppError do módulo com código WEBHOOK_ | CODIGO | src/shared/errors/app-error.ts |
| FDD-INT-03 | docs/FDD.md | Integração | Reuso de ConflictError e UnprocessableEntityError com code | CODIGO | src/shared/errors/http-errors.ts |
| FDD-INT-04 | docs/FDD.md | Integração | Ponto de importação dos erros usado pelos middlewares | CODIGO | src/shared/errors/index.ts |
| FDD-INT-05 | docs/FDD.md | Integração | authenticate nos routers e requireRole ADMIN no router admin | CODIGO | src/middlewares/auth.middleware.ts |
| FDD-INT-06 | docs/FDD.md | Integração | error.middleware serializa os AppError do módulo sem alteração | CODIGO | src/middlewares/error.middleware.ts |
| FDD-INT-07 | docs/FDD.md | Integração | validate com schemas Zod do módulo | CODIGO | src/middlewares/validate.middleware.ts |
| FDD-INT-08 | docs/FDD.md | Integração | req.id vira requestId nos logs de enqueue e auditoria | CODIGO | src/middlewares/request-logger.middleware.ts |
| FDD-INT-09 | docs/FDD.md | Integração | Logger Pino compartilhado com redação de secrets | CODIGO | src/shared/logger/index.ts |
| FDD-INT-10 | docs/FDD.md | Integração | paginated monta a resposta da listagem de webhooks | CODIGO | src/shared/http/response.ts |
| FDD-INT-11 | docs/FDD.md | Integração | Registro dos routers webhooks e adminWebhooks | CODIGO | src/routes/index.ts |
| FDD-INT-12 | docs/FDD.md | Integração | buildControllers instancia repository, service e controllers do módulo | CODIGO | src/app.ts |
| FDD-INT-13 | docs/FDD.md | Integração | Entrypoint do worker modelado em src/server.ts com npm run worker | CODIGO | src/server.ts |
| FDD-INT-14 | docs/FDD.md | Integração | Worker obtém própria instância de PrismaClient com a mesma DATABASE_URL | CODIGO | src/config/database.ts |
| FDD-INT-15 | docs/FDD.md | Integração | Worker reutiliza env validado, sem variável nova | CODIGO | src/config/env.ts |
| FDD-INT-16 | docs/FDD.md | Integração | Status de events usam o enum OrderStatus e canTransition | CODIGO | src/modules/orders/order.status.ts |
| FDD-INT-17 | docs/FDD.md | Integração | Novos models Webhook, WebhookOutbox, WebhookDelivery, WebhookDeadLetter | CODIGO | prisma/schema.prisma |
| FDD-INT-18 | docs/FDD.md | Integração | Setup de testes limpa as tabelas do módulo antes de order e customer | CODIGO | tests/setup.ts |
| FDD-INT-19 | docs/FDD.md | Integração | orders.test.ts como referência de estilo e regressão | CODIGO | tests/orders.test.ts |
| ADR-001 | docs/adrs/ADR-001-outbox-transacional-no-mysql.md | Decisão | Padrão Outbox transacional no MySQL | TRANSCRICAO | [09:08] Larissa |
| ADR-001-ALT-01 | docs/adrs/ADR-001-outbox-transacional-no-mysql.md | Alternativa descartada | Envio síncrono dentro do service de pedidos | TRANSCRICAO | [09:04] Bruno |
| ADR-001-ALT-02 | docs/adrs/ADR-001-outbox-transacional-no-mysql.md | Alternativa descartada | Redis Streams ou Redis Cluster como fila | TRANSCRICAO | [09:07] Diego |
| ADR-002 | docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md | Decisão | Retry com backoff de 5 tentativas e DLQ em tabela separada | TRANSCRICAO | [09:17] Larissa |
| ADR-002-ALT-01 | docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md | Alternativa descartada | Apenas 3 retries | TRANSCRICAO | [09:16] Diego |
| ADR-002-ALT-02 | docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md | Alternativa descartada | Retry indefinido com backoff | TRANSCRICAO | [09:15] Diego |
| ADR-002-ALT-03 | docs/adrs/ADR-002-retry-backoff-exponencial-e-dlq.md | Alternativa descartada | Marcar como falho na própria outbox, sem tabela separada | TRANSCRICAO | [09:18] Diego |
| ADR-003 | docs/adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md | Decisão | HMAC-SHA256 com secret por endpoint e rotação com 24h | TRANSCRICAO | [09:22] Sofia |
| ADR-003-ALT-01 | docs/adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md | Alternativa descartada | Secret global da plataforma | TRANSCRICAO | [09:21] Sofia |
| ADR-003-ALT-02 | docs/adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md | Alternativa descartada | Rotação sem período de transição | TRANSCRICAO | [09:21] Sofia |
| ADR-004 | docs/adrs/ADR-004-entrega-at-least-once-com-x-event-id.md | Decisão | Entrega at-least-once com X-Event-Id para deduplicação | TRANSCRICAO | [09:26] Larissa |
| ADR-004-ALT-01 | docs/adrs/ADR-004-entrega-at-least-once-com-x-event-id.md | Alternativa descartada | Entrega exactly-once | TRANSCRICAO | [09:25] Diego |
| ADR-005 | docs/adrs/ADR-005-worker-separado-com-polling.md | Decisão | Worker em processo Node separado com polling de 2 segundos | TRANSCRICAO | [09:10] Larissa |
| ADR-005-ALT-01 | docs/adrs/ADR-005-worker-separado-com-polling.md | Alternativa descartada | Triggers ou listener do banco para acionar o worker | TRANSCRICAO | [09:09] Diego |
| ADR-005-ALT-02 | docs/adrs/ADR-005-worker-separado-com-polling.md | Alternativa descartada | Worker dentro da mesma instância da API | TRANSCRICAO | [09:11] Diego |
| ADR-006 | docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md | Decisão | Reuso dos padrões existentes do projeto no módulo de webhooks | TRANSCRICAO | [09:30] Larissa |
| ADR-006-ALT-01 | docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md | Alternativa descartada | Estrutura e estilo próprios para o módulo de webhooks | TRANSCRICAO | [09:30] Larissa |
| ADR-006-ALT-02 | docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md | Alternativa descartada | Injetar um repository de webhook no OrderService | TRANSCRICAO | [09:41] Diego |
