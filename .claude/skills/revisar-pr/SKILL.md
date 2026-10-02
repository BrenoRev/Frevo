---
name: revisar-pr
description: Revisa um pull request da Frevo antes do merge — compila, roda os testes e os exemplos, confere as rules do projeto e diz se está entregável ao professor. Use quando pedirem para revisar, validar ou aprovar um PR.
argument-hint: <número do PR>
---

# Revisão de pull request

Revise o PR `$ARGUMENTS` do repositório. Se não vier número, use `gh pr list` e pergunte qual.

A revisão responde a uma pergunta: **dá para fazer merge e apresentar isso ao professor?** Seja direto. Não elogie, não resuma o que o diff já mostra.

## 1. Ler

```sh
gh pr view <n> --json title,body,author,commits,files,statusCheckRollup
gh pr diff <n>
```

Leia também os arquivos inteiros que o diff toca, não só as linhas alteradas.

## 2. Funciona?

Guarde a branch atual, faça checkout do PR e rode:

```sh
gh pr checkout <n>
cabal build all --ghc-options=-Werror
cabal test --test-show-details=direct
for f in examples/*.frevo; do cabal run -v0 Frevo -- "$f" > /dev/null || echo "REJEITADO: $f"; done
```

Qualquer falha reprova o PR. Cole o trecho relevante da saída. Ao terminar, volte para a branch em que estava.

Se a mudança mexe no parser, teste à mão ao menos uma entrada válida e uma inválida que os testes do PR não cobrem.

## 3. Está certo?

Procure, nesta ordem:

- Gramática (`docs/gramatica.ebnf`) e parser dizendo coisas diferentes.
- Construção nova sem teste de rejeição, ou teste que só verifica que o parse não falhou.
- `try` cobrindo um parser grande: esconde o erro real e piora a mensagem.
- Ordem de alternativas em que um prefixo casa antes (`<` antes de `<=`, `se` antes de `segue`).
- Palavra usada como reservada fora de `reservedKeywords`.
- Função parcial, `error`, warning silenciado.
- Teste alterado para passar em vez de o código ser corrigido.

## 4. Segue as rules?

Confira contra `.claude/rules/haskell.md`, `linguagem.md`, `testes.md` e `git.md`. Aponte só violações concretas, com `arquivo:linha`.

Atenção especial a código inchado: comentário que repete o código, abstração sem segundo uso, camada que o enunciado não pede. Diga o que cortar.

## 5. É entregável?

Compare com o enunciado e a checklist da entrega corrente em `CLAUDE.md`. Diga quais itens o PR fecha e quais continuam abertos. Não cobre do PR o que está fora do escopo dele.

## 6. Arguição

Escreva 3 perguntas que o professor faria sobre o que este PR mudou (por que X e não Y, o que acontece com a entrada Z, qual o trade-off). O autor precisa saber respondê-las antes do merge.

## Formato da resposta

```
Veredito: APROVAR | PEDIR MUDANÇAS | BLOQUEAR

Build: ok/falhou   Testes: N passaram, M falharam   Exemplos: ok/rejeitados

Problemas (do mais grave ao menos):
- arquivo:linha — o que está errado e como corrigir

Checklist da entrega: fecha … / continua aberto …

Perguntas para o autor:
1. …
```

`BLOQUEAR` é para build ou teste quebrado. `PEDIR MUDANÇAS` é para defeito ou violação de rule. Sem problemas, diga `APROVAR` e pare.

Não comente no PR, não aprove e não faça merge pelo GitHub sem pedido explícito.
