# Guia de estudo das entregas

Escreve `docs/guia-de-estudo.md` e gera `docs/guia-de-estudo.pdf` (arquivos gerados, que não se commitam). O leitor é um integrante do grupo que vai ser arguido individualmente e precisa entender o que foi construído, inclusive as partes que não escreveu.

Procedimento para qualquer pessoa ou assistente de IA. Se pedirem uma entrega específica, atualize só a seção dela e mantenha as outras; senão, cubra todas as entregas concluídas.

## 1. Levantar o que existe

O guia descreve o repositório como ele está, não como foi planejado. Leia antes de escrever:

- `AGENTS.md`: enunciado e checklist de cada entrega. Só entra no guia entrega com código ou documento no repositório.
- `docs/especificacao.md`, `docs/gramatica.ebnf`, `README.md` (tabela de decisões).
- Todo o código de `src/` e `app/`, e os testes de `test/`.
- `git log --format='%h %an %s'` para saber o que mudou e quando.

Rode `cabal build all` e `cabal test` e anote o número de testes. Não escreva que algo funciona sem ter rodado.

## 2. Escrever

Uma seção por entrega, sempre com estes seis blocos, nesta ordem:

1. **O que o professor pediu** — o enunciado, em uma ou duas frases.
2. **O que entregamos** — lista curta: artefato e onde está.
3. **Conceitos** — cada termo que o professor pode cobrar, definido em uma ou duas frases, com a terminologia da área (token, lexema, gramática livre de contexto, AST, LL(1), precedência, associatividade…). Só os conceitos que o projeto usa.
4. **Como fizemos** — o caminho dos dados de ponta a ponta e os trechos de código que sustentam cada ideia. Trecho copiado do arquivo real, com no máximo 15 linhas e o caminho indicado; nunca código escrito para o guia.
5. **Por que decidimos assim** — tabela: decisão, alternativa descartada, trade-off. É o bloco que separa a nota 7,5 da 10.
6. **Perguntas prováveis** — de 6 a 10 perguntas no estilo do professor, cada uma com resposta de até três frases. Inclua pelo menos duas do tipo "o que acontece se a entrada for…", respondidas com a saída real do programa.

Feche o guia com uma **cola rápida**: vocabulário da linguagem, tabela de precedência e o mapa de arquivos.

### Como escrever

- Direto. Frase curta, um conceito por parágrafo, sem introdução nem conclusão.
- Tabela e lista quando a informação é comparável; prosa só para explicar um porquê.
- Exemplo concreto vale mais que definição: mostre a entrada e a AST que sai.
- Nada inventado. Sem certeza de um fato, confira no código; se não der para conferir, deixe de fora.
- Duas a três páginas por entrega. Se passou disso, corte.
- Sem data, sem nome de integrante, sem elogio ao projeto.

## 3. Gerar o PDF

```sh
scripts/guia/gerar-pdf.sh
```

Precisa de `pandoc` e `weasyprint` (`brew install pandoc weasyprint`). Abra o PDF e confira cada página: tabela cortada, bloco de código estourando a margem ou título órfão no fim da página se corrigem no Markdown e gera-se de novo.

## 4. Conferir antes de entregar

- Todo trecho de código do guia existe igual no arquivo citado.
- Toda saída de programa citada foi obtida rodando o programa.
- Vocabulário e precedência batem com `reservedKeywords` e `operatorTable`.
- O guia não menciona nada que foi cortado da linguagem como se existisse.

O guia é material gerado: os dois arquivos não entram em commit nem em PR. Eles não estão no `.gitignore`, então confira o `git status` antes de commitar e apague-os depois de usar.
