---
paths:
  - "src/**/*.hs"
  - "app/**/*.hs"
  - "test/**/*.hs"
---

# Código Haskell

- Compila sem warning em `-Wall`. O CI usa `-Werror`.
- Sem `error`, `undefined`, `head`, `fromJust` nem outra função parcial.
- Assinatura de tipo em toda função de topo.
- Parsers têm prefixo `p` (`pIf`, `pExpr`). Construtores da AST: `E*` para expressão, `S*` para comando, `T*` para tipo.
- Comentário só para o que o código não mostra: o porquê. Sem banner de seção, sem repetir o nome da função, sem numerar passos.
- Função curta e direta. Se precisa de comentário para ser entendida, reescreva.
- Única extensão de linguagem: `OverloadedStrings`.
- Dependência nova só combinada com o grupo.
- Sem código morto, módulo vazio ou `TODO` commitado.
- Todo integrante precisa conseguir reescrever o trecho no quadro. Na dúvida, a versão mais simples.
