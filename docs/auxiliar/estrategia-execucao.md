# Estratégia de Execução: pacote de Design Docs (Webhooks OMS)

Objetivo: entregar PRD, RFC, FDD, 6 ADRs, TRACKER e README cumprindo todos os critérios de `desafio.md`, com custo mínimo de tokens e zero alucinação. Execução operacional: `orquestracao.md`.

## 1. Arquitetura da solução (multiagente isolado)
- **Orquestrador** (sessão principal): governa estado, dispara agentes, roda o gate mecânico, consolida relatos. Não redige documentos (aula "Role Specification como Orquestrador").
- **Subagentes especialistas**, cada um com prompt estruturado (persona/escopo, objetivo, entradas, formato de saída, critérios, ambiguidades, instruções negativas, tratamento de erro, conforme as aulas "Estruturação de Prompts" e "Regras de ouro"), com metadados declarativos (nome, descrição, modelo, ferramentas) em `.claude/agents/*.md` (aula "Arquivo declarativo do Agent").
- **Isolamento de contexto**: agentes de redação só recebem o próprio prompt e as entradas listadas. Não veem o raciocínio, os relatos nem a saída uns dos outros. O único acoplamento é `contrato-compartilhado.md` (IDs, nomes de ADRs, marcadores, fronteiras).
- **Revisor independente** na última onda: não lê auxiliares nem prompts; audita contra enunciado, transcrição e código.
- **Gate mecânico sem modelo**: `validar-entrega.sh` (grep/ls) verifica estrutura e contagens do desafio a custo zero de tokens. Cada agente o roda no modo do seu documento (autoverificação) antes de reportar; o orquestrador o roda em `wave1` e `full`.
- **Canal de erros e dúvidas**: todo agente termina com o bloco `RELATO`; só o orquestrador consolida em `relatorio-revisao-humana.md`. Ninguém pergunta ao usuário durante a execução.

## 2. Ordem do pacote e ondas
Ordem lógica: **PRD, RFC, FDD, ADRs, Tracker** (README e revisão ao final).

| Onda | Conteúdo | Execução |
|---|---|---|
| 0 | investigador-codigo gera `contexto-codigo.md` | sequencial |
| 1 | PRD, RFC, FDD, ADRs | 4 agentes em paralelo |
| gate | `validar-entrega.sh wave1` | script |
| 2 | Tracker e README | 2 agentes em paralelo |
| gate | `validar-entrega.sh full` | script |
| 3 | revisor-independente | 1 agente |
| fim | relatório para revisão humana | orquestrador |

Por que a onda 1 é paralela sem dependência de saída: PRD/RFC/FDD/ADRs derivam todos de `fatos-reuniao.md`; o contrato fixa nomes de ADR, IDs e fronteiras, então RFC e FDD podem linkar ADRs que ainda estão sendo escritos. O Tracker depende dos IDs e das origens `(src: ...)` já escritos nos documentos, por isso fica depois.

## 3. Roteamento de modelos
| Agente | Modelo | Justificativa |
|---|---|---|
| investigador-codigo | Haiku 5.5 | extração mecânica e curta |
| redator-prd | Sonnet 5.5 | síntese de produto a partir de fatos prontos |
| redator-rfc | Opus 5.5 | síntese arquitetural concisa, fronteira com FDD e ADRs |
| redator-fdd | Opus 5.5 | maior exigência técnica: contratos, erros, integração com código real |
| redator-adrs | Sonnet 5.5 | 7 textos padronizados, decisões já fechadas |
| gerador-tracker | Sonnet 5.5 | tabulação extensa com verificação em fonte |
| redator-readme | Sonnet 5.5 | narrativa a partir de log factual |
| revisor-independente | Opus 5.5 | único passe de alto raciocínio; Fable 5.2 só por pedido humano |
| orquestrador | modelo da sessão (Sonnet 5.5) | governança, sem raciocínio profundo |

## 4. Diagnóstico e riscos (insumo para os prompts)
| Ponto | Tratamento |
|---|---|
| `fatos-reuniao.md` consolida a transcrição (~6k tokens evitados) | agentes leem os fatos e usam `Grep` na transcrição só para confirmar |
| Código não tem worker, outbox nem módulo webhooks | código novo é descrito por nome lógico, sem caminho completo (critério "nenhum arquivo mencionado é inexistente"); o gate acusa qualquer caminho inexistente |
| Fatos x transcrição divergem no pool do Prisma do worker | contrato: vale a transcrição ([09:30] Bruno) |
| Lacunas (colunas, status da outbox, secret storage, códigos WEBHOOK_, métricas) | `[PROPOSTA]` com decisão de origem, nunca como decisão da reunião |
| Descartados/adiados virando requisito | contrato seção 6 + instruções negativas + checagem do revisor |
| Stubs de `docs/*.md` exigem `Read` antes do `Write` | cada prompt instrui a ler o stub |
| README exige iterações reais | só vêm do `log-processo.md`; se faltar, `[NEEDS INPUT]` para o humano |
| Escopo estrito: fazer só o que o desafio pede | contrato seção 0; mínimos do desafio são pisos; sem seções, ADRs ou arquivos extras; revisor classifica `EXCESSO` |
| Critérios de aceite do desafio embutidos | cada prompt traz requisito e critérios literais, checklist A/B/C/D/E/F/G e autoverificação por `validar-entrega.sh <modo>` (até 3 ciclos) |

## 5. Artefatos desta estratégia
| Arquivo | Função |
|---|---|
| `docs/auxiliar/orquestracao.md` | runbook do orquestrador |
| `docs/auxiliar/contrato-compartilhado.md` | acoplamento entre agentes paralelos |
| `docs/auxiliar/validar-entrega.sh` | gate mecânico |
| `.claude/agents/*.md` (8) | prompts e metadados de cada agente |
| `docs/auxiliar/fatos-reuniao.md` | fonte consolidada da reunião |
| (gerados na execução) `contexto-codigo.md`, `log-processo.md`, `relatorio-revisao-humana.md` | estado e saída |

## 6. Orçamento de contexto (estimado)
Cada agente de redação lê contrato (~2k) + fatos (~4k) + contexto-código (~1,5k) e confirma por `Grep`. Transcrição integral (~6k) só no revisor. Orquestrador não lê documentos. O custo dominante é a saída de PRD/RFC/FDD/ADRs/Tracker, inevitável.

## 7. Checklist de aceite
O gate (`wave1` e `full`) cobre: arquivos e seções, ≥8 RFs, ≥2 fora de escopo e riscos, RFC com ≥2 ADRs linkados e 2 alternativas/questões, FDD com ≥4 endpoints, `WEBHOOK_`, ≥4 caminhos reais, métricas/logs/tracing, 5 a 8 ADRs com 5 seções, Tracker (formato, 80% cobertura, 70% TRANSCRICAO válida, 5 CODIGO), README (6 seções, 2 blocos de código) e código intacto. O revisor cobre o que é semântico (contradição, invenção, descartados, duplicação).
