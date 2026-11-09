#!/bin/sh
# Roda o que o CI roda. Tem de passar antes de todo commit que mexe em código.
set -e
cd "$(git rev-parse --show-toplevel)"

test -s docs/gramatica.ebnf || { echo "docs/gramatica.ebnf está vazio"; exit 1; }

cabal build all --enable-tests --ghc-options=-Werror
cabal test --test-show-details=direct

# Os exemplos são checados e executados; 03_feira lê um nome do teclado.
for f in examples/*.frevo; do
  printf 'Painho\n' | cabal run -v0 Frevo -- "$f" > /dev/null || { echo "Exemplo falhou: $f"; exit 1; }
done

# A checagem vem antes da execução: um programa mal tipado não roda nem o
# espia que vem antes do erro.
mal_tipado=$(mktemp)
printf 'espia("rodou")\nNumero x = "oi"\n' > "$mal_tipado"
erro_tipo=$(mktemp)
if saida=$(cabal run -v0 Frevo -- "$mal_tipado" 2> "$erro_tipo"); then
  echo "Programa mal tipado foi aceito"; exit 1
fi
grep -q "os tipos num batem" "$erro_tipo" || { echo "Programa mal tipado falhou sem erro de tipo"; exit 1; }
rm -f "$mal_tipado" "$erro_tipo"
test -z "$saida" || { echo "Programa mal tipado executou antes da checagem: $saida"; exit 1; }

if command -v hlint > /dev/null; then
  hlint src app test
else
  echo "hlint não instalado: o CI vai rodar essa etapa"
fi

echo "Tudo certo."
