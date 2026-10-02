# Mudanças na linguagem

- A gramática em `docs/gramatica.ebnf` é a referência. Mudança de sintaxe altera no mesmo PR: a gramática, `src/Frevo/Parser.hs` e os testes.
- Palavra reservada nova entra também em `reservedKeywords` (`src/Frevo/Lexer.hs`) e em `docs/especificacao.md`, com a justificativa.
- O que dá para escrever como função comum vai para a stdlib, não vira sintaxe.
- Toda construção da linguagem aparece em pelo menos um programa de `examples/`.
- Antes de acrescentar algo, pergunte se a linguagem funciona sem. Se funciona, não entra.
