#!/usr/bin/env bash
# Validação mecânica (zero tokens de modelo) dos critérios de aceite do desafio.md.
# Uso: bash docs/auxiliar/validar-entrega.sh <modo>
#   modos: prd | rfc | fdd | adrs | tracker | readme | wave1 (prd+rfc+fdd+adrs+links cruzados) | full (tudo)
# Cada modo lê SOMENTE os arquivos do seu documento. Saída: OK / FALHA / AVISO. Exit 1 se houver FALHA.
cd "$(git rev-parse --show-toplevel)" || exit 2
MODE=${1:-full}; FAIL=0; WARN=0
ok(){ echo "OK     $*"; }
bad(){ echo "FALHA  $*"; FAIL=$((FAIL+1)); }
warn(){ echo "AVISO  $*"; WARN=$((WARN+1)); }
has(){ grep -qiE "^#+ .*($2)" "$1" || bad "$1 sem seção: $2"; }
cnt(){ grep -ohE "$2" "$1" 2>/dev/null | sort -u | wc -l; }
ADRS="ADR-001-outbox-transacional-no-mysql ADR-002-retry-backoff-exponencial-e-dlq ADR-003-autenticacao-hmac-sha256-secret-por-endpoint ADR-004-entrega-at-least-once-com-x-event-id ADR-005-worker-separado-com-polling ADR-006-reuso-dos-padroes-do-projeto"
exists(){ [ -f "$1" ] && [ "$(wc -c <"$1")" -gt 1500 ] && ok "$1 existe" || { bad "$1 ausente ou stub"; return 1; }; }

# Critério de consistência: nenhum arquivo de código citado pode ser inexistente
paths_check(){ for p in $(grep -ohE "(src|prisma|tests)/[A-Za-z0-9_./-]+\.(ts|prisma|sql|json)" "$@" 2>/dev/null | sort -u); do [ -f "$p" ] || bad "caminho de código inexistente citado: $p (descrever por nome lógico)"; done; }

check_prd(){ exists docs/PRD.md || return
  for s in "Resumo" "Problema" "P.blico" "Objetivos" "Escopo" "Requisitos funcionais" "Requisitos n.o funcionais" "Decis.es" "Depend.ncias" "Riscos" "Crit.rios de aceita" "testes"; do has docs/PRD.md "$s"; done
  n=$(cnt docs/PRD.md "PRD-FR-[0-9]{2}"); [ "$n" -ge 8 ] && ok "PRD: $n RFs" || bad "PRD: $n RFs (min 8)"
  grep -qiE "fora de escopo" docs/PRD.md && ok "PRD: seção Fora de escopo" || bad "PRD sem Fora de escopo"
  n=$(cnt docs/PRD.md "PRD-OUT-[0-9]{2}"); [ "$n" -ge 2 ] && ok "PRD: $n itens fora de escopo" || bad "PRD: $n fora de escopo (min 2)"
  n=$(cnt docs/PRD.md "PRD-RISCO-[0-9]{2}"); [ "$n" -ge 2 ] && ok "PRD: $n riscos" || bad "PRD: $n riscos (min 2)"
  grep -qiE "probabilidade" docs/PRD.md && grep -qiE "impacto" docs/PRD.md && grep -qiE "mitiga" docs/PRD.md || bad "PRD riscos sem probabilidade/impacto/mitigação"
  grep -E "PRD-OBJ-[0-9]{2}" docs/PRD.md | grep -qE "[0-9]" && ok "PRD: objetivo com meta numérica" || bad "PRD sem objetivo com métrica e meta quantitativa"
  grep -qE "—" docs/PRD.md && warn "PRD contém travessão longo"
  paths_check docs/PRD.md; }

check_rfc(){ exists docs/RFC.md || return
  for s in "Resumo|TL;DR" "Contexto" "Proposta" "Alternativas" "Quest.es em aberto" "Impacto" "Decis.es relacionadas"; do has docs/RFC.md "$s"; done
  for m in "Autor" "Status" "Data" "Revisores"; do grep -qiE "$m" docs/RFC.md || bad "RFC sem metadado: $m"; done
  for p in Larissa Marcos Bruno Diego Sofia; do grep -q "$p" docs/RFC.md || bad "RFC: revisor ausente: $p"; done
  w=$(wc -w <docs/RFC.md); { [ "$w" -ge 600 ] && [ "$w" -le 2200 ]; } && ok "RFC: $w palavras (2 a 4 páginas)" || warn "RFC com $w palavras (esperado ~2 a 4 páginas)"
  n=0; for l in $(grep -oE "adrs/ADR-[0-9]{3}-[a-z0-9-]+\.md" docs/RFC.md | sort -u); do
    nm=$(basename "$l" .md); echo "$ADRS" | grep -qw "$nm" && n=$((n+1)) || bad "RFC link para ADR fora do mapa: $l"
    if [ "$MODE" != rfc ]; then [ -f "docs/$l" ] || bad "RFC link quebrado: $l"; fi; done
  [ "$n" -ge 2 ] && ok "RFC: $n links de ADR" || bad "RFC: $n links de ADR (min 2)"
  n=$(cnt docs/RFC.md "RFC-ALT-[0-9]{2}"); [ "$n" -ge 2 ] && ok "RFC: $n alternativas" || bad "RFC: $n alternativas (min 2)"
  n=$(cnt docs/RFC.md "RFC-ABERTA-[0-9]{2}"); [ "$n" -ge 2 ] && ok "RFC: $n questões abertas" || bad "RFC: $n questões abertas (min 2)"
  grep -qE "—" docs/RFC.md && warn "RFC contém travessão longo"
  paths_check docs/RFC.md; }

check_fdd(){ exists docs/FDD.md || return
  for s in "Contexto" "Objetivos t.cnicos" "Escopo" "Fluxos" "Contratos p.blicos" "Matriz de erros" "Estrat.gias de resili.ncia" "Observabilidade" "Depend.ncias" "Crit.rios de aceite" "Riscos" "Integra..o com o sistema existente"; do has docs/FDD.md "$s"; done
  grep -q "WEBHOOK_" docs/FDD.md && ok "FDD: usa WEBHOOK_" || bad "FDD sem códigos WEBHOOK_"
  n=$(grep -oE "\b[A-Z][A-Z0-9]+(_[A-Z0-9]+)+\b" docs/FDD.md | grep -E "^[A-Z]+_" | grep -E "^(ERR|ERROR|WH)_" | sort -u | wc -l); [ "$n" -gt 0 ] && warn "FDD: códigos de erro fora do padrão WEBHOOK_"
  n=$(grep -oE "(GET|POST|PUT|PATCH|DELETE) /[A-Za-z0-9_/:.-]+" docs/FDD.md | sort -u | wc -l); [ "$n" -ge 4 ] && ok "FDD: $n endpoints" || bad "FDD: $n endpoints (min 4)"
  grep -qiE "\"?status\"?|status code|HTTP 2|HTTP 4|20[0-9] |40[0-9] " docs/FDD.md || bad "FDD sem status codes"
  [ "$(grep -c '^```json' docs/FDD.md)" -ge 8 ] && ok "FDD: exemplos JSON (>=8 blocos: request e response de 4 endpoints)" || warn "FDD: menos de 8 blocos json (4 endpoints x request+response)"
  for t in "M.tricas" "Logs" "Tracing"; do grep -qiE "$t" docs/FDD.md || bad "FDD sem $t"; done
  sec=$(awk '/^#+ .*Integra..o com o sistema existente/{f=1} f' docs/FDD.md)
  n=0; for p in $(echo "$sec" | grep -oE "(src|prisma|tests)/[A-Za-z0-9_./-]+\.(ts|prisma|sql|json)" | sort -u); do [ -f "$p" ] && n=$((n+1)); done
  [ "$n" -ge 4 ] && ok "FDD: integração cita $n arquivos reais" || bad "FDD: integração cita $n arquivos reais (min 4)"
  [ "$MODE" != fdd ] && for l in $(grep -oE "adrs/ADR-[0-9]{3}-[a-z0-9-]+\.md" docs/FDD.md | sort -u); do [ -f "docs/$l" ] || bad "FDD link quebrado: $l"; done
  grep -qE "—" docs/FDD.md && warn "FDD contém travessão longo"
  paths_check docs/FDD.md; }

check_adrs(){
  c=$(ls docs/adrs/ 2>/dev/null | grep -cE "^ADR-[0-9]{3}-[a-z0-9-]+\.md$"); { [ "$c" -ge 5 ] && [ "$c" -le 8 ]; } && ok "ADRs: $c arquivos" || bad "ADRs: $c arquivos (esperado 5 a 8)"
  for a in $ADRS; do [ -f "docs/adrs/$a.md" ] || warn "ADR do mapa ausente: $a.md"; done
  cod=0; for f in docs/adrs/ADR-*.md; do [ -f "$f" ] || continue
    [ "$(wc -c <"$f")" -gt 1200 ] || bad "$f muito curto"
    for s in "Status" "Contexto" "Decis.o" "Alternativas Consideradas" "Consequ.ncias"; do has "$f" "$s"; done
    grep -qiE "positiv" "$f" && grep -qiE "negativ" "$f" || bad "$f: consequências sem positivas e negativas"
    grep -qiE "trade-off" "$f" || bad "$f: trade-off não explícito"
    grep -qE "ADR-[0-9]{3}-ALT-[0-9]{2}" "$f" || bad "$f: sem alternativa identificada (ADR-00N-ALT-nn)"
    grep -qE "src/[A-Za-z0-9_./-]+\.ts|prisma/[A-Za-z0-9_./-]+" "$f" && cod=$((cod+1))
    grep -qE "—" "$f" && warn "$f contém travessão longo"
    paths_check "$f"; done
  [ "$cod" -ge 1 ] && ok "ADRs: $cod citam arquivos do código" || bad "nenhum ADR cita arquivos do código"; }

check_tracker(){ T=docs/TRACKER.md; exists "$T" || return
  grep -qE "^\| *ID *\| *Documento *\| *Tipo *\| *Conte.do \(resumo\) *\| *Fonte *\| *Localiza..o *\|" "$T" && ok "Tracker: cabeçalho no formato" || bad "Tracker: cabeçalho fora do formato"
  ids=$(grep -ohE "\b(PRD|RFC|FDD)-[A-Z]+-[0-9]{2}\b|\bADR-[0-9]{3}(-ALT-[0-9]{2})?\b" docs/PRD.md docs/RFC.md docs/FDD.md docs/adrs/ADR-*.md 2>/dev/null | sort -u)
  tot=$(echo "$ids" | grep -c .); cov=0; for i in $ids; do grep -qE "^\| *$i *\|" "$T" && cov=$((cov+1)); done
  [ "$tot" -gt 0 ] && pct=$((cov*100/tot)) || pct=0; [ "$pct" -ge 80 ] && ok "Tracker: cobertura $pct% ($cov/$tot)" || bad "Tracker: cobertura $pct% ($cov/$tot) (min 80)"
  rows=$(grep -cE "^\| *(PRD|RFC|FDD|ADR)-" "$T"); tr=0; cd_=0
  while IFS='|' read -r _ id doc tipo cont fonte loc _; do
    id=$(echo "$id" | xargs); fonte=$(echo "$fonte" | xargs); loc=$(echo "$loc" | xargs)
    case "$fonte" in
      CODIGO) [ -f "${loc%% *}" ] && cd_=$((cd_+1)) || bad "Tracker: CODIGO com caminho inexistente ($id): $loc";;
      TRANSCRICAO) ts=$(echo "$loc" | grep -oE "^\[[0-2][0-9]:[0-5][0-9]\] [^ ;,]+" | head -1)
        if [ -n "$ts" ] && grep -qF "$ts:" TRANSCRICAO.md; then tr=$((tr+1)); else bad "Tracker: timestamp inválido ($id): $loc"; fi;;
      *) bad "Tracker: Fonte deve ser TRANSCRICAO ou CODIGO ($id): '$fonte'";;
    esac
  done < <(grep -E "^\| *(PRD|RFC|FDD|ADR)-" "$T")
  [ "$rows" -gt 0 ] && p2=$((tr*100/rows)) || p2=0; [ "$p2" -ge 70 ] && ok "Tracker: $p2% das linhas TRANSCRICAO válidas" || bad "Tracker: $p2% TRANSCRICAO válidas (min 70)"
  [ "$cd_" -ge 5 ] && ok "Tracker: $cd_ linhas CODIGO válidas" || bad "Tracker: $cd_ linhas CODIGO válidas (min 5)"; }

check_readme(){ [ -f README.md ] || { bad "README.md ausente"; return; }
  for s in "Sobre o desafio" "Ferramentas de IA" "Workflow" "Prompts customizados" "Itera..es" "Como navegar"; do has README.md "$s"; done
  f=$(grep -cE '^```' README.md); [ "$f" -ge 4 ] && ok "README: $((f/2)) blocos de código" || bad "README: $((f/2)) blocos de código (min 2 prompts)"
  grep -qiE "claude|chatgpt|gemini|cursor|copilot" README.md && ok "README cita ferramenta de IA" || bad "README sem ferramenta de IA"
  grep -qE "desafio da|Descri..o$|Estrutura obrigat.ria do entreg.vel" README.md && warn "README parece conter trechos do enunciado"
  paths_check README.md; }

check_git(){ chg=$(git status --porcelain | awk '{print $NF}' | grep -E "^(src|prisma|tests)/|^TRANSCRICAO.md|^package|^tsconfig|^docker-compose|^desafio.md")
  [ -z "$chg" ] && ok "código e transcrição intactos" || bad "arquivos proibidos alterados: $chg"; }

case "$MODE" in
  prd) check_prd;; rfc) check_rfc;; fdd) check_fdd;; adrs) check_adrs;; tracker) check_tracker;; readme) check_readme;;
  wave1) check_prd; check_rfc; check_fdd; check_adrs; check_git;;
  full) check_prd; check_rfc; check_fdd; check_adrs; check_tracker; check_readme; check_git;;
  *) echo "modo inválido: $MODE"; exit 2;;
esac
echo "---- MODO=$MODE FALHAS=$FAIL AVISOS=$WARN"
[ "$FAIL" -eq 0 ]
