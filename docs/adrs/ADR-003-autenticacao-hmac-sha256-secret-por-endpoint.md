---
status: aceito
date: 2026-11-15
tags: [webhooks, seguranca, hmac]
---

# ADR-003: Autenticação das entregas com HMAC-SHA256 e secret por endpoint

ID: **ADR-003**

## Status
Aceito (decidido na reunião técnica) (src: [09:22] Sofia)

## Contexto
Os eventos carregam dados de pedidos para um endpoint fora da infraestrutura da empresa. O cliente precisa validar que a requisição veio de fato do OMS e que o payload não foi adulterado (src: [09:19] Sofia). Já houve cliente que vazou uma secret em log da própria aplicação (src: [09:22] Diego).

## Decisão
Assinar o corpo da requisição com HMAC-SHA256 usando uma secret compartilhada e enviar a assinatura no header `X-Signature` (src: [09:20] Sofia; [09:20] Bruno). Cada endpoint de webhook tem sua própria secret, não uma secret global da plataforma (src: [09:21] Sofia). A secret é rotacionável pela API: ao rotacionar, a antiga continua válida por 24 horas em paralelo e depois deixa de valer (src: [09:21] Sofia; [09:22] Sofia).

## Alternativas Consideradas
### ADR-003-ALT-01: Secret global da plataforma
- Descrição: uma única secret para todos os endpoints e clientes.
- Prós e contras: gestão mais simples, mas o vazamento de uma secret compromete todas as integrações.
- Motivo do descarte: "senão se vaza uma, vaza tudo" (src: [09:21] Sofia)

### ADR-003-ALT-02: Rotação sem período de transição
- Descrição: a secret antiga deixa de valer imediatamente ao rotacionar. [PLAUSÍVEL, não discutida na reunião]
- Prós e contras: janela de exposição menor, mas o cliente não teria tempo de migrar seus sistemas.
- Motivo do descarte: o grace period de 24 horas existe para o cliente ter tempo de migrar (src: [09:21] Sofia)

## Consequências
### Positivas
- Autenticidade e integridade verificáveis pelo cliente com bibliotecas de mercado (src: [09:20] Sofia).
- Vazamento de uma secret compromete apenas o endpoint dela (src: [09:21] Sofia).
- Rotação sem rejeição de notificações durante a migração do cliente (src: [09:21] Sofia).

### Negativas
- Durante 24 horas após a rotação, duas secrets são válidas ao mesmo tempo, o que amplia a exposição nesse período.
- Há mais secrets para gerar, armazenar e rotacionar, uma por endpoint.
- O código de geração de secret e rotação exige revisão de segurança dedicada antes do deploy (src: [09:46] Sofia).

### Trade-off explícito
O time aceitou mais complexidade de gestão (uma secret por endpoint e rotação com período de transição) em troca de menor raio de impacto em vazamentos e de migração sem perda de notificações (src: [09:21] Sofia).

## Referências
- `../RFC.md` e `../FDD.md`
- ADR-004-entrega-at-least-once-com-x-event-id.md
