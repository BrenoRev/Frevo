#!/bin/sh
# Roda o que o CI roda. Tem de passar antes de todo commit que mexe em código.
set -e
cd "$(git rev-parse --show-toplevel)"

test -s docs/gramatica.ebnf || { echo "docs/gramatica.ebnf está vazio"; exit 1; }

cabal build all --enable-tests --ghc-options=-Werror
cabal test --test-show-details=direct

for f in examples/*.frevo; do
  cabal run -v0 Frevo -- "$f" > /dev/null || { echo "Exemplo rejeitado: $f"; exit 1; }
done

if command -v hlint > /dev/null; then
  hlint src app test
else
  echo "hlint não instalado: o CI vai rodar essa etapa"
fi

echo "Tudo certo."
