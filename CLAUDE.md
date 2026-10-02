# Frevo — guia de trabalho para o Claude

Projeto da disciplina **Implementação de Linguagens de Programação / Compiladores** (prof. Rodrigo Bonifácio de Almeida). O grupo implementa a linguagem **Frevo** de forma incremental, em quatro entregas: definição da linguagem → gramática e parser → sistema de tipos e interpretador → RI, otimização e geração de código.

A avaliação de cada entrega é **oral e individual**. Código que roda não garante nota: o objetivo é que cada integrante consiga justificar decisões, alternativas e trade-offs. Isso governa tudo neste arquivo.

## 1. A linguagem

| Campo | Valor |
|---|---|
| Nome / extensão | Frevo / `.frevo` |
| Host | Haskell (Cabal, `base ^>=4.18` → GHC 9.6.x) |
| Estratégia de parsing | Parser combinators (Megaparsec + `parser-combinators`) |
| Propósito | Específico (DSL): ensino de programação para crianças, com vocabulário pernambucano |
| Paradigma | Imperativo |
| Sistema de tipos | Estático |
| Inspiração sintática | Python (superfície), blocos fechados por `cabousse` |
| Representação intermediária | TAC |
| Repositório | https://github.com/BrenoRev/Frevo |

**Vocabulário atual** (fonte: `reservedKeywords` em [src/Frevo/Parser.hs](src/Frevo/Parser.hs)):

| Função | Lexema |
|---|---|
| Tipos | `Numero` (int), `Quebrado` (real), `Prosa` (string), `Certeza` (bool), `Ruma de T` (lista), `Nadica` (unit) |
| Literais booleanos | `Certo`, `Errado` |
| Condicional | `se … então … sinão … cabousse` |
| Laços | `enquanto … faça … cabousse`, `pracada x em e faça … cabousse` |
| Controle | `poparrar` (break), `segue` (continue), `devolve` (return) |
| Função | `função nome(T x, …) -> T … cabousse` |
| Lógicos | `e`, `ou`, `nam` (negação) |
| Comentário | `#` até o fim da linha |

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
5. **Checklist antes de declarar pronto.** Passar item a item pela checklist da entrega (§5), marcando `[x]`/`[ ]` explicitamente.
6. **Não simplificar o problema para caber.** Nada de regex no lugar de parser, `eval` do host no lugar de interpretador, ou hardcode para passar em teste. Se algo for inviável, dizer e propor um recorte honesto — nunca um stub disfarçado.
7. **Testes fazem parte da entrega.** Casos válidos, inválidos (rejeição) e de borda. Parser sem teste de rejeição não está pronto.
8. **Idioma.** Respostas em português do Brasil. Identificadores Haskell em inglês. As palavras-chave e as mensagens de erro **da linguagem Frevo** são em português regional — isso é o propósito da linguagem, não uma violação da regra.
9. **Nunca entregar o que o integrante não conseguiria reescrever no quadro.** Preferir código direto a abstrações engenhosas (ex.: evitar extensões de tipo avançadas, lenses, free monads) a menos que o ganho seja defensável oralmente.
10. Uma pergunta de esclarecimento por vez, e só quando a ambiguidade impedir o trabalho.

## 3. Mapa do repositório

| Caminho | Conteúdo | Situação |
|---|---|---|
| [Frevo.cabal](Frevo.cabal) | Pacote; só o `executable Frevo` | Sem `library` e sem `test-suite`; referencia `LICENSE` e `CHANGELOG.md` inexistentes |
| [app/Main.hs](app/Main.hs) | CLI: lê arquivo, imprime AST ou erro | Funcional em estrutura |
| [src/Frevo/AST.hs](src/Frevo/AST.hs) | `Type`, `Op`, `Expr`, `Stmt` | Incompleta (§4) |
| [src/Frevo/Parser.hs](src/Frevo/Parser.hs) | Camada léxica + parser Megaparsec | Parcial; **erro de tipo em `pFor`** (§4) |
| [src/Frevo/Lexer.hs](src/Frevo/Lexer.hs) | Lexer manual (`String -> [Token]`) | Não usado pelo parser nem listado no Cabal (§4) |
| [src/Frevo/Syntax.hs](src/Frevo/Syntax.hs), [src/Frevo/Pretty.hs](src/Frevo/Pretty.hs) | — | Placeholders de uma linha, não são Haskell válido |
| [test/](test/) | `Spec.hs` + `Frevo/{Lexer,Expr,Stmt,Erro,RoundTrip}Spec.hs` | **Todos vazios (0 bytes)** |
| [examples/example.frevo](examples/example.frevo) | Exemplo completo com funções e tipos | Não é aceito pelo parser atual |
| [exemplo.frevo](exemplo.frevo) | Exemplo simples, na raiz | Deveria estar em `examples/` |
| `docs/` | Gramática, regras de tipagem, semântica | `gramatica.ebnf` está **vazio** |
| [README.md](README.md) | Registro de processo das entregas | Falta build/execução/teste e tabela de decisões |

**Comandos** (ainda não documentados no README; o `cabal test` só existirá após criar a stanza `test-suite`):

```sh
cabal build
cabal run Frevo -- examples/example.frevo
cabal test
```

## 4. Estado atual e por onde seguir

Levantado por leitura do código, **sem compilar** (GHC/Cabal não estavam instalados na máquina onde este arquivo foi escrito). Antes de qualquer trabalho, rodar `cabal build` e corrigir esta seção se ela estiver desatualizada.

**Entrega corrente: Entrega 2 (gramática + parser + testes).** A Entrega 3 depende dela e só começa quando a checklist da E2 fechar.

### Pendências verificadas no código

1. `pFor` constrói `SFor var body`, mas o construtor é `SFor String Expr [Stmt]` — o módulo não deve compilar; `iterable` está sem uso.
2. `em` não está em `reservedKeywords`, embora seja palavra-chave do `pracada`.
3. Parser não cobre: definição de função, declaração tipada, chamada de função, literal de lista, indexação, operadores unários (negação lógica e menos unário), `poparrar`, `segue`. A AST também não tem esses construtores.
4. `TArray` não carrega o tipo do elemento (`Ruma de Numero`).
5. A AST não guarda posição de origem — necessária para os erros de tipo com linha/coluna da Entrega 3.
6. `Lexer.hs` declara `module Lexer` em `src/Frevo/Lexer.hs` (nome não bate com o caminho) e tem `main` próprio.
7. Erros sintáticos saem pelo `errorBundlePretty` padrão; falta a camada com o banco de mensagens da Entrega 1.
8. `examples/example.frevo` diz "Linguagem Cordel" no cabeçalho e chama `buscarPrimeiroPositivo`, que não é definida.
9. A checklist pede **3** programas de exemplo; existem 2.
10. Código e exemplos divergem: negação (`nam` × `não`), `de` (sinônimo de `se` no parser × `Ruma de Numero`), `faça` no cabeçalho de função, declaração com e sem tipo. `Lexer.hs` e a camada léxica de `Parser.hs` duplicam o mesmo trabalho.

### Plano

1. Escrever `docs/gramatica.ebnf` — a gramática é o contrato entre os módulos — e alinhar código e exemplos a ela (pendência 10).
2. Fazer `main` compilar: corrigir `pFor`, limpar o Cabal, separar `library` / `executable` / `test-suite` (hspec + QuickCheck, conforme o README prevê).
3. Completar a AST (com posição) e o parser até aceitar os 3 exemplos.
4. Testes: válidos com AST esperada, inválidos, borda, erro com linha/coluna, round-trip via `Pretty.hs`.
5. Camada de mensagens de erro; README com build/run/test e tabela de decisões.
6. Conferir EBNF × parser e rodar a checklist da E2.

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

- [x] Propósito declarado e justificado (README)
- [x] Paradigma declarado
- [x] Sistema de tipos declarado, com trade-off
- [x] Inspiração sintática identificada
- [ ] Lista fechada de expressões — não há documento no repositório
- [ ] Lista fechada de *statements* — idem
- [ ] Fronteira núcleo × stdlib, com justificativa do corte — idem
- [ ] 3 programas de exemplo (hello world, controle de fluxo, stdlib) — há 2, nenhum hello world
- [ ] Cada integrante defende todas as decisões
- [ ] Slides e exemplos versionados — slides não estão no repositório

Os itens abertos da E1 são insumo direto da E2 (gramática) e da E3 (stdlib): fechar junto com a gramática.

### Entrega 2 — Gramática e parser

> **Enunciado:** Definição da gramática da linguagem e implementação do parser (incluindo suite de testes).

"Parser" aqui é o macrocomponente: análise léxica **e** sintática.

- [ ] Gramática formal (BNF/EBNF) versionada em `docs/`
- [ ] Sem ambiguidade nas construções críticas: precedência e associatividade documentadas; *dangling else* tratado explicitamente (resolvido pelo terminador `cabousse` obrigatório — documentar)
- [ ] Estratégia de parsing declarada e justificada, com a classe de gramática (LL(k), LR(1), PEG…)
- [ ] Tokens definidos: lexemas, palavras reservadas, literais, comentários, whitespace; conflito identificador × palavra-chave tratado (`rword` com `notFollowedBy` já existe — documentar)
- [ ] AST como tipo de dados explícito, separada da gramática concreta — existe, incompleta
- [ ] Testes em três categorias: válidos (AST esperada), inválidos (rejeição), borda (arquivo vazio, aninhamento profundo, comentário não fechado)
- [ ] Erros sintáticos com linha/coluna e mensagem inteligível
- [ ] Os 3 exemplos da Entrega 1 aceitos pelo parser
- [ ] Build e testes documentados no `README.md`

Observação: Frevo só tem comentário de linha (`#`), então "comentário não fechado" não se aplica como está. Cobrir o análogo (string não fechada) e registrar a justificativa.

### Entrega 3 — Sistema de tipos e interpretador

> **Enunciado:** Implementação do sistema de tipos e do interpretador para a linguagem.

- [ ] Regras de tipagem em notação de julgamentos (`Γ ⊢ e : τ`) para todas as construções, em documento próprio em `docs/`
- [ ] Ambiente de tipos Γ com escopo léxico correto (aninhamento, sombreamento)
- [ ] Type checker implementado; se houver inferência, algoritmo nomeado e justificado
- [ ] Erros de tipo com posição e tipo esperado × encontrado
- [ ] Semântica operacional documentada (small-step ou big-step, justificado), com correspondência regra ↔ código do interpretador
- [ ] Interpretador sobre a AST, com ambiente de execução separado do ambiente de tipos
- [ ] Erros de execução (divisão por zero, índice fora de faixa) tratados e distintos dos erros de tipo
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
