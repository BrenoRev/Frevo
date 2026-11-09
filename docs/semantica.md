# Frevo — semântica operacional

Semântica do interpretador da Entrega 3, em estilo **big-step** (semântica natural). A implementação é `src/Frevo/Interpreter.hs`, e a tabela no fim liga cada regra à função que a implementa.

## Por que big-step

| | Big-step (escolhida) | Small-step |
|---|---|---|
| Forma | `⟨s, σ⟩ ⇓ ⟨o, σ'⟩`: o comando roda até o fim e diz como terminou | `⟨s, σ⟩ → ⟨s', σ'⟩`: um passo de reescrita por vez |
| Código | Uma função recursiva por categoria sintática (`eval`, `exec`), com uma cláusula por regra | Uma máquina que reescreve o termo, com contextos de avaliação ou continuações para `poparrar` e `devolve` |
| Não terminação | Não distingue de programa travado: nos dois casos não há derivação | Distingue: sequência infinita de passos × termo que não dá passo |
| Concorrência e intercalação | Não modela | Modela |

A Frevo não tem concorrência nem ordem de avaliação sutil, e o professor cobra a correspondência entre regra e código. A big-step dá essa correspondência quase linha a linha. O preço é a linha "Não terminação": a semântica não diz nada sobre um `enquanto Certo` sem saída. O interpretador simplesmente não termina, que é o comportamento esperado.

Para `poparrar`, `segue` e `devolve`, a execução de um comando termina com um **resultado** o, em vez de lançar uma exceção do Haskell, como o *Crafting Interpreters* faz com exceções Java. Isso deixa o desvio de fluxo visível nas regras e no tipo `Outcome`.

## Domínios

```
v ::= n | r | "…" | Certo | Errado | [v₁, …, vₙ] | nadica     valores       (Value)
o ::= normal | poparrar | segue | devolve v                    resultados    (Outcome)
σ ::= φ₁ · φ₂ · … · φₖ                                         pilha de escopos, o mais interno à esquerda
φ ::= {x ↦ v, …}                                               um escopo
F ::= {f ↦ (x₁…xₙ, s̄), …}                                      funções definidas
```

`n` é um inteiro **sem limite de tamanho** (`Integer` do Haskell, como o `int` do Python). `r` é um Double do IEEE 754. `nadica` é o que uma função `Nadica` entrega; o sistema de tipos impede que ele seja usado como valor.

A configuração completa é `⟨termo, σ, F, ι, ο⟩`, onde ι é a entrada que falta ler e ο é a saída já escrita. Nas regras, F, ι e ο ficam omitidos onde não mudam.

**Operações na pilha:**

```
σ(x)               valor de x no escopo mais à esquerda que tem x            lookupVar
(φ · σ)[x := v]    φ[x ↦ v] · σ          (declarar: sempre no topo)         declare
σ[x ← v]           troca x no escopo mais à esquerda que tem x               assign
                   (atribuir: pode ser um escopo de fora do bloco atual)
```

**Erros.** Além de valores, uma avaliação pode terminar em `erro(divisão por zero)` ou `erro(sem entrada)`. Vale uma regra de propagação: se uma premissa termina em erro, a conclusão termina no mesmo erro, e nada depois dela é avaliado. Em vez de repetir isso em cada regra, o código usa a mônada `ExceptT`.

## Expressões: `⟨e, σ⟩ ⇓ v`

```
(E-Lit)  ⟨n, σ⟩ ⇓ n    ⟨r, σ⟩ ⇓ r    ⟨"…", σ⟩ ⇓ "…"    ⟨Certo, σ⟩ ⇓ Certo    ⟨Errado, σ⟩ ⇓ Errado

                σ(x) = v                    ⟨eᵢ, σ⟩ ⇓ vᵢ  (i = 1…n, da esquerda para a direita)
(E-Var)  ───────────────     (E-Ruma) ─────────────────────────────────────────────────────
          ⟨x, σ⟩ ⇓ v                          ⟨[e₁, …, eₙ], σ⟩ ⇓ [v₁, …, vₙ]

           ⟨e, σ⟩ ⇓ v                          ⟨e, σ⟩ ⇓ b
(E-Neg)  ──────────────────      (E-Nam)  ─────────────────────
          ⟨−e, σ⟩ ⇓ −v                     ⟨nam e, σ⟩ ⇓ ¬b
```

**Lógicos, em curto-circuito.** O lado direito só é avaliado quando decide o resultado:

```
              ⟨e₁, σ⟩ ⇓ Errado                          ⟨e₁, σ⟩ ⇓ Certo    ⟨e₂, σ⟩ ⇓ b
(E-E-Curto) ──────────────────────────     (E-E)    ─────────────────────────────────
             ⟨e₁ e e₂, σ⟩ ⇓ Errado                       ⟨e₁ e e₂, σ⟩ ⇓ b

              ⟨e₁, σ⟩ ⇓ Certo                           ⟨e₁, σ⟩ ⇓ Errado    ⟨e₂, σ⟩ ⇓ b
(E-Ou-Curto) ─────────────────────────     (E-Ou)   ──────────────────────────────────
             ⟨e₁ ou e₂, σ⟩ ⇓ Certo                       ⟨e₁ ou e₂, σ⟩ ⇓ b
```

Com isso, `Errado e 1 / 0 == 1` vale `Errado` sem erro, como em Python, Java e C.

**Aritmética e comparação**, com os dois operandos avaliados da esquerda para a direita:

```
            ⟨e₁, σ⟩ ⇓ v₁    ⟨e₂, σ⟩ ⇓ v₂    v = v₁ ⊕ v₂    (⊕ ∈ {+, −, *}, ou / com v₂ ≠ 0)
(E-Arit)  ─────────────────────────────────────────────────────────────────────────────
                                 ⟨e₁ ⊕ e₂, σ⟩ ⇓ v

            ⟨e₁, σ⟩ ⇓ v₁    ⟨e₂, σ⟩ ⇓ 0
(E-Div0)  ─────────────────────────────────────
           ⟨e₁ / e₂, σ⟩ ⇓ erro(divisão por zero)

            ⟨e₁, σ⟩ ⇓ v₁    ⟨e₂, σ⟩ ⇓ v₂    b = (v₁ ⊲ v₂)    ⊲ ∈ {==, <, <=, >, >=}
(E-Comp)  ─────────────────────────────────────────────────────────────────────
                                 ⟨e₁ ⊲ e₂, σ⟩ ⇓ b
```

- **`/` em `Numero`** arredonda para baixo, como o `//` do Python: `7 / 2 = 3` e `-7 / 2 = -4`. Em `Quebrado` é a divisão real.
- **Divisão por zero é erro nos dois tipos,** inclusive `1.5 / 0.0`, que no IEEE 754 daria infinito. Para uma criança, "divisão por zero" ensina mais do que `Infinity`.
- **`==` é igualdade estrutural:** duas rumas são iguais quando têm os mesmos itens na mesma ordem.

## Chamadas

Os argumentos são avaliados da esquerda para a direita, e depois:

```
             f ↦ (x₁…xₙ, s̄) ∈ F    ⟨eᵢ, σ⟩ ⇓ vᵢ    ⟨s̄, {x₁ ↦ v₁, …, xₙ ↦ vₙ}⟩ ⇓ ⟨devolve v, σ'⟩
(E-Cham)   ─────────────────────────────────────────────────────────────────────────────────
                                      ⟨f(e₁, …, eₙ), σ⟩ ⇓ v

             mesmas premissas, mas o corpo termina em ⟨normal, σ'⟩
(E-ChamN)  ──────────────────────────────────────────────────────    (só função Nadica, garantido pela checagem)
                        ⟨f(e₁, …, eₙ), σ⟩ ⇓ nadica
```

O corpo roda numa pilha que tem **só os parâmetros**, a mesma escolha do sistema de tipos (S-Fun em [tipos.md](tipos.md)). A pilha σ de quem chamou volta intacta no fim: σ' é descartada.

**Stdlib** (ι é a entrada, ο a saída, `·` é concatenação):

```
(E-Espia)        ⟨espia(v), ο⟩ ⇓ ⟨nadica, ο · texto(v) · "\n"⟩
(E-Pergunta)     ⟨pergunta(p), ι = l · ι', ο⟩ ⇓ ⟨l, ι', ο · p⟩
(E-PerguntaFim)  ⟨pergunta(p), ι = ε, ο⟩ ⇓ erro(sem entrada)
(E-Encanga)      ⟨encanga(a, b)⟩ ⇓ a · b
(E-Tamanho)      ⟨quantoTem([v₁, …, vₙ])⟩ ⇓ n        ⟨quantoTem(s)⟩ ⇓ número de caracteres de s
```

`texto(v)` (a função `render`) escreve `Numero` em decimal, `Quebrado` sem notação científica (`0.01`, não `1.0e-2`), `Prosa` sem aspas, `Certo`/`Errado`, e `Ruma` como `[1, 2]`. Dentro de uma ruma, a prosa aparece entre aspas, para não se confundir com a vírgula. `quantoTem` conta caracteres Unicode (code points), não bytes: `quantoTem("ação")` vale 4 com os acentos compostos, que é como os editores costumam salvar. A mesma palavra com o acento decomposto (letra + acento separado) vale 6.

## Comandos: `⟨s, σ⟩ ⇓ ⟨o, σ'⟩`

```
              ⟨e, σ⟩ ⇓ v                                 ⟨e, σ⟩ ⇓ v    x ∈ σ
(X-Decl)  ───────────────────────────────    (X-Atrib) ──────────────────────────────
           ⟨τ x = e, σ⟩ ⇓ ⟨normal, σ[x := v]⟩           ⟨x = e, σ⟩ ⇓ ⟨normal, σ[x ← v]⟩

             ⟨f(ē), σ⟩ ⇓ v
(X-Cham)  ────────────────────────     (X-Fun)  ⟨função f(… x̄) -> τ s̄ cabousse, F⟩ ⇓ ⟨normal, F[f ↦ (x̄, s̄)]⟩
           ⟨f(ē), σ⟩ ⇓ ⟨normal, σ⟩

(X-Pop)  ⟨poparrar, σ⟩ ⇓ ⟨poparrar, σ⟩     (X-Seg)  ⟨segue, σ⟩ ⇓ ⟨segue, σ⟩

              ⟨e, σ⟩ ⇓ v
(X-Dev)   ─────────────────────────────
           ⟨devolve e, σ⟩ ⇓ ⟨devolve v, σ⟩
```

**Blocos abrem escopo.** O corpo roda com um escopo vazio no topo, que é retirado no fim (`inScope`). O que foi declarado dentro some, e o que foi atribuído a variáveis de fora fica:

```
           ⟨e, σ⟩ ⇓ Certo    ⟨s̄₁, ∅ · σ⟩ ⇓ ⟨o, φ · σ'⟩              ⟨e, σ⟩ ⇓ Errado    ⟨s̄₂, ∅ · σ⟩ ⇓ ⟨o, φ · σ'⟩
(X-SeV)  ───────────────────────────────────────────    (X-SeF) ───────────────────────────────────────────
          ⟨se e então s̄₁ sinão s̄₂ cabousse, σ⟩ ⇓ ⟨o, σ'⟩          ⟨se e então s̄₁ sinão s̄₂ cabousse, σ⟩ ⇓ ⟨o, σ'⟩
```

Sem `sinão`, X-SeF vira `⟨…, σ⟩ ⇓ ⟨normal, σ⟩`.

**Laços.** Uma volta roda o corpo num escopo novo. O resultado da volta decide se o laço continua:

```
              ⟨e, σ⟩ ⇓ Errado
(X-EnqF)  ─────────────────────────────────────
           ⟨enquanto e faça s̄ cabousse, σ⟩ ⇓ ⟨normal, σ⟩

              ⟨e, σ⟩ ⇓ Certo    ⟨s̄, ∅ · σ⟩ ⇓ ⟨o, φ · σ₁⟩    o ∈ {normal, segue}    ⟨enquanto e faça s̄ cabousse, σ₁⟩ ⇓ ⟨o', σ₂⟩
(X-EnqV)  ────────────────────────────────────────────────────────────────────────────────────────────────────────────
                                         ⟨enquanto e faça s̄ cabousse, σ⟩ ⇓ ⟨o', σ₂⟩

              ⟨e, σ⟩ ⇓ Certo    ⟨s̄, ∅ · σ⟩ ⇓ ⟨poparrar, φ · σ₁⟩
(X-EnqP)  ───────────────────────────────────────────────────────
           ⟨enquanto e faça s̄ cabousse, σ⟩ ⇓ ⟨normal, σ₁⟩

              ⟨e, σ⟩ ⇓ Certo    ⟨s̄, ∅ · σ⟩ ⇓ ⟨devolve v, φ · σ₁⟩
(X-EnqD)  ───────────────────────────────────────────────────────
           ⟨enquanto e faça s̄ cabousse, σ⟩ ⇓ ⟨devolve v, σ₁⟩
```

`pracada` avalia a ruma **uma vez só**, antes da primeira volta, e cada volta declara x num escopo novo:

```
             ⟨e, σ⟩ ⇓ [v₁, …, vₙ]    ⟨x, s̄, [v₁, …, vₙ], σ⟩ ⇓ₚ ⟨o, σ'⟩
(X-Pra)   ────────────────────────────────────────────────────────────
                ⟨pracada x em e faça s̄ cabousse, σ⟩ ⇓ ⟨o, σ'⟩

(P-Fim)   ⟨x, s̄, [], σ⟩ ⇓ₚ ⟨normal, σ⟩

             ⟨s̄, {x ↦ v₁} · σ⟩ ⇓ ⟨o, φ · σ₁⟩    o ∈ {normal, segue}    ⟨x, s̄, [v₂, …, vₙ], σ₁⟩ ⇓ₚ ⟨o', σ₂⟩
(P-Volta) ───────────────────────────────────────────────────────────────────────────────────────────
                                    ⟨x, s̄, [v₁, …, vₙ], σ⟩ ⇓ₚ ⟨o', σ₂⟩
```

Com `poparrar` ou `devolve v` no corpo, valem regras análogas a X-EnqP e X-EnqD. Mudar a variável da ruma dentro do corpo não muda as voltas que faltam.

**Sequência:**

```
                                  ⟨s, σ⟩ ⇓ ⟨normal, σ₁⟩    ⟨s̄, σ₁⟩ ⇓ ⟨o, σ₂⟩              ⟨s, σ⟩ ⇓ ⟨o, σ₁⟩    o ≠ normal
(X-Vazio) ⟨ε, σ⟩ ⇓ ⟨normal, σ⟩   (X-Seq) ──────────────────────────────────────   (X-Desvio) ─────────────────────────────
                                         ⟨s s̄, σ⟩ ⇓ ⟨o, σ₂⟩                                 ⟨s s̄, σ⟩ ⇓ ⟨o, σ₁⟩
```

**Programa:** o nível de topo roda em `⟨s̄, ∅, F = ∅, ι, ο = ε⟩`. A saída do programa é o ο final; um erro encerra a execução e mantém o que já foi escrito.

**Posição.** O comando `SAt (linha, coluna)` não muda a semântica: `⟨SAt p s, σ⟩` se avalia como `⟨s, σ⟩`, e só um erro saindo de s ganha a posição p, se ainda não tiver uma (`atPos`).

## Separação entre execução e tipos

O ambiente de execução (σ e F, no registro `Store`) é outro tipo de dado, em outro módulo, do ambiente de tipos Γ (`Env`, em `TypeEnv.hs`). Γ associa nomes a **tipos** e é imutável, numa mônada Reader. σ associa nomes a **valores** e muda a cada atribuição, numa mônada State. A checagem roda antes, sobre o programa inteiro (`checkAndRun` em `app/Main.hs`): um programa mal tipado não executa nem a primeira linha.

Os erros também são de tipos diferentes. `TypeError` é o que a checagem acusa. `RuntimeError` é o que só aparece rodando: `DivByZero` e `NoInput`. O construtor `Stuck` representa o programa travado da semântica operacional, o caso em que nenhuma regra se aplica (somar `Prosa` com `Numero`, usar uma variável que não existe). Se o sistema de tipos é sound (ver [tipos.md](tipos.md)), `Stuck` nunca acontece num programa que passou pela checagem. Os testes mostram que ele acontece quando a checagem é pulada.

## Regra ↔ código

Tudo em `src/Frevo/Interpreter.hs`, salvo indicação.

| Regra | Onde |
|---|---|
| E-Lit, E-Var, E-Ruma, E-Neg, E-Nam | cláusulas de `eval`; E-Var usa `lookupVar` |
| E-E-Curto, E-E, E-Ou-Curto, E-Ou | `eval (EBinOp And …)` e `eval (EBinOp Or …)` |
| E-Arit, E-Comp | `eval (EBinOp op …)` → `binOp` → `numOp` (`div` para `Numero`, `/` para `Quebrado`) |
| E-Div0 | `binOp Div (VInt _) (VInt 0)` e `binOp Div (VFloat _) (VFloat 0)` |
| E-Cham, E-ChamN | `evalCall` → `call` → `callUser` |
| E-Espia, E-Pergunta, E-PerguntaFim, E-Encanga, E-Tamanho | cláusulas de `call` com o nome da função; texto(v) é `render` |
| X-Decl, X-Atrib | `exec (SDecl …)` com `declare`; `exec (SAssign …)` com `assign` |
| X-Cham, X-Fun, X-Pop, X-Seg, X-Dev | cláusulas de `exec` |
| X-SeV, X-SeF | `exec (SIf …)` com `inScope` |
| X-EnqF, X-EnqV, X-EnqP, X-EnqD | `exec (SWhile …)` e `loopStep` |
| X-Pra, P-Fim, P-Volta | `exec (SFor …)`, `forEach` e `loopStep` |
| X-Vazio, X-Seq, X-Desvio | `execStmts` |
| Propagação de erro | mônada `ExceptT RuntimeError`; posição em `atPos` |
| Programa | `runProgram`; a ordem checagem → execução está em `app/Main.hs` |
