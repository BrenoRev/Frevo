{-# LANGUAGE OverloadedStrings #-}
module Frevo.TypeSpec (spec) where

import Data.Text (Text)
import qualified Data.Text as T
import Frevo.AST
import Frevo.Parser
import Frevo.TypeEnv
import Frevo.TypeChecker (typecheckProgram)
import Test.Hspec
import Text.Megaparsec (errorBundlePretty)

-- Ajudante: recebe o código em texto, roda o parser e aplica o typechecker
checar :: Text -> Either TypeError ()
checar src = case parseProgram "t" src of
  Left err  -> error $ "Erro de sintaxe no teste de tipo: " ++ errorBundlePretty err
  Right ast -> typecheckProgram ast

spec :: Spec
spec = do
  describe "Atribuição e Declaração de Variáveis" $ do
    it "aceita declarações com tipos corretos" $ do
      checar "Numero x = 10" `shouldBe` Right ()
      checar "Quebrado y = 3.14" `shouldBe` Right ()
      checar "Prosa s = \"frevo\"" `shouldBe` Right ()
      checar "Certeza b = Certo" `shouldBe` Right ()

    it "rejeita atribuição de tipo incompatível" $ do
      checar "Numero x = \"texto\"" `shouldBe` Left (TypeMissMatch TInt TStr)
      checar "Certeza b = 10" `shouldBe` Left (TypeMissMatch TBool TInt)

    it "rejeita uso de variável não declarada" $ do
      checar "x = y" `shouldBe` Left (UndefinedVar "y")

  describe "Expressões e Operadores Binários" $ do
    it "aceita operações entre tipos compatíveis" $ do
      checar "Numero x = 1 + 2 * 3" `shouldBe` Right ()
      checar "Certeza b = (10 > 5) e nam Errado" `shouldBe` Right ()

    it "rejeita soma entre tipos incompatíveis" $ do
      checar "Numero x = 1 + Certo" `shouldBe` Left (InvalidOperation Add TInt TBool)

  describe "Controle de Fluxo e Laços" $ do
    it "valida condição booleana no se e enquanto" $ do
      checar "se Certo então x = 1 cabousse" `shouldBe` Right ()
      checar "enquanto Errado faça x = 1 cabousse" `shouldBe` Right ()

    it "rejeita condição não booleana no condicional" $ do
      checar "se 10 então x = 1 cabousse" `shouldBe` Left (TypeMissMatch TBool TInt)
      checar "enquanto \"texto\" faça x = 1 cabousse" `shouldBe` Left (TypeMissMatch TBool TStr)

    it "aceita iteração pracada em arrays" $ do
      checar "pracada x em [1, 2, 3] faça Numero y = x cabousse" `shouldBe` Right ()

    it "rejeita pracada em tipos não iteráveis" $ do
      checar "pracada x em 10 faça Numero y = x cabousse" `shouldBe` Left (NoIterable TInt)

    it "permite poparrar e segue apenas dentro de laços" $ do
      checar "enquanto Certo faça poparrar segue cabousse" `shouldBe` Right ()
      checar "poparrar" `shouldBe` Left BreakOutsideLoop
      checar "segue" `shouldBe` Left ContinueOutsideLoop

  describe "Funções e Devolução" $ do
    it "aceita funções bem tipadas e chamadas válidas" $ do
      let prog = "função soma(Numero a, Numero b) -> Numero\n\
                 \  devolve a + b\n\
                 \cabousse\n\
                 \Numero resultado = soma(10, 20)"
      checar prog `shouldBe` Right ()

    it "rejeita retorno de tipo diferente do declarado" $ do
      let prog = "função teste() -> Numero\n\
                 \  devolve Certo\n\
                 \cabousse"
      checar prog `shouldBe` Left (TypeMissMatch TInt TBool)

    it "rejeita devolve fora do corpo de uma função" $ do
      checar "devolve 10" `shouldBe` Left ReturnOutsideFunction

    it "rejeita chamada de função com quantidade errada de argumentos" $ do
      let prog = "função foo(Numero a) -> Nadica\n\
                 \cabousse\n\
                 \foo(1, 2)"
      checar prog `shouldBe` Left (ArityMissmatch "foo" 1 2)

    it "rejeita chamada de função inexistente" $ do
      checar "x = funcaoFantasma()" `shouldBe` Left (UndefinedFun "funcaoFantasma")