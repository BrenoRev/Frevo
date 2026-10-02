# Git

- Antes de commitar código: `scripts/verificar.sh`. Antes de abrir PR: `docs/regras/pronto.md` inteiro.
- `main` sempre compila e só recebe merge por PR com o CI verde.
- Uma branch por frente de trabalho, um integrante por PR: o histórico mostra quem fez o quê.
- Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `build:`, `ci:`, `chore:`. Um commit por passo concluído.
- Sem linha `Co-Authored-By` de IA nos commits nem rodapé de atribuição nos PRs.
- Não commitar trabalho de um integrante em nome de outro.
- Sem artefato de build (`dist-newstyle/`), arquivo gerado (guia de estudo) nem configuração pessoal de editor.
