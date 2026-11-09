module Frevo.StatementSpec (spec) where

import qualified Data.Map as M
import Frevo.AST
import Frevo.Statement (checkBlock)
import Frevo.TypeEnv
import Test.Hspec

checkStmts :: [Stmt] -> Either TypeError ()
checkStmts stmts = runTC (checkBlock stmts) emptyEnv

spec :: Spec
spec = do
  describe "declaração e atribuição" $ do
    it "aceita declaração e reatribuição com o mesmo tipo" $
      checkStmts
        [ SDecl TInt "x" (EInt 10)
        , SAssign "x" (EBinOp Add (EVar "x") (EInt 5))
        ]
        `shouldBe` Right ()

    it "aceita lista vazia simples e aninhada herdando o tipo declarado" $ do
      checkStmts [SDecl (TArray TInt) "xs" (EList [])]
        `shouldBe` Right ()
      checkStmts [SDecl (TArray (TArray TStr)) "m" (EList [EList []])]
        `shouldBe` Right ()

    it "aceita reatribuir lista vazia a uma variável Ruma de T já existente" $
      checkStmts
        [ SDecl (TArray TInt) "xs" (EList [EInt 1, EInt 2])
        , SAssign "xs" (EList [])
        ]
        `shouldBe` Right ()

    it "permite sombreamento no mesmo escopo mudando o tipo" $
      checkStmts
        [ SDecl TInt "x" (EInt 1)
        , SDecl TStr "x" (EStr "oxe")
        , SAssign "x" (EStr "massa")
        ]
        `shouldBe` Right ()

    it "rejeita declaração quando o tipo da expressão não bate com o anotado" $
      checkStmts [SDecl TInt "x" (EStr "errado")]
        `shouldBe` Left (TypeMismatch TInt TStr)

    it "rejeita declaração de lista heterogênea" $
      checkStmts [SDecl (TArray TInt) "xs" (EList [EInt 1, EBool True])]
        `shouldBe` Left (ArrayHeterogeneousType TInt TBool)

    it "rejeita atribuição a variável não declarada" $
      checkStmts [SAssign "naoExiste" (EInt 1)]
        `shouldBe` Left (UndefinedVar "naoExiste")

    it "rejeita atribuição que tenta mudar o tipo da variável" $
      checkStmts
        [ SDecl TInt "x" (EInt 1)
        , SAssign "x" (EBool True)
        ]
        `shouldBe` Left (TypeMismatch TInt TBool)

  describe "condicional e isolamento de escopo" $ do
    it "aceita condicional com condição booleana com e sem sinão" $ do
      checkStmts [SIf (EBool True) [SDecl TInt "x" (EInt 1)] Nothing]
        `shouldBe` Right ()
      checkStmts [SIf (EBool False) [SDecl TInt "x" (EInt 1)] (Just [SDecl TInt "y" (EInt 2)])]
        `shouldBe` Right ()

    it "rejeita condicional cuja condição não é Certeza" $
      checkStmts [SIf (EInt 1) [] Nothing]
        `shouldBe` Left (TypeMismatch TBool TInt)

    it "não vaza variável declarada dentro do ramo então para fora do cabousse" $
      checkStmts
        [ SIf (EBool True) [SDecl TInt "interna" (EInt 1)] Nothing
        , SAssign "interna" (EInt 2)
        ]
        `shouldBe` Left (UndefinedVar "interna")

    it "não vaza variável declarada no ramo então para o ramo sinão" $
      checkStmts
        [ SIf
            (EBool True)
            [SDecl TInt "soNoEntao" (EInt 1)]
            (Just [SAssign "soNoEntao" (EInt 2)])
        ]
        `shouldBe` Left (UndefinedVar "soNoEntao")

    it "restaura o tipo da variável externa após sombreamento dentro do se" $
      checkStmts
        [ SDecl TInt "x" (EInt 10)
        , SIf
            (EBool True)
            [ SDecl TStr "x" (EStr "sombreada")
            , SAssign "x" (EStr "ainda prosa")
            ]
            Nothing
        , SAssign "x" (EInt 20)
        ]
        `shouldBe` Right ()

  describe "laços e controle de fluxo" $ do
    it "aceita enquanto com condição booleana e comandos poparrar/segue" $
      checkStmts
        [ SWhile
            (EBool True)
            [ SIf (EBool False) [SContinue] (Just [SBreak])
            ]
        ]
        `shouldBe` Right ()

    it "rejeita enquanto com condição não booleana" $
      checkStmts [SWhile (EStr "loop") []]
        `shouldBe` Left (TypeMismatch TBool TStr)

    it "aceita pracada sobre Ruma e expõe a variável de iteração no corpo" $
      checkStmts
        [ SDecl (TArray TFloat) "precos" (EList [EFloat 4.5, EFloat 6.0])
        , SDecl TFloat "total" (EFloat 0.0)
        , SFor
            "preco"
            (EVar "precos")
            [ SAssign "total" (EBinOp Add (EVar "total") (EVar "preco"))
            ]
        ]
        `shouldBe` Right ()

    it "rejeita pracada quando a expressão não é uma Ruma" $
      checkStmts
        [ SDecl TInt "numeroSolto" (EInt 42)
        , SFor "item" (EVar "numeroSolto") []
        ]
        `shouldBe` Left (NoIterable TInt)

    it "rejeita pracada diretamente sobre lista vazia sem tipo conhecido" $
      checkStmts [SFor "item" (EList []) []]
        `shouldBe` Left EmptyList

    it "remove a variável de iteração do pracada ao sair do laço" $
      checkStmts
        [ SDecl (TArray TInt) "xs" (EList [EInt 1])
        , SFor "item" (EVar "xs") []
        , SAssign "item" (EInt 2)
        ]
        `shouldBe` Left (UndefinedVar "item")

    it "rejeita poparrar fora de laço" $
      checkStmts [SBreak] `shouldBe` Left BreakOutsideLoop

    it "rejeita segue fora de laço" $
      checkStmts [SContinue] `shouldBe` Left ContinueOutsideLoop

    it "rejeita poparrar após o término de um laço anterior" $
      checkStmts
        [ SWhile (EBool True) [SBreak]
        , SBreak
        ]
        `shouldBe` Left BreakOutsideLoop

    it "rejeita segue após o término de um laço anterior" $
      checkStmts
        [ SWhile (EBool True) [SContinue]
        , SContinue
        ]
        `shouldBe` Left ContinueOutsideLoop

    it "não vaza variável declarada no corpo do enquanto" $
      checkStmts
        [ SWhile (EBool True) [SDecl TInt "volta" (EInt 1)]
        , SAssign "volta" (EInt 2)
        ]
        `shouldBe` Left (UndefinedVar "volta")

  describe "chamadas de comando e retorno" $ do
    it "aceita chamada de função registrada no ambiente como comando" $ do
      let env = emptyEnv { funEnv = M.singleton "avisa" ([TFloat, TFloat], TUnit) }
      runTC (checkBlock [SCall "avisa" [EFloat 10.5, EFloat 20.0]]) env
        `shouldBe` Right ()

    it "rejeita devolve fora de função" $
      checkStmts [SReturn (EInt 1)]
        `shouldBe` Left ReturnOutsideFunction

    it "aceita devolve [] quando a função retorna Ruma de T" $ do
      let env = emptyEnv { retType = Just (TArray TInt) }
      runTC (checkBlock [SReturn (EList [])]) env
        `shouldBe` Right ()

    it "rejeita devolve com tipo diferente do retorno da função" $ do
      let env = emptyEnv { retType = Just TInt }
      runTC (checkBlock [SReturn (EBool True)]) env
        `shouldBe` Left (TypeMismatch TInt TBool)

    it "rejeita chamada de função não declarada como comando" $
      checkStmts [SCall "naoExiste" []]
        `shouldBe` Left (UndefinedFun "naoExiste")

    it "rejeita chamada como comando com número errado de argumentos" $ do
      let env = emptyEnv { funEnv = M.singleton "avisa" ([TFloat, TFloat], TUnit) }
      runTC (checkBlock [SCall "avisa" [EFloat 10.5]]) env
        `shouldBe` Left (ArityMismatch "avisa" 2 1)

  describe "definição de função" $ do
    it "aceita função com parâmetro no corpo e chamada depois da definição" $
      checkStmts
        [ SFun "dobro" [(TInt, "n")] TInt [SReturn (EBinOp Mul (EVar "n") (EInt 2))]
        , SDecl TInt "x" (ECall "dobro" [EInt 21])
        ]
        `shouldBe` Right ()

    it "rejeita corpo de função mal tipado" $
      checkStmts [SFun "f" [] TInt [SDecl TStr "s" (EInt 1)]]
        `shouldBe` Left (TypeMismatch TStr TInt)

    it "rejeita devolve com tipo diferente do retorno declarado" $
      checkStmts [SFun "f" [] TInt [SReturn (EBool True)]]
        `shouldBe` Left (TypeMismatch TInt TBool)

    it "aceita recursão" $
      checkStmts
        [ SFun "conta" [(TInt, "n")] TInt [SReturn (ECall "conta" [EVar "n"])]
        ]
        `shouldBe` Right ()

    it "rejeita chamada antes da definição" $
      checkStmts
        [ SDecl TInt "x" (ECall "dobro" [EInt 1])
        , SFun "dobro" [(TInt, "n")] TInt [SReturn (EVar "n")]
        ]
        `shouldBe` Left (UndefinedFun "dobro")

    it "rejeita função definida duas vezes" $
      checkStmts
        [ SFun "f" [] TInt [SReturn (EInt 1)]
        , SFun "f" [] TInt [SReturn (EInt 2)]
        ]
        `shouldBe` Left (DuplicateFun "f")

    it "não deixa o corpo enxergar variável declarada fora da função" $
      checkStmts
        [ SDecl TInt "global" (EInt 1)
        , SFun "f" [] TInt [SReturn (EVar "global")]
        ]
        `shouldBe` Left (UndefinedVar "global")

    it "não vaza o parâmetro para fora da função" $
      checkStmts
        [ SFun "f" [(TInt, "n")] TInt [SReturn (EVar "n")]
        , SAssign "n" (EInt 1)
        ]
        `shouldBe` Left (UndefinedVar "n")

    it "rejeita poparrar no corpo da função fora de laço" $
      checkStmts [SFun "f" [] TUnit [SBreak]]
        `shouldBe` Left BreakOutsideLoop

    it "poparrar no corpo da função não sai por um laço de fora" $
      checkStmts [SWhile (EBool True) [SFun "f" [] TUnit [SBreak]]]
        `shouldBe` Left BreakOutsideLoop
