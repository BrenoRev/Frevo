#!/bin/sh
# Converte docs/guia-de-estudo.md em PDF.
set -e
cd "$(git rev-parse --show-toplevel)"
# No macOS o WeasyPrint não acha o Pango do Homebrew sozinho.
if command -v brew >/dev/null; then
  export DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_FALLBACK_LIBRARY_PATH"
fi
pandoc docs/guia-de-estudo.md \
  --from markdown --standalone \
  --metadata title="Frevo — guia de estudo" \
  --css scripts/guia/estilo.css \
  --pdf-engine weasyprint \
  --output docs/guia-de-estudo.pdf
echo "docs/guia-de-estudo.pdf"
