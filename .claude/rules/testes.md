---
paths:
  - "test/**/*.hs"
---

# Testes

- Toda construção tem teste de aceitação comparando a AST produzida e teste de rejeição.
- Teste de erro confere linha e coluna, não só que falhou.
- Um `it` por comportamento, com nome em português dizendo o que é verificado.
- Casos de borda ficam em `ErroSpec`: arquivo vazio, só comentários, aninhamento profundo.
- Os programas de `examples/` são aceitos pelo parser (`StmtSpec`).
- Teste não é ajustado para passar: se quebrou, o defeito está no código ou na gramática.
