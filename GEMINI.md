# Projeto: MBA IA - Desafio Design Docs com IA

Este arquivo contém as diretrizes de engenharia e convenções para este repositório.

## Estratégia de Economia de Tokens

Para garantir eficiência e reduzir custos de contexto, seguimos rigorosamente estas regras:

1.  **Pesquisa Estratégica:**
    - Utilize `grep_search` e `glob` com escopo restrito (use `include_pattern` e `exclude_pattern`).
    - Combine buscas em paralelo sempre que possível.
    - Utilize os parâmetros `before` e `after` no `grep_search` para obter contexto suficiente em uma única chamada, evitando `read_file` subsequente.

2.  **Leitura Cirúrgica:**
    - Nunca leia arquivos inteiros se precisar apenas de uma parte. Utilize `start_line` e `end_line` no `read_file`.
    - Minimize o número de chamadas de leitura de arquivo em uma única sequência.

3.  **Edições Eficientes:**
    - Utilize o `replace` para edições precisas e cirúrgicas. Forneça contexto suficiente no `old_string` para evitar ambiguidades.
    - Evite reescrever arquivos inteiros com `write_file` a menos que seja uma criação ou um arquivo muito pequeno.

4.  **Uso de Subagentes:**
    - Delegue tarefas repetitivas, de alta carga ou investigação complexa para os subagentes (`generalist`, `codebase_investigator`). As interações com subagentes consolidam o histórico e preservam o seu contexto principal.

5.  **Comunicação Concisa:**
    - Mantenha respostas diretas e profissionais.
    - Evite preâmbulos ("Ok, vou fazer...") e conclusões desnecessárias. Foque no valor técnico.
    - Use `update_topic` apenas para fases complexas (a cada 3-10 turnos) para orquestrar o fluxo.

6.  **Gerenciamento de Histórico:**
    - Mantenha a história de conversas concisa; não repita resumos ou explicações já fornecidos.
