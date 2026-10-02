## O que muda

<!-- Uma ou duas frases. -->

## Entrega

<!-- Qual entrega e qual item da checklist do CLAUDE.md este PR fecha. -->

## Como testar

```sh
scripts/verificar.sh
```

## Antes de pedir revisão

- [ ] `scripts/verificar.sh` passa
- [ ] Tentei quebrar com entradas que os testes não cobrem (`.claude/rules/pronto.md`)
- [ ] Rodei `/revisar-pr` e corrigi o que ela apontou
- [ ] Se mudou a sintaxe: `docs/gramatica.ebnf`, parser e testes mudaram juntos
- [ ] Sei explicar cada linha deste PR
