# Frevo

Documentação de etapas do projeto da disciplina de Implementação de Linguagens de Programação, semestre 2026.2.

Este documento registra **o que precisou ser feito** em cada marco. É um registro de processo: descreve as atividades executadas e os artefatos gerados, não o conteúdo das escolhas. As decisões de projeto estão documentadas separadamente.

---

## Identificação

| Campo | Valor |
|---|---|
| Nome da linguagem | Frevo |
| Extensão de arquivo | `.frevo` |
| Linguagem de implementação (host) | Haskell |
| Estratégia de parsing | Parser combinators |
| Propósito | Geral |
| Paradigma | Imperativo |
| Sistema de tipos | Estático |
| Inspiração sintática | Python |

## Objetivo da linguagem

Frevo é uma linguagem de programação de propósito geral pensada para o **ensino de programação para crianças**, construída sobre o vocabulário e o modo de falar pernambucano.

A proposta parte da constatação de que a barreira inicial no aprendizado de programação não é apenas conceitual, mas linguística: as palavras-chave, os nomes de tipo e as mensagens de erro das linguagens de uso corrente estão em inglês e assumem vocabulário técnico prévio. Frevo substitui essa camada por termos que a criança já domina antes de sentar no computador, de modo que o nome da construção ensine o conceito em vez de exigir que ele já seja conhecido.

A linguagem segue a tradição didática do Portugol quanto ao caráter pedagógico, adota tipagem estática para que o erro seja apresentado ao aluno antes da execução, e mantém sintaxe de superfície próxima a Python para que a transição posterior para uma linguagem de uso profissional seja de baixo atrito.

---

## Como usar

Requer GHC e Cabal, instalados pelo [GHCup](https://www.haskell.org/ghcup/). Testado com GHC 9.10.3, a mesma versão do CI.

```sh
cabal build all                                  # compila
cabal run Frevo -- examples/03_feira.frevo       # imprime a AST do programa
cabal test                                       # roda a suíte de testes
scripts/verificar.sh                             # tudo o que o CI roda: build, testes, exemplos e lint
```

Em erro de sintaxe, o programa mostra linha, coluna e o trecho do código, e sai com código 1.

## Trabalhando com assistentes de IA

O contexto do projeto para qualquer assistente (Claude Code, Codex, Cursor, Copilot, Gemini…) está em [AGENTS.md](AGENTS.md). As regras ficam em [docs/regras/](docs/regras/) e os procedimentos (revisão de PR, guia de estudo) em [docs/procedimentos/](docs/procedimentos/). Se a sua ferramenta não lê `AGENTS.md` sozinha, peça para ela ler esse arquivo no começo da conversa.

## Decisões da Entrega 2

| Decisão | Escolha | Alternativa descartada |
|---|---|---|
| Estratégia de parsing | Parser combinators (Megaparsec), descida recursiva | Gerador (Happy/Alex): mais uma linguagem para aprender e erros piores |
| Classe da gramática | LL(1) no nível de tokens | LR: desnecessário, a gramática não tem recursão à esquerda depois da fatoração |
| Análise léxica | Integrada ao parser (scannerless) | Lexer separado: exigiria token com posição e instância de `Stream` |
| Precedência de operadores | Tabela declarativa (`makeExprParser`) | Uma função por nível: mesmo resultado, mais código |
| *Dangling else* | Todo bloco fecha com `cabousse` | Regra do "else mais próximo": deixa a ambiguidade na gramática |
| Fim de comando | Sem terminador | `;` ou quebra de linha significativa: mais uma regra para a criança errar |
| Erros | Mensagem do Megaparsec com linha e coluna | Camada própria de mensagens: mais código sem exigência do enunciado |

A gramática está em [docs/gramatica.ebnf](docs/gramatica.ebnf) e a especificação em [docs/especificacao.md](docs/especificacao.md).

---

## Entrega 1: Definição da linguagem

Marco sem exigência de implementação. O produto é a especificação da linguagem e sua defesa oral.

### 1.1 Delimitação de propósito e público-alvo

Caracterização do público (crianças em fase escolar), do contexto de uso (sala de aula, com o professor como usuário secundário) e da escolha de propósito geral contra propósito específico.

### 1.2 Definição de paradigma e modelo de tipagem

Escolha do paradigma e do modelo de tipagem, com antecipação das implicações de cada um sobre o interpretador a ser construído no terceiro marco.

### 1.3 Estudo da referência técnica

Análise de linguagem de referência com propósito pedagógico e tipagem estática comparáveis, para extrair o modelo de anotação de tipos, o formato de assinatura de função e a estratégia de delimitação de blocos.

### 1.4 Levantamento de vocabulário regional

Coleta ampla de expressões, verbos e interjeições do falar pernambucano, organizada por função sintática potencial em vez de por ordem alfabética.

### 1.5 Definição dos critérios de filtragem

Estabelecimento dos critérios que determinam se uma expressão levantada pode ou não se tornar lexema da linguagem, cobrindo restrições do analisador léxico, restrições de conjunto de caracteres, adequação de registro e custo de reserva de palavra.

### 1.6 Aplicação dos filtros e registro dos descartes

Passagem do vocabulário levantado pelos critérios definidos, com registro do motivo de descarte de cada expressão eliminada. O registro dos descartes é artefato de entrega, não subproduto.

### 1.7 Mapeamento de vocabulário para construções sintáticas

Associação de cada slot sintático da linguagem (declaração, condicional, laço, definição de função, retorno, entrada, saída) ao conjunto de candidatos aprovados nos filtros.

### 1.8 Fechamento da lista de expressões

Enumeração fechada das expressões suportadas: literais, variáveis, operações unárias e binárias, chamada de função, construção de coleção e indexação.

### 1.9 Fechamento da lista de comandos

Enumeração fechada dos comandos suportados diretamente pela linguagem, distinguindo o que é construção primitiva do que será função de biblioteca.

### 1.10 Delimitação da fronteira entre núcleo e biblioteca padrão

Definição explícita do corte entre o que a linguagem reconhece como construção sintática e o que é implementado como função da biblioteca padrão, com o critério do corte registrado.

### 1.11 Definição do sistema de tipos da primeira versão

Especificação dos tipos básicos e do tipo composto da primeira versão, incluindo os nomes de tipo na linguagem e o modelo de anotação (onde a anotação é obrigatória e onde o tipo é inferido).

### 1.12 Redação do banco de mensagens do compilador

Elaboração do vocabulário de erro por categoria de falha e dos textos de mensagem correspondentes, incluindo o formato de apresentação do erro ao aluno.

### 1.13 Escrita dos programas de exemplo

Produção dos três programas de exemplo exigidos, cobrindo em conjunto saída simples, controle de fluxo e uso da biblioteca padrão.

### 1.14 Nomeação da linguagem e definição da extensão

Escolha do nome da linguagem e da extensão de arquivo, necessários para nomear o repositório, os arquivos de exemplo e os artefatos subsequentes.

### 1.15 Montagem da apresentação

Preparação do material de apresentação no formato exigido (15 minutos de definição e 10 minutos de discussão) e ensaio cronometrado.

### 1.16 Preparação para a avaliação individual

Alinhamento entre os integrantes para que cada um consiga defender a totalidade das decisões do marco, e não apenas a parte que redigiu.

### 1.17 Versionamento

Publicação dos slides, dos programas de exemplo e dos documentos de especificação no repositório do grupo.

---

## Entrega 2: Gramática formal e parser

Marco de implementação. O produto é a gramática versionada, o parser funcional e a suíte de testes.

### 2.1 Preparação do repositório e do ambiente de build

Criação da estrutura de diretórios (`src/`, `test/`, `docs/`, `examples/`, `app/`), configuração do gerenciador de build com versão de compilador fixada, declaração das dependências de parsing e de teste, e verificação de que o ambiente compila de forma idêntica nas máquinas de todos os integrantes.

### 2.2 Redação da gramática formal

Escrita da gramática em EBNF e versionamento como arquivo em `docs/`. A gramática precede o código e funciona como contrato entre os integrantes que implementam módulos em paralelo.

### 2.3 Tratamento das construções críticas de ambiguidade

Resolução documentada da precedência e da associatividade dos operadores, e tratamento explícito do dangling else, com registro de como cada ambiguidade foi eliminada.

### 2.4 Declaração da estratégia de parsing

Registro formal da estratégia adotada e da classe de gramática correspondente, com a justificativa da escolha e as alternativas descartadas.

### 2.5 Definição da AST como tipo de dados

Implementação da árvore sintática abstrata como tipo de dados explícito da linguagem host, separada da gramática concreta. Elementos puramente sintáticos que não carregam semântica não aparecem na AST.

### 2.6 Implementação da camada léxica

Implementação do consumidor de espaço em branco e comentários, dos combinadores de lexema, do conjunto de palavras reservadas, do reconhecedor de identificadores e dos literais. Inclui o tratamento do conflito entre identificador e palavra reservada, e o tratamento de palavra reservada que é prefixo de identificador válido.

### 2.7 Implementação do parser de expressões

Construção do parser de expressões com tabela declarativa de precedência e associatividade, cobrindo operações unárias, binárias, chamada de função, literais de coleção e indexação.

### 2.8 Implementação do parser de comandos

Construção do parser de comandos e de blocos, cobrindo declaração, atribuição, condicional, laços, definição de função e retorno.

### 2.9 Integração e ponto de entrada

Montagem do parser completo do programa, com consumo de espaço inicial e exigência de fim de entrada, e implementação do executável de linha de comando que lê um arquivo e imprime a AST ou o erro.

### 2.10 Implementação da camada de reporte de erros

Rótulos em português nos parsers e ajuste da posição do erro de palavra reservada, para que a mensagem aponte linha e coluna do ponto exato da falha.

### 2.11 Suíte de testes: programas válidos

Escrita dos casos de programas sintaticamente válidos, com comparação estrutural contra a AST esperada. Verificar que o parse não falhou é insuficiente: o teste compara a árvore produzida.

### 2.12 Suíte de testes: programas inválidos

Escrita dos casos de rejeição obrigatória, cobrindo uso de palavra reservada como identificador, bloco sem terminador, operador sem operando e construções proibidas pela gramática.

### 2.13 Suíte de testes: casos de borda

Escrita dos casos de borda exigidos: arquivo vazio, expressões profundamente aninhadas geradas programaticamente, e prosa não fechada (a linguagem só tem comentário de linha).

### 2.14 Verificação dos erros com posição

Testes específicos que confirmam que o erro reportado aponta a linha e a coluna corretas, e não apenas que o parse falhou.

### 2.15 Validação dos programas de exemplo da Entrega 1

Execução do parser sobre os três programas de exemplo produzidos no primeiro marco, exigidos como aceitos pela checklist.

### 2.16 Redação do README

Documentação dos comandos de build, de execução e de teste na raiz do repositório, junto da tabela de decisões de projeto do marco.

### 2.17 Revisão da gramática contra a implementação

Conferência item a item entre o arquivo EBNF e o parser implementado, para garantir que a gramática versionada descreve o que o código de fato aceita.

### 2.18 Verificação final contra a checklist

Passagem explícita por cada item da checklist obrigatória do marco, com marcação de concluído ou pendente.

### 2.19 Preparação para a avaliação individual

Leitura cruzada do código entre os integrantes, de modo que cada um consiga explicar módulos que não escreveu.

---

## Artefatos por marco

| Marco | Artefato | Local |
|---|---|---|
| Entrega 1 | Especificação da linguagem | `docs/` |
| Entrega 1 | Registro de vocabulário e descartes | `docs/` |
| Entrega 1 | Programas de exemplo | `examples/` |
| Entrega 2 | Gramática formal em EBNF | `docs/` |
| Entrega 2 | AST, camada léxica e parser | `src/` |
| Entrega 2 | Executável de linha de comando | `app/` |
| Entrega 2 | Suíte de testes | `test/` |
| Entrega 2 | Instruções de build, execução e teste | `README.md` |

## Convenções de trabalho no repositório

| Item | Convenção |
|---|---|
| Repositório | Um único repositório Git por grupo |
| Branch principal | `main` sempre em estado que compila |
| Commits | Padrão Conventional Commits, pequenos e atômicos |
| Fluxo | Branch de feature com pull request; o CI valida build, testes, exemplos e lint |
| Histórico | Contribuição visível de todos os integrantes |
| Build | Nenhum artefato de build versionado |