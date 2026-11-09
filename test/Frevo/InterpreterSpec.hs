{-# LANGUAGE OverloadedStrings #-}
module Frevo.InterpreterSpec (spec) where

import Data.IORef
import Data.Text (Text)
import qualified Data.Text.IO.Utf8 as T
import Frevo.AST
import Frevo.Interpreter
import Frevo.Parser (parseProgram)
import Frevo.TypeChecker (typecheckProgram)
import Test.Hspec
import Text.Megaparsec (errorBundlePretty)

-- Igual ao Main: só executa o que passou no parser e na checagem de tipos.
runFrevo :: [String] -> Text -> IO (Either RuntimeError (), String)
runFrevo input src = case parseProgram "t" src of
  Left err -> fail (errorBundlePretty err)
  Right prog -> case typecheckProgram prog of
    Left err -> fail (show err)
    Right () -> execute input prog

-- Teclado vira lista de linhas e tela vira texto acumulado.
execute :: [String] -> [Stmt] -> IO (Either RuntimeError (), String)
execute input prog = do
  inputRef <- newIORef input
  outputRef <- newIORef ""
  let console = Console { writeOut = appendTo outputRef, readIn = nextLine inputRef }
  result <- runProgram console prog
  output <- readIORef outputRef
  return (result, output)

appendTo :: IORef String -> String -> IO ()
appendTo ref text = modifyIORef ref (++ text)

nextLine :: IORef [String] -> IO (Maybe String)
nextLine ref = do
  remaining <- readIORef ref
  case remaining of
    [] -> return Nothing
    line : rest -> do
      writeIORef ref rest
      return (Just line)

prints :: Text -> String -> Expectation
prints src expected = runFrevo [] src `shouldReturn` (Right (), expected)

runExample :: FilePath -> [String] -> String -> Expectation
runExample path input expected = do
  src <- T.readFile path
  runFrevo input src `shouldReturn` (Right (), expected)

spec :: Spec
spec = do
  describe "espia" $ do
    it "escreve Numero, Prosa e Certeza" $
      "espia(42) espia(\"oxe\") espia(Certo) espia(Errado)" `prints` "42\noxe\nCerto\nErrado\n"

    it "escreve Quebrado sem notação científica" $
      "espia(4.5) espia(0.01) espia(1.0e7)" `prints` "4.5\n0.01\n10000000.0\n"

    it "escreve Ruma com prosa entre aspas, inclusive aninhada e vazia" $
      "espia([1, 2]) espia([[\"a\"], []]) Ruma de Numero v = [] espia(v)"
        `prints` "[1, 2]\n[[\"a\"], []]\n[]\n"

  describe "aritmética" $ do
    it "respeita a precedência" $
      "espia(1 + 2 * 3) espia((1 + 2) * 3) espia(-2 * 3)" `prints` "7\n9\n-6\n"

    it "divisão de Numero arredonda para baixo e a de Quebrado não" $
      "espia(7 / 2) espia(-7 / 2) espia(7.0 / 2.0)" `prints` "3\n-4\n3.5\n"

    it "Numero não tem limite de tamanho" $
      "espia(9223372036854775807 + 1)" `prints` "9223372036854775808\n"

  describe "comparação e lógica" $ do
    it "compara números, prosa e ruma" $
      "espia(2 < 3) espia(2.5 >= 3.0) espia(\"a\" == \"a\") espia([1, 2] == [1, 2]) espia([1] == [])"
        `prints` "Certo\nErrado\nCerto\nCerto\nErrado\n"

    it "nam inverte e e/ou combinam" $
      "espia(nam Certo) espia(Certo e Errado) espia(Errado ou Certo)" `prints` "Errado\nErrado\nCerto\n"

    it "e e ou não avaliam o lado direito quando o esquerdo já decide" $
      "espia(Errado e 1 / 0 == 1) espia(Certo ou 1 / 0 == 1)" `prints` "Errado\nCerto\n"

  describe "variáveis e escopo" $ do
    it "atribuição dentro do bloco muda a variável de fora" $
      "Numero x = 1\nse Certo então x = 2 cabousse\nespia(x)" `prints` "2\n"

    it "declaração dentro do bloco some no cabousse e a de fora volta" $
      "Numero x = 1\nse Certo então\n Prosa x = \"dentro\"\n espia(x)\n x = \"mudou\"\ncabousse\nespia(x)"
        `prints` "dentro\n1\n"

    it "declaração dentro de sinão, enquanto e pracada some no cabousse" $
      "Numero x = 1\nse Errado então sinão Prosa x = \"a\" cabousse\nenquanto x < 2 faça Prosa x = \"b\" poparrar cabousse\npracada i em [1] faça Prosa x = \"c\" cabousse\npracada x em [\"d\"] faça espia(x) cabousse\nespia(x + 1)"
        `prints` "d\n2\n"

    it "redeclarar no mesmo escopo troca o valor e o tipo" $
      "Numero x = 1\nProsa x = \"a\"\nespia(x)" `prints` "a\n"

    it "variável do corpo do laço nasce de novo a cada volta" $
      "Numero i = 0\nenquanto i < 2 faça\n Numero c = 0\n c = c + 1\n espia(c)\n i = i + 1\ncabousse"
        `prints` "1\n1\n"

  describe "enquanto" $ do
    it "repete enquanto a condição for Certo" $
      "Numero i = 0\nenquanto i < 3 faça espia(i) i = i + 1 cabousse" `prints` "0\n1\n2\n"

    it "poparrar sai do laço e segue pula para a próxima volta" $
      "Numero i = 0\nenquanto Certo faça\n i = i + 1\n se i == 2 então segue cabousse\n se i > 3 então poparrar cabousse\n espia(i)\ncabousse"
        `prints` "1\n3\n"

    it "poparrar sai só do laço mais interno" $
      "Numero i = 0\nenquanto i < 2 faça\n i = i + 1\n enquanto Certo faça poparrar cabousse\n espia(i)\ncabousse"
        `prints` "1\n2\n"

  describe "pracada" $ do
    it "percorre a ruma em ordem" $
      "pracada x em [3, 1, 2] faça espia(x) cabousse" `prints` "3\n1\n2\n"

    it "avalia a ruma uma vez só, antes da primeira volta" $
      "Ruma de Numero xs = [1, 2]\npracada x em xs faça\n xs = [9, 9, 9]\n espia(x)\ncabousse\nespia(quantoTem(xs))"
        `prints` "1\n2\n3\n"

    it "não roda o corpo em ruma vazia" $
      "Ruma de Prosa v = []\npracada x em v faça espia(x) cabousse\nespia(\"fim\")" `prints` "fim\n"

    it "aceita poparrar e segue" $
      "pracada x em [1, 2, 3, 4] faça\n se x == 2 então segue cabousse\n se x == 4 então poparrar cabousse\n espia(x)\ncabousse"
        `prints` "1\n3\n"

  describe "funções" $ do
    it "devolve o valor e aceita recursão" $
      "função fat(Numero n) -> Numero\n se n < 2 então devolve 1 cabousse\n devolve n * fat(n - 1)\ncabousse\nespia(fat(20))"
        `prints` "2432902008176640000\n"

    it "devolve dentro de laço sai da função inteira" $
      "função acha(Ruma de Numero xs, Numero alvo) -> Certeza\n pracada x em xs faça\n  se x == alvo então devolve Certo cabousse\n cabousse\n devolve Errado\ncabousse\nespia(acha([1, 2, 3], 2))\nespia(acha([1, 2, 3], 5))"
        `prints` "Certo\nErrado\n"

    it "parâmetro com o nome de uma variável de fora não a altera" $
      "Numero x = 1\nfunção f(Numero x) -> Numero\n x = x * 10\n devolve x\ncabousse\nespia(f(5))\nespia(x)"
        `prints` "50\n1\n"

    it "função Nadica roda como comando e volta sem devolve" $
      "função avisa(Prosa s) -> Nadica\n espia(s)\ncabousse\navisa(\"oi\")\nespia(\"depois\")"
        `prints` "oi\ndepois\n"

    it "avalia os argumentos da esquerda para a direita" $
      runFrevo ["1", "2"] "espia(encanga(pergunta(\"a\"), pergunta(\"b\")))" `shouldReturn` (Right (), "ab12\n")

  describe "stdlib" $ do
    it "pergunta mostra o texto e lê uma linha" $
      runFrevo ["Maria"] "Prosa n = pergunta(\"Nome? \")\nespia(encanga(\"Oi, \", n))"
        `shouldReturn` (Right (), "Nome? Oi, Maria\n")

    it "quantoTem conta itens da ruma e letras da prosa, com acento" $
      "espia(quantoTem([1, 2, 3])) espia(quantoTem(\"ação\")) espia(quantoTem(\"\"))" `prints` "3\n4\n0\n"

  describe "erros de execução" $ do
    it "divisão por zero de Numero e de Quebrado aponta o comando" $ do
      runFrevo [] "espia(1)\nespia(1 / 0)\nespia(2)" `shouldReturn` (Left (RuntimeAt (2, 1) DivByZero), "1\n")
      runFrevo [] "Quebrado z = 0.0\nespia(1.5 / z)" `shouldReturn` (Left (RuntimeAt (2, 1) DivByZero), "")

    it "divisão por zero dentro da função aponta o comando do corpo" $
      runFrevo [] "função f(Numero a) -> Numero\n  devolve 10 / a\ncabousse\nespia(f(0))"
        `shouldReturn` (Left (RuntimeAt (2, 3) DivByZero), "")

    it "pergunta sem entrada é erro de execução" $
      runFrevo [] "Prosa n = pergunta(\"? \")" `shouldReturn` (Left (RuntimeAt (1, 1) NoInput), "? ")

    it "programa mal tipado que pule a checagem trava em vez de seguir" $ do
      execute [] [SAssign "x" (EInt 1)] `shouldReturn` (Left (Stuck "atribuição a x"), "")
      execute [] [SCall "espia" [EBinOp Add (EInt 1) (EStr "a")]]
        `shouldReturn` (Left (Stuck "operação entre valores de tipos errados"), "")

    it "mensagens começam pela linha e coluna" $
      runtimeErrorMessage (RuntimeAt (2, 1) DivByZero) `shouldBe` "linha 2, coluna 1: divisão por zero"

  describe "programas de examples/" $ do
    it "01 dá bom dia" $
      runExample "examples/01_bom_dia.frevo" [] "Bom dia, Recife!\n"

    it "02 conta os passos e as voltas" $
      runExample "examples/02_passos.frevo" []
        "Hora de tomar um caldinho e descansar\n1\n2\n4\n5\n"

    it "03 soma a feira" $
      runExample "examples/03_feira.frevo" ["Painho"]
        "Quem vai pra feira? Bora, Painho\n3\nVixe, painho vai reclamar\n"
