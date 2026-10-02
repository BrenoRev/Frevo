## O que muda

<!-- Uma ou duas frases. -->

## Entrega

<!-- Qual entrega e qual item da checklist do CLAUDE.md este PR fecha. -->

## Como testar

```sh
cabal build all
cabal test
```

## Antes de pedir revisão

- [ ] `cabal build all --ghc-options=-Werror` passa
- [ ] `cabal test` passa
- [ ] Se mudou a sintaxe: `docs/gramatica.ebnf`, parser e testes mudaram juntos
- [ ] Sei explicar cada linha deste PR
