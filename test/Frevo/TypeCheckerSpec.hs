{-# LANGUAGE OverloadedStrings #-}
module Frevo.TypeCheckerSpec (spec) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO.Utf8 as T
import Frevo.AST
import Frevo.Parser (parseProgram)
import Frevo.TypeChecker
import Frevo.TypeEnv
import Test.Hspec

-- Nothing quando o parser rejeita: a checagem nem começa.
typecheck :: Text -> Maybe (Either TypeError ())
typecheck src = either (const Nothing) (Just . typecheckProgram) (parseProgram "t" src)

ok :: Maybe (Either TypeError ())
ok = Just (Right ())

rejectsAt :: Pos -> TypeError -> Maybe (Either TypeError ())
rejectsAt pos err = Just (Left (TypeAt pos err))

checkExample :: FilePath -> Expectation
checkExample path = do
  src <- T.readFile path
  typecheck src `shouldBe` ok

spec :: Spec
spec = do
  describe "stdlib" $ do
    it "espia aceita valor de qualquer tipo" $
      typecheck "espia(1) espia(1.5) espia(\"oi\") espia(Certo) espia([[1]])" `shouldBe` ok

    it "espia rejeita o resultado de função Nadica" $
      typecheck "função f() -> Nadica cabousse\nespia(f())" `shouldBe` rejectsAt (2, 1) (InvalidArg "espia" TUnit)

    it "espia e quantoTem exigem exatamente um argumento" $ do
      typecheck "espia(1, 2)" `shouldBe` rejectsAt (1, 1) (ArityMismatch "espia" 1 2)
      typecheck "Numero n = quantoTem()" `shouldBe` rejectsAt (1, 1) (ArityMismatch "quantoTem" 1 0)

    it "quantoTem aceita Ruma e Prosa e devolve Numero" $
      typecheck "Numero a = quantoTem([1.5])\nNumero b = quantoTem(\"oxe\")" `shouldBe` ok

    it "quantoTem rejeita o que não é Ruma nem Prosa" $
      typecheck "Numero n = quantoTem(42)" `shouldBe` rejectsAt (1, 1) (InvalidArg "quantoTem" TInt)

    it "quantoTem de [] sem tipo é rejeitado" $
      typecheck "espia(quantoTem([]))" `shouldBe` rejectsAt (1, 1) EmptyList

    it "pergunta e encanga seguem a assinatura fixa" $ do
      typecheck "Prosa n = encanga(\"a\", pergunta(\"b\"))" `shouldBe` ok
      typecheck "Prosa n = pergunta(1)" `shouldBe` rejectsAt (1, 1) (ArgMismatch "pergunta" 1 TStr TInt)
      typecheck "Prosa n = encanga(\"a\")" `shouldBe` rejectsAt (1, 1) (ArityMismatch "encanga" 2 1)

    it "rejeita função com nome da stdlib" $ do
      typecheck "função encanga() -> Nadica cabousse" `shouldBe` rejectsAt (1, 1) (DuplicateFun "encanga")
      typecheck "função espia(Numero x) -> Nadica cabousse" `shouldBe` rejectsAt (1, 1) (DuplicateFun "espia")

  describe "definição de função" $ do
    it "diz qual argumento está com o tipo errado" $
      typecheck "função f(Numero a, Prosa b) -> Nadica cabousse\nf(1, 2)"
        `shouldBe` rejectsAt (2, 1) (ArgMismatch "f" 2 TStr TInt)

    it "não confunde o argumento errado de uma chamada interna com o da externa" $
      typecheck "função g(Numero a) -> Numero devolve a cabousse\nfunção f(Numero a) -> Nadica cabousse\nf(g(\"x\"))"
        `shouldBe` rejectsAt (3, 1) (ArgMismatch "g" 1 TInt TStr)

    it "rejeita devolve em função Nadica, mesmo de valor Nadica" $ do
      typecheck "função f() -> Nadica devolve 1 cabousse" `shouldBe` rejectsAt (1, 22) VoidReturn
      typecheck "função f() -> Nadica devolve espia(1) cabousse" `shouldBe` rejectsAt (1, 22) VoidReturn

    it "rejeita parâmetro repetido" $
      typecheck "função f(Numero x, Prosa x) -> Nadica cabousse" `shouldBe` rejectsAt (1, 1) (DuplicateParam "f" "x")

    it "função Nadica não precisa de devolve" $
      typecheck "função f() -> Nadica cabousse" `shouldBe` ok

    it "rejeita função sem devolve" $
      typecheck "função f() -> Numero cabousse" `shouldBe` rejectsAt (1, 1) (MissingReturn "f")

    it "rejeita se sem sinão como único devolve" $
      typecheck "função f(Certeza c) -> Numero\n se c então devolve 1 cabousse\ncabousse"
        `shouldBe` rejectsAt (1, 1) (MissingReturn "f")

    it "rejeita se em que só um dos ramos devolve" $ do
      typecheck "função f(Certeza c) -> Numero\n se c então devolve 1 sinão espia(1) cabousse\ncabousse"
        `shouldBe` rejectsAt (1, 1) (MissingReturn "f")
      typecheck "função f(Certeza c) -> Numero\n se c então espia(1) sinão devolve 2 cabousse\ncabousse"
        `shouldBe` rejectsAt (1, 1) (MissingReturn "f")

    it "aceita devolve nos dois ramos do se" $
      typecheck "função f(Certeza c) -> Numero\n se c então devolve 1 sinão devolve 2 cabousse\ncabousse"
        `shouldBe` ok

    it "rejeita devolve só dentro de laço" $ do
      typecheck "função f() -> Numero enquanto Certo faça devolve 1 cabousse cabousse"
        `shouldBe` rejectsAt (1, 1) (MissingReturn "f")
      typecheck "função f(Ruma de Numero xs) -> Numero pracada x em xs faça devolve x cabousse cabousse"
        `shouldBe` rejectsAt (1, 1) (MissingReturn "f")

    it "aceita devolve no meio do corpo seguido de mais comandos" $
      typecheck "função f() -> Numero\n devolve 1\n espia(2)\ncabousse" `shouldBe` ok

  describe "posição do erro" $ do
    it "aponta o comando no começo, no meio e no fim do arquivo" $ do
      typecheck "Numero x = \"a\"\nespia(1)\nespia(2)" `shouldBe` rejectsAt (1, 1) (TypeMismatch TInt TStr)
      typecheck "espia(1)\n  Numero x = \"a\"\nespia(2)" `shouldBe` rejectsAt (2, 3) (TypeMismatch TInt TStr)
      typecheck "espia(1)\nespia(2)\nespia(y)" `shouldBe` rejectsAt (3, 1) (UndefinedVar "y")

    it "aponta o comando mais interno, não o bloco que o contém" $
      typecheck "se Certo então\n  enquanto Certo faça\n    x = 1\n  cabousse\ncabousse"
        `shouldBe` rejectsAt (3, 5) (UndefinedVar "x")

    it "erro na condição aponta o se" $
      typecheck "espia(1)\nse 1 então cabousse" `shouldBe` rejectsAt (2, 1) (TypeMismatch TBool TInt)

    it "erro no corpo da função aponta o comando do corpo" $
      typecheck "função f() -> Numero\n  devolve \"a\"\ncabousse" `shouldBe` rejectsAt (2, 3) (TypeMismatch TInt TStr)

  describe "mensagens" $ do
    it "começam pela linha e coluna" $
      typeErrorMessage (TypeAt (3, 5) (UndefinedVar "x"))
        `shouldBe` "linha 3, coluna 5: a variável x não foi declarada"

    it "usam o nome do tipo na Frevo" $
      typeErrorMessage (TypeMismatch (TArray TStr) TFloat)
        `shouldBe` "era pra ser Ruma de Prosa, mas veio Quebrado"

    it "concordam o número de argumentos" $ do
      typeErrorMessage (ArityMismatch "f" 1 3) `shouldBe` "f recebe 1 argumento, mas foi chamada com 3"
      typeErrorMessage (ArityMismatch "f" 2 0) `shouldBe` "f recebe 2 argumentos, mas foi chamada com 0"

    it "dizem a posição do argumento errado" $
      typeErrorMessage (ArgMismatch "f" 2 TStr TInt) `shouldBe` "o 2º argumento de f era pra ser Prosa, mas veio Numero"

  it "checa ruma com 60 níveis de aninhamento sem custo exponencial" $
    typecheck ("espia(quantoTem(" <> T.replicate 60 "[" <> "1" <> T.replicate 60 "]" <> "))") `shouldBe` ok

  it "rejeita o programa inteiro, mesmo com comandos válidos antes do erro" $
    typecheck "espia(\"antes\")\nNumero x = \"oi\"" `shouldBe` rejectsAt (2, 1) (TypeMismatch TInt TStr)

  it "os programas de examples/ passam na checagem" $
    mapM_ checkExample
      [ "examples/01_bom_dia.frevo"
      , "examples/02_passos.frevo"
      , "examples/03_feira.frevo"
      ]
