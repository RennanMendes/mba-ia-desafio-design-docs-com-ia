# Desafio Design Docs com IA: Webhooks de Notificação de Pedidos (OMS)

Entrega 100% documental (Markdown). **Nunca editar** `src/`, `prisma/`, `tests/`, configs nem `TRANSCRICAO.md`.
Enunciado: `desafio.md`. Estratégia: `docs/auxiliar/estrategia-execucao.md`. **Para executar: seguir `docs/auxiliar/orquestracao.md`** (você é o orquestrador).

## Papel desta sessão
Orquestrar subagentes definidos em `.claude/agents/*.md` (um por documento, cada um com modelo próprio). Não redigir os documentos aqui. Disparar agentes independentes na mesma mensagem (paralelo), nunca repassar o raciocínio de um agente a outro, consolidar RELATOs em `docs/auxiliar/relatorio-revisao-humana.md` e parar para revisão humana. Sem commit/push a menos que o usuário peça.

## Fontes (ordem de autoridade)
1. `TRANSCRICAO.md`: verificação pontual por `Grep "^\[09:2" TRANSCRICAO.md`; não reler inteira (exceto o revisor independente).
2. `docs/auxiliar/fatos-reuniao.md`: decisões, descartes, adiados com `[hh:mm] Nome`.
3. `docs/auxiliar/contexto-codigo.md`: fatos do código (gerado na onda 0).
4. `docs/auxiliar/contrato-compartilhado.md`: IDs, nomes de ADR, marcadores, fronteiras entre documentos.
5. Curso (somente templates, sob demanda): `D:\_development\01-Cursos\FullCycle\Resumo das aulas\mba-fullcycle-ai-resume\07 - Design Docs com IA\agents.md`.

## Regras de conteúdo
- Zero invenção: todo item com `(src: [hh:mm] Nome)` ou `(src: caminho)`. Sem origem: remover, `[PROPOSTA]` (com decisão de origem) ou `[NEEDS INPUT: pergunta]`.
- DESCARTADO/ADIADO/QUESTÃO ABERTA só em Fora de escopo, Alternativas ou Questões em aberto.
- Critério do desafio: nenhum arquivo de código mencionado pode ser inexistente. Código novo (worker, módulo webhooks, `npm run worker`) é descrito por nome lógico, nunca por caminho completo.
- Escopo estrito: só o que o `desafio.md` pede (6 ADRs, sem seções ou arquivos extras). O README da raiz é substituído (requisito 6) só pelo `redator-readme`.
- Sem duplicação: PRD (por quê/o quê), RFC (proposta, 2 a 4 págs), ADR (1 decisão), FDD (como construir). Linkar em vez de copiar.
- Português, sem travessão longo, sem emojis.

## Economia de tokens
- `Grep -n -C` e `Read` com offset/limit; nunca arquivo grande inteiro sem necessidade; buscas independentes em paralelo.
- `Edit` cirúrgico; `Write` só para criar.
- Validação mecânica com `bash docs/auxiliar/validar-entrega.sh wave1|full` (zero tokens de modelo) em vez de reler documentos.
- Respostas curtas, sem preâmbulo nem resumo do que o diff já mostra.

## Modelos
Haiku: investigador-codigo · Sonnet: PRD, ADRs, Tracker, README · Opus: RFC, FDD, revisor-independente. Detalhes em `docs/auxiliar/estrategia-execucao.md`.
