# Frevo — especificação da linguagem

## Decisões

| Questão | Decisão | Por quê |
|---|---|---|
| Propósito | Geral, pensada para o ensino de programação para crianças | Nenhuma construção é presa a um domínio: variáveis, condicional, laços, funções e listas servem a qualquer programa. O público motiva o vocabulário, que é o falar pernambucano que a criança já conhece, e não restringe o que dá para escrever. |
| Paradigma | Imperativo | É o modelo de "faça isto, depois aquilo" que se ensina primeiro. O interpretador será um ambiente de variáveis mais um laço sobre comandos. |
| Sistema de tipos | Estático, com anotação obrigatória | O erro aparece antes de rodar, com uma mensagem que o professor lê em sala. Custa um type checker; dispensa inferência. |
| Inspiração sintática | Python | Sintaxe de superfície enxuta, comentário com `#`. Os blocos fecham com `cabousse` em vez de indentação, o que mantém a gramática livre de contexto. |

## Tipos

| Tipo | Nome | Literal |
|---|---|---|
| Inteiro | `Numero` | `42` |
| Real | `Quebrado` | `1.75` |
| String | `Prosa` | `"oxe"` |
| Booleano | `Certeza` | `Certo`, `Errado` |
| Lista | `Ruma de T` | `[1, 2, 3]` |
| Sem valor | `Nadica` | só como retorno de função |

## Expressões

Lista fechada:

1. Literal: inteiro, real, string, booleano.
2. Variável.
3. Lista: `[e1, e2, …]`.
4. Chamada de função: `f(e1, e2, …)`.
5. Aritmética: `+`, `-`, `*`, `/` e `-` unário.
6. Comparação: `==`, `<`, `<=`, `>`, `>=`.
7. Lógica: `e`, `ou`, `nam`.
8. Parênteses.

## Comandos

Lista fechada:

1. Declaração: `Numero x = 0`. Pode repetir o nome de uma variável do mesmo escopo: a nova declaração substitui a anterior, inclusive o tipo.
2. Atribuição: `x = x + 1`.
3. Chamada de função: `espia(x)`.
4. Condicional: `se … então … sinão … cabousse`.
5. Laço condicional: `enquanto … faça … cabousse`.
6. Laço sobre lista: `pracada x em xs faça … cabousse`.
7. `poparrar` (sai do laço) e `segue` (próxima volta).
8. Definição de função: `função f(Numero x) -> Numero … cabousse`, só no nível de topo. A função vale da definição em diante e dentro do próprio corpo (recursão); o corpo só enxerga os parâmetros. Duas funções com o mesmo nome são erro.
9. Retorno: `devolve e`.

## Execução

As regras formais estão em [tipos.md](tipos.md) e [semantica.md](semantica.md). As decisões que uma criança percebe ao rodar um programa:

| Questão | Decisão |
|---|---|
| Ordem | O programa inteiro é checado antes de rodar. Com erro de tipo, nenhuma linha executa. |
| `Numero` | Inteiro sem limite de tamanho. |
| `/` | Em `Numero`, arredonda para baixo (`7 / 2` é 3, `-7 / 2` é -4); em `Quebrado`, divisão real. Divisão por zero é erro nos dois. |
| Misturar `Numero` e `Quebrado` | Erro de tipo: `1 + 2.5` não é aceito. |
| `e`, `ou` | O lado direito só é avaliado se o esquerdo não decidir o resultado. |
| Escopo | Declaração dentro de `se`, `enquanto`, `pracada` ou função vale até o `cabousse`; atribuição muda a variável de fora. Declarar de novo o mesmo nome é permitido e esconde o anterior. |
| Função | Vale da definição para baixo (e dentro dela mesma, para recursão). O corpo enxerga só os parâmetros. Se não é `Nadica`, todo caminho termina em `devolve`; se é `Nadica`, não usa `devolve` e termina no `cabousse`. |
| `pracada` | A ruma é lida uma vez, antes da primeira volta. |

## Núcleo e biblioteca padrão

Entra no núcleo o que precisa de sintaxe própria ou muda o fluxo de execução. Todo o resto é função comum: não reserva palavra, não aumenta a gramática e pode crescer sem mexer no parser.

| Função | O que faz |
|---|---|
| `espia(x)` | Escreve um valor de qualquer tipo na tela e pula a linha. |
| `pergunta(texto)` | Mostra o texto e lê uma linha do teclado como `Prosa`. Sem entrada, é erro de execução. |
| `encanga(a, b)` | Junta duas `Prosa`. |
| `quantoTem(xs)` | Tamanho de uma `Ruma` (itens) ou de uma `Prosa` (caracteres Unicode: `"ação"` tem 4). |

Nenhuma dessas é palavra reservada, mas os quatro nomes não podem ser usados para uma função do programa.

## O que ficou de fora

O levantamento de vocabulário está em [lexico-linguagem-pernambucana.pdf](lexico-linguagem-pernambucana.pdf). Em relação a ele:

| Cortado | Motivo |
|---|---|
| `bota`, `crava` | A declaração começa pelo tipo; uma palavra para declarar seria redundante. |
| `pronto`, `ai`, `ensina`, `entrega`, `num` | O grupo fechou `cabousse`, `então`, `função`, `devolve` e `nam`. |
| `ousse` (senão-se), `arrudeia`, `visse` | Açúcar sintático: `se` aninhado e `enquanto` já resolvem. |
| Operadores em palavra (`mais`, `vez`) | Reservariam palavras comuns da fala infantil. |
| `!=`, `%`, indexação `xs[i]` | `nam (a == b)` e `pracada` cobrem o uso; menos construções para tipar e interpretar. |
| `Vaique`, `Massa`/`Aperreio`, módulos, bloco de teste | Tipos e recursos avançados, fora da primeira versão. |

As palavras reservadas mantêm o acento (`função`, `então`, `sinão`, `faça`), contra o filtro 2 do levantamento: o grupo preferiu a grafia correta, que é a que a criança aprende na escola, ao custo de exigir arquivo em UTF-8.
