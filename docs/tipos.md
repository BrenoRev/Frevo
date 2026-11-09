# Frevo — sistema de tipos

Regras de tipagem da Entrega 3 e onde cada uma está no código. A implementação fica em `src/Frevo/`: `TypeEnv.hs` (ambiente Γ e erros), `Infer.hs` (expressões), `Statement.hs` (comandos) e `TypeChecker.hs` (programa inteiro e mensagens).

## Tipos

```
τ ::= Numero | Quebrado | Prosa | Certeza | Ruma de τ | Nadica
```

`Nadica` só aparece como retorno de função: a gramática não deixa escrever `Nadica` como tipo de variável, de parâmetro ou de item de `Ruma`.

## Ambiente Γ

```
Γ = (V ; Φ ; ρ ; λ)
```

| Componente | O que guarda | Campo de `Env` |
|---|---|---|
| V | variável ↦ tipo | `varEnv` |
| Φ | função ↦ (τ₁, …, τₙ) → τ | `funEnv` |
| ρ | tipo de retorno da função em que se está, ou ⊥ fora de função | `retType` |
| λ | ⊤ dentro de `enquanto`/`pracada`, ⊥ fora | `inLoop` |

`Γ[x ↦ τ]` acrescenta ou substitui `x` em V. No código, `withVar` faz isso com `local` da mônada Reader. Como `local` desfaz a mudança ao sair do bloco, o escopo léxico sai de graça: uma declaração dentro de `se`, `enquanto`, `pracada` ou função não vaza, e a variável sombreada volta a ter o tipo antigo depois do `cabousse`.

O programa começa em

```
Γ₀ = (∅ ; {pergunta : (Prosa) → Prosa, encanga : (Prosa, Prosa) → Prosa} ; ⊥ ; ⊥)
```

que é `stdlibEnv`. `espia` e `quantoTem` não estão em Φ, porque aceitam mais de um tipo e a linguagem não tem polimorfismo. Cada uma tem regra própria (T-Espia, T-Tam-R e T-Tam-P).

## Julgamentos

| Julgamento | Lê-se | Função |
|---|---|---|
| `Γ ⊢ e : τ` | e sintetiza o tipo τ | `infer` |
| `Γ ⊢ e ⇐ τ` | e é verificada contra τ, que já é conhecido | `check` |
| `Γ ⊢ s ⊣ Γ'` | o comando s está bem tipado e deixa Γ' para os comandos seguintes | uma cláusula de `checkBlock` |
| `Γ ⊢ s̄ ok` | a sequência de comandos está bem tipada | `checkBlock` |

**Algoritmo.** Não há inferência: toda variável, parâmetro e retorno é anotado. A checagem é dirigida pela sintaxe, de baixo para cima e numa passada só, sem unificação. O único ponto em que o tipo desce de fora para dentro é a lista vazia `[]`, que sozinha não diz o tipo dos elementos. Para ela existe o modo de verificação `⇐`, uma forma mínima de checagem bidirecional. A alternativa seria um tipo especial "lista de qualquer coisa" ou inferência de Hindley-Milner. As duas foram descartadas: custam mais código e mais teoria do que a única construção que precisa delas justifica.

Nas regras, `vazia(e)` vale quando e é `[]` ou uma lista cujos elementos são todos `vazia` (`[[]]`, `[[], []]`). No código, é `isEmptyList`.

## Expressões

```
                                         x : τ ∈ V
(T-Num) Γ ⊢ n : Numero         (T-Var) ───────────
(T-Que) Γ ⊢ r : Quebrado                Γ ⊢ x : τ
(T-Pro) Γ ⊢ "…" : Prosa
(T-Cer) Γ ⊢ Certo : Certeza     Γ ⊢ Errado : Certeza
```

```
         Γ ⊢ e : τ    τ ∈ {Numero, Quebrado}              Γ ⊢ e : Certeza
(T-Neg) ─────────────────────────────────────   (T-Nam) ───────────────────
                   Γ ⊢ −e : τ                            Γ ⊢ nam e : Certeza
```

```
           Γ ⊢ e₁ : τ    Γ ⊢ e₂ : τ    τ ∈ {Numero, Quebrado}    ⊕ ∈ {+, −, *, /}
(T-Arit) ────────────────────────────────────────────────────────────────────────
                                   Γ ⊢ e₁ ⊕ e₂ : τ

           Γ ⊢ e₁ : τ    Γ ⊢ e₂ : τ    τ ∈ {Numero, Quebrado}    ⊲ ∈ {<, <=, >, >=}
(T-Rel)  ────────────────────────────────────────────────────────────────────────
                                 Γ ⊢ e₁ ⊲ e₂ : Certeza

           Γ ⊢ e₁ : τ    Γ ⊢ e₂ : τ    τ ≠ Nadica
(T-Igual) ─────────────────────────────────────────
                  Γ ⊢ e₁ == e₂ : Certeza

           Γ ⊢ e₁ : Certeza    Γ ⊢ e₂ : Certeza    ∘ ∈ {e, ou}
(T-Lóg)  ──────────────────────────────────────────────────────
                       Γ ⊢ e₁ ∘ e₂ : Certeza
```

Não há conversão implícita entre `Numero` e `Quebrado`: `1 + 2.5` é erro (`InvalidOp`). A conversão automática é a principal fonte de surpresa em C e em JavaScript, e a regra estrita deixa o tipo de cada conta óbvio para quem está aprendendo. Em `==`, se um dos lados é `vazia`, ele é verificado contra o tipo sintetizado pelo outro lado (`xs == []`).

```
            eₖ é o primeiro elemento que não é vazia    Γ ⊢ eₖ : τ    τ ≠ Nadica
            para todo i:  Γ ⊢ eᵢ ⇐ τ  se vazia(eᵢ),   Γ ⊢ eᵢ : τ  caso contrário
(T-Ruma)  ─────────────────────────────────────────────────────────────────────────
                               Γ ⊢ [e₁, …, eₙ] : Ruma de τ
```

O primeiro elemento concreto é inferido uma vez só e não volta a ser comparado: inferi-lo de novo dobraria o custo a cada nível de aninhamento, e `[[[…[1]…]]]` levaria tempo exponencial. Com isso, a checagem visita cada nó da AST um número constante de vezes. Se todos os elementos são `vazia`, não há regra de síntese, e o erro é `EmptyList`. Elemento de tipo diferente dá `ArrayHeterogeneousType`, e elemento `Nadica` dá `VoidListElement`.

```
            f : (τ₁, …, τₙ) → τ ∈ Φ    para todo i: Γ ⊢ eᵢ ⇐ τᵢ
(T-Cham)  ──────────────────────────────────────────────────────
                         Γ ⊢ f(e₁, …, eₙ) : τ

             Γ ⊢ e : τ    τ ≠ Nadica
(T-Espia)  ──────────────────────────
             Γ ⊢ espia(e) : Nadica

               Γ ⊢ e : Ruma de τ                           Γ ⊢ e : Prosa
(T-Tam-R)  ───────────────────────────    (T-Tam-P)  ───────────────────────────
             Γ ⊢ quantoTem(e) : Numero                   Γ ⊢ quantoTem(e) : Numero
```

A aridade é conferida antes dos tipos dos argumentos (`ArityMismatch`). Um argumento de tipo errado dá `ArgMismatch`, que diz a posição do argumento ("o 2º argumento de f era pra ser Prosa, mas veio Numero"). A comparação é feita com o tipo do próprio argumento, sem capturar erro, então um erro dentro de uma chamada interna, como em `f(g("x"))`, continua sendo atribuído a `g`. Chamar uma função que ainda não foi definida é erro (`UndefinedFun`); ver S-Fun.

**Verificação** (`check`):

```
             vazia(eᵢ) e Γ ⊢ eᵢ ⇐ τ  para todo i                             Γ ⊢ e : τ    não vazia(e)
(C-Vazia) ───────────────────────────────────────────   (C-Sint) ──────────────────────────
                    Γ ⊢ [e₁, …, eₙ] ⇐ Ruma de τ                                  Γ ⊢ e ⇐ τ
```

Com n = 0, C-Vazia dá `Γ ⊢ [] ⇐ Ruma de τ`. Uma lista `vazia` verificada contra um tipo que não é `Ruma` dá `EmptyListMismatch`.

## Comandos

```
              Γ ⊢ e ⇐ τ                                  x : τ ∈ V    Γ ⊢ e ⇐ τ
(S-Decl) ─────────────────────────────     (S-Atrib) ───────────────────────────
          Γ ⊢ τ x = e  ⊣  Γ[x ↦ τ]                        Γ ⊢ x = e  ⊣  Γ

             Γ ⊢ f(ē) : τ    (τ pode ser Nadica)
(S-Cham) ─────────────────────────────────────────
                  Γ ⊢ f(ē)  ⊣  Γ
```

Declarar de novo uma variável no mesmo escopo é permitido e pode mudar o tipo dela dali em diante (sombreamento). A atribuição nunca muda o tipo.

```
          Γ ⊢ e ⇐ Certeza    Γ ⊢ s̄₁ ok    Γ ⊢ s̄₂ ok
(S-Se)  ─────────────────────────────────────────────────   (sem sinão: s̄₂ vazio)
          Γ ⊢ se e então s̄₁ sinão s̄₂ cabousse  ⊣  Γ

           Γ ⊢ e ⇐ Certeza    Γ[λ := ⊤] ⊢ s̄ ok
(S-Enq)  ────────────────────────────────────────
          Γ ⊢ enquanto e faça s̄ cabousse  ⊣  Γ

           Γ ⊢ e : Ruma de τ    Γ[x ↦ τ][λ := ⊤] ⊢ s̄ ok
(S-Pra)  ─────────────────────────────────────────────────
          Γ ⊢ pracada x em e faça s̄ cabousse  ⊣  Γ
```

A conclusão devolve o Γ de antes do bloco: o que foi declarado dentro some no `cabousse`. Em S-Pra, uma expressão que não é `Ruma` dá `NoIterable`.

```
              λ = ⊤                          λ = ⊤                     ρ = τ    τ ≠ Nadica    Γ ⊢ e ⇐ τ
(S-Pop) ──────────────────────  (S-Seg) ───────────────────  (S-Dev) ──────────────────────────────────
         Γ ⊢ poparrar  ⊣  Γ              Γ ⊢ segue  ⊣  Γ                  Γ ⊢ devolve e  ⊣  Γ
```

Com λ = ⊥, os erros são `BreakOutsideLoop` e `ContinueOutsideLoop`; com ρ = ⊥, `ReturnOutsideFunction`; com ρ = Nadica, `VoidReturn`. Como a gramática exige uma expressão depois de `devolve`, numa função `Nadica` ele só serviria para o truque `devolve espia(x)`. Por isso fica proibido, e a função `Nadica` termina sempre no `cabousse`. É uma limitação consciente: ela não tem saída antecipada, e o desvio se escreve com `se … sinão`. Permitir `devolve` sem expressão tornaria a gramática ambígua, porque o comando seguinte, que começa por um identificador, poderia ser lido como a expressão do `devolve`.

```
          f ∉ dom(Φ) ∪ {espia, quantoTem}      x₁, …, xₙ distintos
          Φ' = Φ[f ↦ (τ₁, …, τₙ) → τ]
          ({x₁ ↦ τ₁, …, xₙ ↦ τₙ} ; Φ' ; τ ; ⊥) ⊢ s̄ ok
          τ = Nadica  ou  devolve(s̄)
(S-Fun) ──────────────────────────────────────────────────────────────────
          Γ ⊢ função f(τ₁ x₁, …, τₙ xₙ) -> τ s̄ cabousse  ⊣  (V ; Φ' ; ρ ; λ)
```

- **f entra em Φ' antes do corpo,** o que permite recursão, e só vale do ponto da definição em diante. É a ordem em que o interpretador executa (X-Fun em [semantica.md](semantica.md)).
- **O corpo começa com V contendo só os parâmetros,** sem as variáveis do nível de topo. Os motivos estão na seção de soundness.
- **λ volta a ⊥ no corpo:** um `poparrar` ali nunca sai por um laço de fora.
- **Erros:** `DuplicateFun` (nome repetido ou nome da stdlib), `DuplicateParam` e `MissingReturn`.

`devolve(s̄)` (a função `alwaysReturns`) é uma aproximação conservadora de "todo caminho termina em `devolve`":

```
devolve(s̄)                       = existe s em s̄ com devolve₁(s)
devolve₁(devolve e)              = verdadeiro
devolve₁(se e então s̄₁ sinão s̄₂) = devolve(s̄₁) e devolve(s̄₂)
devolve₁(qualquer outro)         = falso
```

`enquanto` e `pracada` nunca contam, porque podem rodar zero vezes. Um `se` sem `sinão` também não conta.

**Sequência e programa:**

```
                          Γ ⊢ s ⊣ Γ'    Γ' ⊢ s̄ ok                Γ₀ ⊢ s̄ ok
(S-Vazio) Γ ⊢ ε ok   (S-Seq) ───────────────────────   (Prog) ─────────────────
                                 Γ ⊢ s s̄ ok                   ⊢ s̄ programa ok
```

## Posição nos erros

O parser embrulha cada comando em `SAt (linha, coluna)`. Ao checar um `SAt`, `atPos` anexa a posição a qualquer erro que ainda não tenha uma. O erro de uma expressão aponta o começo do comando que a contém. O erro de um comando dentro de um bloco aponta esse comando, não o bloco, porque a posição mais interna é anexada primeiro. A coluna conta TAB como 8, igual ao erro de sintaxe do Megaparsec. As mensagens em português ficam em `typeErrorMessage` (`TypeChecker.hs`).

## Soundness

**Afirmação.** Se `⊢ P programa ok`, a execução de P (ver [semantica.md](semantica.md)) nunca chega a `Stuck`. Ela termina normalmente, termina com um dos dois erros de execução previstos (divisão por zero, `pergunta` sem entrada) ou não termina. Não há prova formal. O argumento abaixo é o informal de progresso e preservação, regra a regra, e o construtor `Stuck` do interpretador marca exatamente os pontos que essa afirmação diz serem inalcançáveis.

| Regra | Por que é sound |
|---|---|
| T-Arit, T-Rel | Os dois operandos têm o mesmo tipo numérico. Em tempo de execução, os dois valores são `VInt` ou os dois são `VFloat`, e `binOp` tem um caso para cada combinação. |
| T-Igual | Exige o mesmo tipo e exclui `Nadica`. A igualdade estrutural de `Value` está definida para quaisquer dois valores de um mesmo tipo diferente de `Nadica`. |
| T-Lóg, S-Se, S-Enq | O operando ou a condição é `Certeza`, então `evalBool` sempre recebe `VBool`. |
| T-Ruma, S-Pra | Toda `Ruma` bem tipada vira `VList`, então `pracada` sempre recebe uma lista. |
| T-Cham | Aridade e tipo de cada argumento conferem com a assinatura em Φ, e a função está definida antes da chamada nos dois lados: na checagem por S-Fun, na execução por X-Fun. |
| S-Decl, S-Atrib | V associa a cada nome o tipo da declaração mais recente visível. A pilha de escopos do interpretador associa a cada nome o valor da declaração mais recente visível, e o tipo desse valor é o que V registrou. |
| S-Fun | Se o corpo enxergasse as variáveis do topo, este programa seria aceito: `Numero g = 1`, depois `função f() -> Numero devolve g cabousse`, depois `Prosa g = "a"`, depois `espia(f() + 1)`. Mas ele somaria `"a" + 1` ao rodar. Começar o corpo só com os parâmetros fecha esse buraco. |
| S-Pop, S-Seg, S-Dev | λ e ρ garantem que `poparrar`/`segue` só aparecem dentro de laço e `devolve` só dentro de função, então o desvio sempre tem quem o trate (`loopStep`, `callUser`). |
| `devolve(s̄)` | Sound: se a análise diz que todo caminho devolve, todo caminho que termina devolve, e uma função não `Nadica` nunca entrega `VUnit` a quem a chamou. É **incompleta**, ou seja, rejeita programas seguros como `função f() -> Numero enquanto Certo faça devolve 1 cabousse cabousse`. O trade-off é o mesmo do Java: uma análise exata exigiria decidir se o laço termina, o que é indecidível. |

**Onde o sistema de tipos não protege:**

- **Divisão por zero.** O tipo não diz se o divisor é zero. É um erro de execução previsto (`DivByZero`), não um `Stuck`.
- **`pergunta` sem entrada.** Depende do mundo externo; é erro de execução (`NoInput`).
- **`Quebrado` fora da faixa do Double.** `1.0e300 * 1.0e300` vira infinito, e infinito menos infinito vira NaN. Continua sendo `Quebrado` e não trava; é a semântica do IEEE 754. O literal que já nasce infinito (`1e400`) é rejeitado pelo parser, assim como expoente com mais de três dígitos.
- **Terminação.** Um `enquanto Certo` sem `poparrar` roda para sempre. Tipagem estática simples não garante terminação.
