# Testes

Vale para todo código em `test/`.

- Toda construção tem teste de aceitação comparando a AST produzida e teste de rejeição.
- Rejeição é por peça da regra: para cada palavra ou símbolo obrigatório, um caso em que ele falta (`se` sem `então`, `pracada` sem `em`, parêntese não fechado).
- Todo literal tem teste do que aceita e do que rejeita no limite (`1.`, `2pac`, prosa não fechada).
- Entrada do mundo real tem teste: fim de linha do Windows, acento em nome, arquivo vazio.
- Teste de erro confere linha e coluna, não só que falhou.
- Um `it` por comportamento, com nome em português dizendo o que é verificado.
- Casos de borda ficam em `ErroSpec`: arquivo vazio, só comentários, aninhamento profundo.
- Os programas de `examples/` são aceitos pelo parser (`StmtSpec`).
- Defeito encontrado à mão ou em revisão vira teste antes de ser corrigido.
- Teste não é ajustado para passar: se quebrou, o defeito está no código ou na gramática.
