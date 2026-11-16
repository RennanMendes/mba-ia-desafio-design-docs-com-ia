# PRD: Sistema de Webhooks de Notificação de Pedidos

Versão: 1.0
Data: 2026-11-15
Responsável: [a definir]

---

## 1. Resumo e contexto da feature

A plataforma passará a notificar clientes B2B, por webhook de saída (outbound), sempre que o status de um pedido mudar. O cliente cadastra uma URL HTTPS, escolhe quais status quer ouvir e recebe um evento assinado, em tempo real (abaixo de 10 segundos), sem precisar consultar a API de pedidos repetidamente (src: [09:00] Marcos; [09:02] Marcos).

O escopo é somente envio da plataforma para o cliente. Não há fluxo de entrada (inbound) (src: [09:02] Marcos; [09:03] Sofia).

Prazo estimado: 3 sprints, incluindo a revisão de segurança de pelo menos 2 dias úteis antes do deploy (src: [09:46] Larissa; [09:46] Sofia). A Atlas Comercial espera a entrega até o fim de novembro (src: [09:45] Marcos).

## 2. Problema e motivação

Três clientes B2B (Atlas Comercial, MaxDistribuição e Nova Cargo) pediram formalmente para ser notificados quando o status dos seus pedidos muda. Hoje consultam `GET /orders` de tempos em tempos, o que deixa a integração lenta e cara para eles (src: [09:00] Marcos).

Há risco comercial explícito: a Atlas sugeriu que pode migrar para o concorrente se a entrega não ocorrer a tempo (src: [09:00] Marcos).

Do lado técnico, a transação de mudança de status já é pesada (atualiza o pedido, grava histórico e baixa estoque). Chamar o cliente dentro dela travaria a mudança de status de outros pedidos quando um cliente estivesse lento ou fora do ar (src: [09:04] Bruno). A solução precisa, portanto, desacoplar a notificação da operação principal sem perder eventos.

## 3. Público-alvo e cenários de uso

**Público-alvo**
- Clientes B2B integradores (Atlas Comercial, MaxDistribuição, Nova Cargo), representados por usuários autenticados na API da plataforma (src: [09:00] Marcos; [09:32] Marcos).
- Operadores com role `ADMIN`, que reprocessam entregas que falharam definitivamente (src: [09:36] Sofia).
- Times internos de produto e suporte, que documentam a integração no portal de desenvolvedor e apoiam os clientes (src: [09:26] Marcos; [09:40] Marcos).

**Cenários de uso**
1. O cliente cadastra um webhook com URL HTTPS e os status de interesse (por exemplo, apenas `SHIPPED` e `DELIVERED`) e passa a receber só esses eventos (src: [09:31] Marcos; [09:33] Marcos).
2. O pedido muda de status e o cliente recebe a notificação em menos de 10 segundos (src: [09:02] Marcos).
3. O servidor do cliente fica indisponível por algumas horas (por exemplo, manutenção planejada de 2 horas) e a plataforma tenta de novo ao longo de cerca de 15 horas, sem perder o evento (src: [09:16] Diego; [09:17] Diego).
4. O cliente investiga um problema consultando as últimas 100 entregas, com resultado, resposta e tempo de resposta (src: [09:34] Marcos).
5. O cliente suspeita de vazamento de secret e a rotaciona, mantendo a antiga válida por 24 horas para migrar seus sistemas (src: [09:21] Sofia; [09:22] Diego).
6. Um evento esgota as tentativas e um `ADMIN` o reprocessa manualmente (src: [09:18] Diego; [09:36] Sofia).

## 4. Objetivos e métricas de sucesso

| ID | Objetivo | Métrica | Meta | Origem |
|---|---|---|---|---|
| **PRD-OBJ-01** | Notificar o cliente em "tempo real" | Tempo entre a mudança de status e a entrega do evento ao cliente | Menos de 10 segundos (latência mínima de até 2 segundos pelo polling) | (src: [09:02] Marcos; [09:10] Larissa) |
| **PRD-OBJ-02** | Nunca perder nem gerar evento fantasma | Pedidos com status alterado sem evento correspondente (considerando filtro do cliente) e eventos sem alteração de status confirmada | 0 ocorrências [PROPOSTA] | (src: [09:40] Bruno; [09:41] Diego) |
| **PRD-OBJ-03** | Tolerar indisponibilidade do cliente | Janela de retentativas antes de a falha ser considerada definitiva | Cerca de 15 horas, em 5 tentativas | (src: [09:17] Diego) |
| **PRD-OBJ-04** | Reduzir o polling dos clientes sobre `GET /orders` | Adoção dos webhooks pelos 3 clientes solicitantes | 3 de 3 clientes integrados após o lançamento [PROPOSTA] | (src: [09:00] Marcos) |

## 5. Escopo

### Incluso
- Cadastro, edição, remoção e listagem de webhooks por cliente, com URL HTTPS e filtro de status (src: [09:31] Marcos; [09:33] Bruno).
- Geração de evento na mudança de status do pedido, de forma atômica com a mudança (src: [09:40] Bruno).
- Entrega assinada por HMAC-SHA256, com secret por endpoint e rotação (src: [09:22] Sofia).
- Retentativas com backoff, DLQ e reprocessamento manual por `ADMIN` (src: [09:17] Larissa; [09:18] Diego).
- Consulta das últimas 100 entregas por webhook (src: [09:34] Marcos).

### Fora de escopo
- **PRD-OUT-01** Dashboard/painel visual no frontend para configuração de webhooks (DESCARTADO): é projeto separado do time de frontend; clientes usam apenas a API (src: [09:40] Larissa; [09:39] Marcos).
- **PRD-OUT-02** Notificação por e-mail ao cliente após 3 falhas consecutivas (ADIADO): fora desta fase, a reavaliar depois de medir o impacto (src: [09:37] Larissa; [09:38] Marcos).
- **PRD-OUT-03** Arquivamento automático das entregas da outbox após cerca de 30 dias (ADIADO): fora do escopo desta feature (src: [09:08] Diego).
- **PRD-OUT-04** Múltiplos workers em paralelo, com particionamento por pedido ou lock pessimista (ADIADO): problema do futuro; por ora, um único worker (src: [09:13] Diego).
- **PRD-OUT-05** Rate limiting de envio por cliente (ADIADO, ponto em aberto): observar o comportamento após o lançamento e decidir depois (src: [09:39] Larissa; [09:39] Diego).
- **PRD-OUT-06** Fluxo inbound, em que o cliente envia webhooks para a plataforma (DESCARTADO): os clientes só querem receber (src: [09:02] Marcos).
- **PRD-OUT-07** Garantia de ordenação global e entrega exactly-once (DESCARTADO): a ordenação vale só por pedido e com um único worker; exactly-once exigiria coordenação dos dois lados (src: [09:13] Larissa; [09:25] Diego).

## 6. Requisitos funcionais

### PRD-FR-01: Cadastro e gestão de webhooks por cliente
- O cliente cadastra, edita, remove e lista os webhooks de um customer pela API, autenticado. O identificador do cliente é informado na requisição, pois o login identifica o operador e não o cliente (src: [09:31] Marcos; [09:33] Bruno; [09:32] Larissa).
- A URL deve ser HTTPS; URLs HTTP são recusadas com erro de validação (src: [09:23] Sofia).

### PRD-FR-02: Filtro por status de interesse
- Cada webhook define a lista de status que deseja ouvir. Se nenhum webhook do cliente quer o novo status, o evento nem é gerado (src: [09:33] Marcos; [09:34] Bruno).

### PRD-FR-03: Evento gerado na mudança de status, sem perda
- Toda mudança de status elegível gera um evento gravado na mesma transação da mudança. Se a gravação do evento falhar, a mudança de status é desfeita; se a mudança for desfeita, o evento não existe (src: [09:06] Diego; [09:40] Bruno; [09:41] Diego).
- O conteúdo do evento é um retrato do pedido no momento da mudança, imune a alterações posteriores (src: [09:52] Larissa; [09:52] Diego).

### PRD-FR-04: Entrega assíncrona e ordenada por pedido
- A entrega ocorre fora da operação de mudança de status, por um processo separado da API, com verificação a cada 2 segundos (src: [09:09] Diego; [09:11] Diego).
- Eventos do mesmo pedido são entregues na ordem em que ocorreram, enquanto houver um único worker (src: [09:12] Diego; [09:13] Larissa).

### PRD-FR-05: Conteúdo da notificação
- O evento é um JSON enxuto com identificador do evento, tipo `order.status_changed`, data/hora, identificador e número do pedido, status anterior e novo, cliente e valor total. A lista de itens não é enviada; o cliente consulta o pedido se precisar (src: [09:43] Diego; [09:44] Bruno).
- A requisição leva cabeçalhos de identificação do evento, assinatura, data/hora do envio e identificação do webhook (src: [09:44] Diego; [09:44] Sofia; [09:45] Diego).

### PRD-FR-06: Assinatura e secret por endpoint
- Cada notificação é assinada com HMAC-SHA256 para que o cliente confirme a origem e a integridade (src: [09:20] Sofia).
- Cada webhook tem sua própria secret, gerada pela plataforma e devolvida na criação (src: [09:21] Sofia; [09:31] Marcos).

### PRD-FR-07: Rotação de secret com transição
- O cliente pode pedir nova secret pela API; a anterior continua válida por 24 horas para dar tempo de migração (src: [09:21] Sofia; [09:22] Sofia).

### PRD-FR-08: Retentativas com backoff e DLQ
- Em caso de falha (inclusive tempo limite de 10 segundos), há 5 tentativas com intervalos crescentes de 1 minuto, 5 minutos, 30 minutos, 2 horas e 12 horas (src: [09:17] Larissa; [09:42] Diego).
- Esgotadas as tentativas, o evento vai para uma área de falhas definitivas (DLQ), com o conteúdo original, o motivo da falha e a data/hora (src: [09:18] Diego).

### PRD-FR-09: Reprocessamento manual de falhas definitivas
- Um usuário `ADMIN` pode recolocar na fila de entrega um evento da DLQ. A ação registra quem a executou, para auditoria (src: [09:18] Diego; [09:36] Sofia; [09:36] Larissa).

### PRD-FR-10: Histórico das últimas 100 entregas
- O cliente consulta as últimas 100 entregas de um webhook, com sucesso ou falha, conteúdo enviado, resposta recebida e tempo de resposta (src: [09:34] Marcos).

### PRD-FR-11: Autorização
- Cadastro, edição, remoção, listagem, rotação e consulta de entregas aceitam qualquer role autenticada nesta fase; o reprocessamento exige `ADMIN` (src: [09:36] Larissa; [09:37] Sofia).

### PRD-FR-12: Limite de tamanho do evento
- Eventos acima de 64KB não são enviados e geram erro explícito, sem truncar o conteúdo (src: [09:23] Sofia; [09:24] Larissa).

## 7. Requisitos não funcionais

- **PRD-NFR-01** Latência: notificação abaixo de 10 segundos, com polling de 2 segundos (src: [09:02] Marcos; [09:10] Larissa).
- **PRD-NFR-02** Garantia de entrega: pelo menos uma vez (at-least-once); o cliente deduplica pelo identificador do evento enviado em cabeçalho (src: [09:24] Diego; [09:25] Diego).
- **PRD-NFR-03** Segurança em trânsito: somente HTTPS, com assinatura HMAC-SHA256 e secret por endpoint (src: [09:20] Sofia; [09:23] Sofia).
- **PRD-NFR-04** Isolamento: a entrega não pode degradar nem bloquear a mudança de status de pedidos, e reiniciar a API não interrompe o worker (src: [09:04] Bruno; [09:11] Diego).
- **PRD-NFR-05** Resiliência: tempo limite de 10 segundos por chamada ao cliente; falha de rede tratada como falha de entrega e enviada ao backoff (src: [09:42] Diego).
- **PRD-NFR-06** Desempenho da fila: consultas do worker apoiadas em índices por status e data de criação (src: [09:08] Diego).
- **PRD-NFR-07** Consistência com o projeto: reuso dos padrões existentes (módulo por domínio, erros com prefixo `WEBHOOK_`, logger Pino, tratamento centralizado de erros, validação Zod, identificadores UUID) (src: [09:27] Bruno; [09:29] Larissa; [09:30] Larissa; [09:51] Larissa).
- **PRD-NFR-08** Auditabilidade: replay registra o autor em log (src: [09:36] Sofia).

## 8. Decisões e trade-offs principais

- **Outbox transacional no MySQL em vez de envio síncrono ou Redis.** Garante consistência e evita nova infraestrutura; o custo é que a tabela cresce e exige arquivamento futuro. Detalhes em [ADR-001](adrs/ADR-001-outbox-transacional-no-mysql.md).
- **Retry com backoff exponencial em 5 tentativas e DLQ.** Cobre indisponibilidades longas (cerca de 15 horas) sem prender o worker como retries infinitos; o custo é que falhas além da janela exigem replay manual. Detalhes em [ADR-002](adrs/ADR-002-retry-backoff-exponencial-e-dlq.md).
- **HMAC-SHA256 com secret por endpoint e rotação de 24h.** Limita o dano de um vazamento a um endpoint; o custo é a gestão de secrets pelo cliente. Detalhes em [ADR-003](adrs/ADR-003-autenticacao-hmac-sha256-secret-por-endpoint.md).
- **Entrega at-least-once com identificador de evento.** Evita a complexidade do exactly-once; o custo é transferir a deduplicação ao cliente, que será orientado no portal de desenvolvedor. Detalhes em [ADR-004](adrs/ADR-004-entrega-at-least-once-com-x-event-id.md).
- **Worker em processo separado, com polling de 2s e instância única.** Simples e robusto a reinícios da API; o custo é latência mínima de até 2 segundos e ordenação garantida só por pedido enquanto houver um worker. Detalhes em [ADR-005](adrs/ADR-005-worker-separado-com-polling.md).
- **Reuso dos padrões do projeto.** Menos código novo e curva de aprendizado menor; o custo é herdar as limitações dos padrões atuais. Detalhes em [ADR-006](adrs/ADR-006-reuso-dos-padroes-do-projeto.md).

## 9. Dependências

- Fluxo de mudança de status de pedidos, onde o evento é gerado de forma transacional (src: [09:40] Bruno).
- Banco MySQL existente, que hospeda a fila de eventos e a DLQ (src: [09:07] Diego).
- Autenticação por JWT e controle de role (`ADMIN`) já existentes (src: [09:32] Marcos; [09:36] Larissa).
- Disponibilidade de um processo Node separado para o worker, com a mesma base e stack da API (src: [09:11] Diego).
- Revisão de segurança de pelo menos 2 dias úteis, agendada com Sofia antes do deploy (src: [09:46] Sofia; [09:49] Sofia).
- Documentação no portal de desenvolvedor, a cargo do produto (deduplicação, integração via API) (src: [09:26] Marcos; [09:40] Marcos).
- Confirmação do prazo com a Atlas Comercial (src: [09:47] Marcos).

## 10. Riscos e mitigação

Probabilidade e impacto abaixo são julgamento do redator [PROPOSTA], com base nos fatos da reunião.

| ID | Risco | Probabilidade | Impacto | Mitigação | Origem |
|---|---|---|---|---|---|
| **PRD-RISCO-01** | Rajada de eventos sobrecarrega o servidor do cliente (ex.: 50 pedidos mudando de status em 1 minuto) [PROPOSTA] | Média | Médio | Rate limiting adiado de propósito; observar o comportamento após o lançamento e decidir depois | (src: [09:38] Diego; [09:39] Larissa) |
| **PRD-RISCO-02** | Ordenação perdida se for adotado mais de um worker [PROPOSTA] | Baixa | Alto | Manter worker único; documentar a limitação como conhecida; particionar por pedido só em fase futura | (src: [09:12] Diego; [09:13] Larissa) |
| **PRD-RISCO-03** | Crescimento da tabela de eventos sem arquivamento degrada o desempenho [PROPOSTA] | Média | Médio | Índices por status e data de criação; planejar o arquivamento adiado em fase seguinte | (src: [09:07] Bruno; [09:08] Diego) |
| **PRD-RISCO-04** | Cliente indisponível além da janela de cerca de 15 horas perde a entrega automática [PROPOSTA] | Baixa | Médio | Evento preservado na DLQ; replay manual por `ADMIN`; histórico de entregas para diagnóstico | (src: [09:17] Marcos; [09:18] Diego) |
| **PRD-RISCO-05** | Vazamento de secret pelo cliente (já ocorreu antes) [PROPOSTA] | Média | Alto | Secret por endpoint limita o alcance; rotação com transição de 24h; revisão de segurança antes do deploy | (src: [09:22] Diego; [09:21] Sofia) |
| **PRD-RISCO-06** | Cliente processa eventos duplicados por não deduplicar [PROPOSTA] | Média | Médio | Identificador de evento em cabeçalho; orientação destacada no portal de desenvolvedor | (src: [09:25] Sofia; [09:26] Marcos) |
| **PRD-RISCO-07** | Prazo de 3 sprints pressionado pela data esperada pela Atlas [PROPOSTA] | Média | Alto | Escopo enxuto, com itens adiados fora da entrega; revisão de segurança reservada no fim do cronograma | (src: [09:45] Marcos; [09:46] Larissa) |

## 11. Critérios de aceitação

- **PRD-AC-01** Dado um webhook ativo para o status novo, quando o status do pedido mudar, então o cliente recebe a notificação em menos de 10 segundos (src: [09:02] Marcos).
- **PRD-AC-02** Dado um webhook que não inclui o novo status, quando o status mudar, então nenhum evento é gerado para ele (src: [09:34] Bruno).
- **PRD-AC-03** Dada uma falha na gravação do evento, quando o status do pedido mudar, então a mudança é desfeita (src: [09:40] Bruno).
- **PRD-AC-04** Dada uma URL HTTP no cadastro, então o sistema recusa com erro de validação (src: [09:23] Sofia).
- **PRD-AC-05** Dada uma notificação enviada, então ela carrega assinatura HMAC-SHA256 válida calculada com a secret do endpoint (src: [09:20] Sofia; [09:22] Sofia).
- **PRD-AC-06** Dada uma rotação de secret, então a anterior continua válida por 24 horas e depois deixa de valer (src: [09:21] Sofia).
- **PRD-AC-07** Dado um cliente que não responde, então ocorrem 5 tentativas nos intervalos definidos e, ao esgotá-las, o evento vai para a DLQ (src: [09:17] Larissa; [09:18] Diego).
- **PRD-AC-08** Dada uma chamada que excede 10 segundos, então ela é tratada como falha e reagendada (src: [09:42] Diego).
- **PRD-AC-09** Dado um evento na DLQ, quando um `ADMIN` o reprocessar, então ele volta à fila e a ação fica registrada em log; um usuário sem `ADMIN` é recusado (src: [09:36] Larissa; [09:36] Sofia).
- **PRD-AC-10** Dado um webhook, então o cliente lista as últimas 100 entregas com resultado, resposta e tempo (src: [09:34] Marcos).
- **PRD-AC-11** Dado um evento acima de 64KB, então ele não é enviado e gera erro explícito (src: [09:23] Sofia; [09:24] Larissa).
- **PRD-AC-12** Dados vários eventos do mesmo pedido, então chegam na ordem de criação (src: [09:12] Diego).

## 12. Estratégia de testes e validação

A reunião previu testes ponta a ponta junto da integração em pedidos (src: [09:46] Larissa) e revisão de segurança dedicada (src: [09:46] Sofia). O desenho abaixo detalha esses pontos [PROPOSTA] (src: [09:46] Larissa).

- **Testes de unidade** [PROPOSTA]: filtro por status, validação de URL HTTPS e limite de 64KB, cálculo da assinatura, janela de transição da secret, cálculo dos intervalos de retentativa.
- **Testes de integração** [PROPOSTA]: atomicidade entre mudança de status e gravação do evento (incluindo rollback), ordenação por pedido, passagem para a DLQ e replay com e sem role `ADMIN`.
- **Testes ponta a ponta** [PROPOSTA]: fluxo completo contra um servidor de cliente simulado, cobrindo sucesso, lentidão acima de 10 segundos e indisponibilidade (src: [09:46] Larissa).
- **Validação de segurança**: auditoria de pelo menos 2 dias úteis sobre HMAC, geração de secret e rotação, antes do deploy (src: [09:46] Sofia; [09:49] Sofia).
- **Validação de aceite**: cada PRD-AC é verificado antes do lançamento; a meta de 10 segundos é medida em ambiente de homologação [PROPOSTA] (src: [09:10] Larissa).
- **Pós-lançamento**: observar o volume de envios por cliente para decidir sobre rate limiting (src: [09:39] Larissa).
