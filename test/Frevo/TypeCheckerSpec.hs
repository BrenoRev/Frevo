{-# LANGUAGE OverloadedStrings #-}
module Frevo.TypeCheckerSpec (spec) where

import Data.Text (Text)
import qualified Data.Text.IO.Utf8 as T
import qualified Data.Map as M
import Frevo.AST
import Frevo.Function
import Frevo.Parser (parseProgram)
import Frevo.TypeChecker
import Frevo.TypeEnv
import Test.Hspec

-- Ambiente com a stdlib, uma função Nadica e uma que devolve Numero.
env :: Env
env = emptyEnv
  { funEnv = M.union stdlibSignatures (M.fromList [("avisa", ([], TUnit)), ("dobra", ([TInt], TInt))])
  , retType = Just TInt
  }

run :: TC a -> Either TypeError a
run checker = runTC checker env

-- Nothing quando o parser rejeita: o teste de tipo nem começa.
typecheck :: Text -> Maybe (Either TypeError ())
typecheck src = either (const Nothing) (Just . typecheckProgram) (parseProgram "t" src)

ok :: Maybe (Either TypeError ())
ok = Just (Right ())

rejects :: TypeError -> Maybe (Either TypeError ())
rejects = Just . Left

checkExample :: FilePath -> Expectation
checkExample path = do
  src <- T.readFile path
  typecheck src `shouldBe` ok

spec :: Spec
spec = do
  describe "chamada" $ do
    it "espia aceita valor de qualquer tipo" $
      mapM (run . checkCallStmt "espia" . pure) [TInt, TFloat, TStr, TBool, TArray TInt]
        `shouldBe` Right (replicate 5 TUnit)

    it "espia e quantoTem exigem exatamente um argumento" $ do
      run (checkCallStmt "espia" [TInt, TInt]) `shouldBe` Left (ArityMismatch "espia" 1 2)
      run (checkCallStmt "quantoTem" []) `shouldBe` Left (ArityMismatch "quantoTem" 1 0)

    it "quantoTem aceita Ruma e Prosa e rejeita o resto" $ do
      run (checkCallStmt "quantoTem" [TArray TFloat]) `shouldBe` Right TInt
      run (checkCallStmt "quantoTem" [TStr]) `shouldBe` Right TInt
      run (checkCallStmt "quantoTem" [TInt]) `shouldBe` Left (InvalidArg "quantoTem" TInt)

    it "pergunta e encanga seguem a assinatura fixa" $ do
      run (checkCallStmt "pergunta" [TStr]) `shouldBe` Right TStr
      run (checkCallStmt "pergunta" [TInt]) `shouldBe` Left (TypeMismatch TStr TInt)
      run (checkCallStmt "encanga" [TStr]) `shouldBe` Left (ArityMismatch "encanga" 2 1)

    it "compara cada argumento com o parâmetro na mesma posição" $ do
      run (checkCallStmt "dobra" [TInt]) `shouldBe` Right TInt
      run (checkCallStmt "dobra" [TFloat]) `shouldBe` Left (TypeMismatch TInt TFloat)

    it "acusa função não definida" $
      run (checkCallStmt "pula" []) `shouldBe` Left (UndefinedFun "pula")

    it "chamada Nadica vale como comando, mas não como expressão" $ do
      run (checkCallStmt "avisa" []) `shouldBe` Right TUnit
      run (checkCallExpr "avisa" []) `shouldBe` Left (NoValue "avisa")
      run (checkCallExpr "espia" [TInt]) `shouldBe` Left (NoValue "espia")

  describe "devolve" $ do
    it "confere o tipo com o retorno da função" $ do
      run (checkReturn TInt) `shouldBe` Right ()
      run (checkReturn TStr) `shouldBe` Left (TypeMismatch TInt TStr)

    it "fora de função é erro" $
      runTC (checkReturn TInt) emptyEnv `shouldBe` Left ReturnOutsideFunction

  describe "lista" $ do
    it "tem o tipo dos elementos, inclusive aninhada" $ do
      run (checkList [TInt, TInt]) `shouldBe` Right (TArray TInt)
      run (checkList [TArray TStr]) `shouldBe` Right (TArray (TArray TStr))

    it "rejeita elementos de tipos diferentes" $
      run (checkList [TInt, TFloat]) `shouldBe` Left (TypeMismatch TInt TFloat)

    it "vazia sem declaração não tem tipo" $
      run (checkList []) `shouldBe` Left EmptyList

  describe "definição de função" $ do
    it "aceita chamada antes da definição e recursão" $
      typecheck "espia(fat(5))\nfunção fat(Numero n) -> Numero\n se n < 2 então devolve 1 cabousse\n devolve n * fat(n - 1)\ncabousse"
        `shouldBe` ok

    it "rejeita função definida duas vezes" $
      typecheck "função f() -> Nadica cabousse\nfunção f() -> Nadica cabousse" `shouldBe` rejects (DuplicateFun "f")

    it "rejeita função com nome da stdlib" $ do
      typecheck "função encanga() -> Nadica cabousse" `shouldBe` rejects (DuplicateFun "encanga")
      typecheck "função espia(Numero x) -> Nadica cabousse" `shouldBe` rejects (DuplicateFun "espia")

    it "rejeita parâmetro repetido" $
      typecheck "função f(Numero x, Prosa x) -> Nadica cabousse" `shouldBe` rejects (DuplicateParam "f" "x")

    it "corpo enxerga os parâmetros, mas não as variáveis do topo" $ do
      typecheck "função f(Numero x) -> Numero devolve x cabousse" `shouldBe` ok
      typecheck "Numero g = 1\nfunção f() -> Numero devolve g cabousse" `shouldBe` rejects (UndefinedVar "g")

    it "parâmetro da função não vaza para o topo" $
      typecheck "função f(Numero x) -> Nadica cabousse\nespia(x)" `shouldBe` rejects (UndefinedVar "x")

    it "rejeita devolve com tipo diferente do declarado" $
      typecheck "função f() -> Numero devolve \"oi\" cabousse" `shouldBe` rejects (TypeMismatch TInt TStr)

    it "rejeita devolve em função Nadica" $
      typecheck "função f() -> Nadica devolve 1 cabousse" `shouldBe` rejects (TypeMismatch TUnit TInt)

    it "rejeita devolve no nível de topo" $
      typecheck "devolve 1" `shouldBe` rejects ReturnOutsideFunction

    it "rejeita argumento de tipo errado na chamada" $
      typecheck "função f(Numero x) -> Nadica cabousse\nf(1.5)" `shouldBe` rejects (TypeMismatch TInt TFloat)

    it "rejeita valor de função Nadica dentro de expressão" $
      typecheck "função f() -> Nadica cabousse\nespia(f())" `shouldBe` rejects (NoValue "f")

  describe "todo caminho devolve" $ do
    it "função Nadica não precisa de devolve" $
      typecheck "função f() -> Nadica cabousse" `shouldBe` ok

    it "rejeita função sem devolve" $
      typecheck "função f() -> Numero cabousse" `shouldBe` rejects (MissingReturn "f")

    it "rejeita se sem sinão como único devolve" $
      typecheck "função f(Certeza c) -> Numero se c então devolve 1 cabousse cabousse"
        `shouldBe` rejects (MissingReturn "f")

    it "aceita devolve nos dois ramos do se" $
      typecheck "função f(Certeza c) -> Numero se c então devolve 1 sinão devolve 2 cabousse cabousse"
        `shouldBe` ok

    it "rejeita devolve só dentro de laço" $ do
      typecheck "função f() -> Numero enquanto Certo faça devolve 1 cabousse cabousse"
        `shouldBe` rejects (MissingReturn "f")
      typecheck "função f(Ruma de Numero xs) -> Numero pracada x em xs faça devolve x cabousse cabousse"
        `shouldBe` rejects (MissingReturn "f")

    it "alwaysReturns olha os ramos aninhados" $ do
      alwaysReturns [SIf (EBool True) [SIf (EBool True) [SReturn (EInt 1)] (Just [SReturn (EInt 2)])] (Just [SReturn (EInt 3)])]
        `shouldBe` True
      alwaysReturns [SIf (EBool True) [SIf (EBool True) [SReturn (EInt 1)] Nothing] (Just [SReturn (EInt 3)])]
        `shouldBe` False

  it "os programas de examples/ passam na checagem" $
    mapM_ checkExample
      [ "examples/01_bom_dia.frevo"
      , "examples/02_passos.frevo"
      , "examples/03_feira.frevo"
      ]
