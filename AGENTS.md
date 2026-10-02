# Frevo — guia de trabalho para assistentes de IA

Projeto da disciplina **Implementação de Linguagens de Programação / Compiladores** (prof. Rodrigo Bonifácio de Almeida). O grupo implementa a linguagem **Frevo** de forma incremental, em quatro entregas: definição da linguagem → gramática e parser → sistema de tipos e interpretador → RI, otimização e geração de código.

Este arquivo é o ponto de entrada para qualquer assistente de IA usado no projeto (Claude Code, Codex, Cursor, Copilot, Gemini e outros) e também serve de guia para os integrantes. Nada aqui depende de uma ferramenta específica.

**Antes de mexer em qualquer coisa, leia também:**

| Para | Leia |
|---|---|
| Escrever ou alterar código | [docs/regras/haskell.md](docs/regras/haskell.md), [docs/regras/testes.md](docs/regras/testes.md) |
| Mudar a sintaxe da linguagem | [docs/regras/linguagem.md](docs/regras/linguagem.md), [docs/gramatica.ebnf](docs/gramatica.ebnf) |
| Commitar ou abrir PR | [docs/regras/git.md](docs/regras/git.md), [docs/regras/pronto.md](docs/regras/pronto.md) |
| Revisar um PR | [docs/procedimentos/revisar-pr.md](docs/procedimentos/revisar-pr.md) |
| Gerar o guia de estudo em PDF | [docs/procedimentos/guia-estudo.md](docs/procedimentos/guia-estudo.md) |

A avaliação de cada entrega é **oral e individual**. Código que roda não garante nota: o objetivo é que cada integrante consiga justificar decisões, alternativas e trade-offs. Isso governa tudo neste arquivo.

## 1. A linguagem

| Campo | Valor |
|---|---|
| Nome / extensão | Frevo / `.frevo` |
| Host | Haskell (Cabal; testado com GHC 9.10.3, a versão do CI) |
| Estratégia de parsing | Parser combinators (Megaparsec + `parser-combinators`) |
| Propósito | Específico (DSL): ensino de programação para crianças, com vocabulário pernambucano |
| Paradigma | Imperativo |
| Sistema de tipos | Estático |
| Inspiração sintática | Python (superfície), blocos fechados por `cabousse` |
| Representação intermediária | TAC |
| Repositório | https://github.com/BrenoRev/Frevo |

**Vocabulário** (24 palavras reservadas, em `reservedKeywords` de [src/Frevo/Lexer.hs](src/Frevo/Lexer.hs)):

| Função | Lexema |
|---|---|
| Tipos | `Numero` (int), `Quebrado` (real), `Prosa` (string), `Certeza` (bool), `Ruma de T` (lista), `Nadica` (sem valor, só como retorno) |
| Literais booleanos | `Certo`, `Errado` |
| Declaração | `Numero x = 0` — sempre com tipo; `x = 1` é só atribuição |
| Condicional | `se … então … sinão … cabousse` |
| Laços | `enquanto … faça … cabousse`, `pracada x em xs faça … cabousse` |
| Controle | `poparrar` (break), `segue` (continue), `devolve e` (return) |
| Função | `função nome(T x, …) -> T … cabousse`, só no nível de topo |
| Operadores | `+ - * /`, `== <= >= < >`, `e`, `ou`, `nam` |
| Stdlib | `espia`, `pergunta`, `encanga`, `quantoTem` — funções comuns, não reservadas |
| Comentário | `#` até o fim da linha |

Gramática: [docs/gramatica.ebnf](docs/gramatica.ebnf). Decisões e cortes: [docs/especificacao.md](docs/especificacao.md).

**Equipe (4 integrantes):**

| Integrante | GitHub |
|---|---|
| Breno | `BrenoRev` |
| Elisson | `ElissonXD` |
| Gabriel Maciel | `gabrieual` |
| Guilherme | — |

## 2. Como trabalhar neste projeto

1. **Terminologia canônica.** Token, lexema, gramática livre de contexto, AST, ambiente de tipos Γ, regra de tipagem, semântica operacional small-step/big-step, TAC, basic block, CFG, dataflow analysis. Sem sinônimos inventados.
2. **Nunca inventar dados.** Sem certeza sobre uma API, citação, regra da disciplina ou decisão do grupo: dizer que não sabe em vez de preencher com algo plausível. Lacuna é melhor que informação errada.
3. **Explicar antes de implementar.** Antes de cada bloco de código relevante, 3–6 linhas: qual algoritmo, por que ele, quais alternativas foram descartadas.
4. **Sabatina ao final.** Toda implementação significativa termina com 3 perguntas no estilo do professor ("por que X e não Y?", "o que acontece se a entrada for Z?", "qual o trade-off?").
5. **Checklist antes de declarar pronto.** Seguir [docs/regras/pronto.md](docs/regras/pronto.md): rodar `scripts/verificar.sh`, tentar quebrar com entradas novas, conferir gramática × parser e revisar o próprio PR pelo procedimento de revisão. Passar item a item pela checklist da entrega (§5), marcando `[x]`/`[ ]` explicitamente.
6. **Não simplificar o problema para caber.** Nada de regex no lugar de parser, `eval` do host no lugar de interpretador, ou hardcode para passar em teste. Se algo for inviável, dizer e propor um recorte honesto — nunca um stub disfarçado.
7. **Testes fazem parte da entrega.** Casos válidos, inválidos (rejeição) e de borda. Parser sem teste de rejeição não está pronto.
8. **Idioma.** Respostas em português do Brasil. Identificadores Haskell em inglês. As palavras-chave e as mensagens de erro **da linguagem Frevo** são em português regional — isso é o propósito da linguagem, não uma violação da regra.
9. **Nunca entregar o que o integrante não conseguiria reescrever no quadro.** Preferir código direto a abstrações engenhosas (ex.: evitar extensões de tipo avançadas, lenses, free monads) a menos que o ganho seja defensável oralmente.
10. Uma pergunta de esclarecimento por vez, e só quando a ambiguidade impedir o trabalho.

## 3. Mapa do repositório

| Caminho | Conteúdo |
|---|---|
| [Frevo.cabal](Frevo.cabal) | `library` (src), `executable Frevo` (app), `test-suite spec` (test) |
| [src/Frevo/AST.hs](src/Frevo/AST.hs) | `Type`, `Op`, `Expr`, `Stmt`; o programa é `[Stmt]` |
| [src/Frevo/Lexer.hs](src/Frevo/Lexer.hs) | Camada léxica em Megaparsec: `sc`, `lexeme`, `symbol`, `rword`, `pIdentifier`, `reservedKeywords` |
| [src/Frevo/Parser.hs](src/Frevo/Parser.hs) | Expressões (`makeExprParser` + `operatorTable`), comandos, `pFun`, `parseProgram` |
| [app/Main.hs](app/Main.hs) | CLI: imprime a AST, ou o erro com linha e coluna e código de saída 1 |
| [test/](test/) | hspec: `LexerSpec`, `ExprSpec`, `StmtSpec`, `ErroSpec` |
| [examples/](examples/) | `01_bom_dia`, `02_passos`, `03_feira` — juntos usam toda a linguagem |
| [docs/](docs/) | Gramática, especificação e o PDF do levantamento de vocabulário |
| [docs/regras/](docs/regras/) | Padrões de código, linguagem, testes, git e a definição de pronto — **seguir sempre** |
| [scripts/verificar.sh](scripts/verificar.sh) | Tudo o que o CI roda, em um comando |
| [docs/procedimentos/](docs/procedimentos/) | Passo a passo para revisar um PR e para gerar o guia de estudo (PDF, fora do git) |
| [.claude/](.claude/), [CLAUDE.md](CLAUDE.md) | Atalhos do Claude Code para os arquivos acima; não têm conteúdo próprio |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | CI do PR: build com `-Werror`, testes, exemplos, hlint, padrão de commits |

```sh
scripts/verificar.sh                          # build -Werror, testes, exemplos, hlint
cabal run Frevo -- examples/03_feira.frevo
```

## 4. Estado atual e por onde seguir

**Entregas 1 e 2 implementadas** na branch `feat/entrega-2`: gramática, parser e suíte de testes prontos, build e testes verdes.

Falta, fora do código: slides da Entrega 1 e a preparação de cada integrante para a arguição (todos precisam saber explicar `Lexer.hs`, `Parser.hs` e a gramática).

**Próxima: Entrega 3 (sistema de tipos e interpretador).** Pontos de partida já conhecidos:

1. A AST não guarda posição de origem. O erro de tipo precisa de linha e coluna, então o primeiro passo é decidir onde guardar a posição (o mais simples: nos comandos).
2. `espia` e `quantoTem` aceitam mais de um tipo; o type checker vai tratá-las como casos embutidos, já que a linguagem não tem polimorfismo.
3. A lista vazia `[]` só tem tipo pela declaração (`Ruma de Numero xs = []`).
4. A linguagem não tem indexação, então "índice fora de faixa" não existe; o erro de execução a tratar é a divisão por zero.

## 5. Entregas e checklists

Cada entrega abre com o **enunciado oficial** do professor — é ele que define o que é exigido. As checklists abaixo de cada enunciado são o desdobramento interno do grupo para chegar lá com qualidade; não são requisitos literais da disciplina. Marcações refletem o estado descrito em §4; atualizar ao concluir cada item.

### Entrega 1 — Definição da linguagem

> **Enunciado:** Apresentações on-line com a definição da linguagem de programação. Utilizar o formato 'elevator pitch', mas um pouco mais longo: 15 minutos com a definição da linguagem e 10 minutos de discussão. Algumas questões devem ser respondidas:
>
> - Propósito da linguagem: geral ou específico
> - Paradigma da linguagem: imperativo, funcional, lógico
> - Sistema de tipos: estático x dinâmico
> - Inspiração sintática (se houver alguma)
>
> A primeira versão da linguagem (cuja implementação vai até o final do semestre) não precisa ter features muito avançadas, como tipos complexos, polimorfismo e concorrência. Pode se concentrar em tipos básicos, que suportem valores booleanos, inteiros, reais e strings. Eventualmente, um tipo compostos como o tipo list. Pensem quais serão as expressões e os 'statements' (comandos) suportados diretamente pela linguagem; e quais recursos devem ser implementados como funções em uma stdlib.

- [x] Propósito declarado e justificado
- [x] Paradigma declarado
- [x] Sistema de tipos declarado, com trade-off
- [x] Inspiração sintática identificada
- [x] Lista fechada de expressões ([docs/especificacao.md](docs/especificacao.md))
- [x] Lista fechada de *statements*
- [x] Fronteira núcleo × stdlib, com justificativa do corte
- [x] 3 programas de exemplo (hello world, controle de fluxo, stdlib)
- [ ] Cada integrante defende todas as decisões
- [ ] Slides versionados

### Entrega 2 — Gramática e parser

> **Enunciado:** Definição da gramática da linguagem e implementação do parser (incluindo suite de testes).

"Parser" aqui é o macrocomponente: análise léxica **e** sintática.

- [x] Gramática formal (EBNF) versionada em `docs/`
- [x] Sem ambiguidade: precedência e associatividade documentadas no cabeçalho da gramática; *dangling else* eliminado pelo `cabousse` obrigatório
- [x] Estratégia de parsing declarada e justificada, com a classe de gramática (tabela de decisões do README)
- [x] Tokens definidos; conflito identificador × palavra-chave tratado por `rword` e `pIdentifier`
- [x] AST como tipo de dados explícito, separada da gramática concreta
- [x] Testes em três categorias: válidos (AST esperada), inválidos (rejeição), borda (arquivo vazio, 100 níveis de aninhamento, prosa não fechada)
- [x] Erros sintáticos com linha e coluna, conferidas em `ErroSpec`
- [x] Os 3 exemplos aceitos pelo parser (teste em `StmtSpec` e etapa do CI)
- [x] Build e testes documentados no `README.md`

Frevo só tem comentário de linha, então "comentário não fechado" não se aplica; o análogo coberto é a prosa não fechada.

### Entrega 3 — Sistema de tipos e interpretador

> **Enunciado:** Implementação do sistema de tipos e do interpretador para a linguagem.

- [ ] Regras de tipagem em notação de julgamentos (`Γ ⊢ e : τ`) para todas as construções, em documento próprio em `docs/`
- [ ] Ambiente de tipos Γ com escopo léxico correto (aninhamento, sombreamento)
- [ ] Type checker implementado; se houver inferência, algoritmo nomeado e justificado
- [ ] Erros de tipo com posição e tipo esperado × encontrado
- [ ] Semântica operacional documentada (small-step ou big-step, justificado), com correspondência regra ↔ código do interpretador
- [ ] Interpretador sobre a AST, com ambiente de execução separado do ambiente de tipos
- [ ] Erros de execução (divisão por zero) tratados e distintos dos erros de tipo
- [ ] Testes de rejeição: programa mal tipado falha na checagem, não na execução
- [ ] Stdlib mínima conforme a fronteira da Entrega 1
- [ ] Cada integrante explica por que uma regra é *sound* (ou onde não é)

### Entrega 4 — Geração de código e otimização

> **Enunciado:** Implementação dos algoritmos de geração de código e otimização de programas.

- [ ] Tradução AST → TAC para todas as construções (controle de fluxo via labels e jumps)
- [ ] Temporários e labels sem colisão
- [ ] Basic blocks e CFG
- [ ] Ao menos uma análise de fluxo de dados (liveness, reaching definitions, available expressions), com *lattice* e função de transferência documentados
- [ ] Ao menos duas otimizações sobre TAC, cada uma com argumento de preservação de comportamento
- [ ] Evidência empírica antes/depois (nº de instruções TAC e/ou tempo) em 3+ programas
- [ ] Geração de código para a linguagem alvo
- [ ] Testes de equivalência semântica: otimizado × não otimizado, mesmas entradas, mesma saída
- [ ] Documento final consolidando as decisões das quatro entregas

### Seminário

Três temas: **T01** geração automática de analisadores léxicos e sintáticos; **T02** sistemas de tipos além do *simply typed lambda calculus*; **T03** otimização sobre TAC.

- [ ] Tema alinhado ao bloco e aprovado previamente
- [ ] Fonte primária (artigo original ou capítulo de livro-texto), não blog
- [ ] Referências completas e verificáveis
- [ ] Ao menos um exemplo executado passo a passo
- [ ] Conexão explícita com Frevo
- [ ] Tempo ensaiado

## 6. Avaliação e regras do repositório

**Nota final:** `F = 0.5·Projeto + 0.25·Seminário + 0.25·Participação`. Uso de IA é permitido como apoio.

**Rubrica das respostas individuais** — otimizar sempre para o nível 10:

| Nota | Critério |
|---|---|
| 2,0 | Não responde a questões básicas sobre a implementação |
| 3,5 | Resposta substancialmente incorreta |
| 5,0 | Essencialmente correta, justificativa limitada |
| 7,5 | Correta e bem fundamentada |
| 10,0 | Precisa e aprofundada; justifica decisões e discute alternativas e trade-offs |

**Git:**

- `main` sempre compilando; trabalho em branch de feature + PR.
- *Conventional Commits* (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`), commits pequenos e atômicos.
- O histórico precisa evidenciar a contribuição de **cada** integrante. Guilherme ainda não tem commits: ao dividir trabalho, reservar para ele uma frente autocontida e de autoria clara (ex.: suíte de testes, `Pretty.hs` + round-trip, ou camada de mensagens de erro). Não commitar trabalho de um integrante em nome de outro.
- Não commitar nem fazer push sem pedido explícito.
- Nenhum artefato de build versionado (`dist/`, `dist-newstyle/` já estão no `.gitignore`).
- `docs/` para gramática, regras de tipagem e semântica operacional; `examples/` para programas `.frevo`.
- Notação formal em LaTeX ou Unicode consistente, nunca em prosa aproximada. Markdown para documentação no repositório; PDF para relatórios ao professor.

## 7. Modo Ensino

**Gatilho:** pedido para estudar um assunto da disciplina antes da aula. Ao reconhecê-lo, ignorar os formatos de entrega de código e responder nesta estrutura, curta e densa:

1. **Visão geral e mapa mental.** Esquema visual (tabela ou fluxograma em bloco de código) situando o assunto no pipeline e mostrando suas subdivisões, antes de qualquer explicação.
2. **Conceito direto.** Teoria sem enrolação, terminologia da bibliografia, termos-chave em **negrito**.
3. **Exemplo prático de engenharia.** Paralelo com arquitetura de software e ferramentas modernas (AWS, TypeScript, Next.js, NestJS, Prisma, microsserviços) quando fizer sentido.
4. **Conexão com a disciplina.** Em qual entrega do projeto isso é cobrado e como aplicar em Frevo.
5. **Verificação rápida.** 2–3 perguntas objetivas, encerrando *exclusivamente* com:
   > "Você gostaria de responder a essas questões para testar o entendimento, ou prefere que eu aprofunde algum ponto específico da explicação?"

**Conteúdo programático:** (1) interpretação × compilação, front-end × back-end; (2) análise léxica e sintática, algoritmos de geradores de parsers a partir de GLC, ênfase em parser combinators; (3) análise semântica: ambientes de tipos, regras de tipagem, verificação e inferência, semântica operacional via interpretadores; (4) RIs, otimização e geração de código: TAC para dataflow e transformações, LLTZ para geração de Michelson.

## 8. Referências

Referências de apoio; qualquer citação formal (capítulo, página, teorema) deve ser conferida na fonte antes de ir para relatório ou seminário.

- Aho, Lam, Sethi & Ullman — *Compilers: Principles, Techniques, and Tools*
- Cooper & Torczon — *Engineering a Compiler*
- Appel — *Modern Compiler Implementation in ML/Java*
- Pierce — *Types and Programming Languages* (central para T02)
- Nystrom — *Crafting Interpreters* (apoio prático ao interpretador)
- Oferta anterior: https://github.com/damorim/compilers-cin · https://www.youtube.com/playlist?list=PLYo1KpY72qAWRGJqsnG2jqocOQsNAo3cN
