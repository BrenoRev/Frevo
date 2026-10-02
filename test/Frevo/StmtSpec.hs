{-# LANGUAGE OverloadedStrings #-}
module Frevo.StmtSpec (spec) where

import Data.Either (isLeft, isRight)
import Data.Text (Text)
import qualified Data.Text.IO.Utf8 as T
import Data.Void (Void)
import Frevo.AST
import Frevo.Parser
import Test.Hspec
import Text.Megaparsec (ParseErrorBundle)

prog :: Text -> Either (ParseErrorBundle Text Void) [Stmt]
prog = parseProgram "t"

x :: Expr
x = EVar "x"

spec :: Spec
spec = do
  it "lê declaração de cada tipo" $ do
    prog "Numero n = 1" `shouldBe` Right [SDecl TInt "n" (EInt 1)]
    prog "Quebrado q = 1.5" `shouldBe` Right [SDecl TFloat "q" (EFloat 1.5)]
    prog "Prosa p = \"oi\"" `shouldBe` Right [SDecl TStr "p" (EStr "oi")]
    prog "Certeza c = Certo" `shouldBe` Right [SDecl TBool "c" (EBool True)]

  it "lê tipo de lista, inclusive aninhada" $ do
    prog "Ruma de Numero xs = [1]" `shouldBe` Right [SDecl (TArray TInt) "xs" (EList [EInt 1])]
    prog "Ruma de Ruma de Prosa m = []" `shouldBe` Right [SDecl (TArray (TArray TStr)) "m" (EList [])]

  it "lê atribuição e chamada como comandos" $
    prog "x = 1\nespia(x)" `shouldBe` Right [SAssign "x" (EInt 1), SCall "espia" [x]]

  it "separa comandos sem terminador" $
    prog "x = 1 y = 2" `shouldBe` Right [SAssign "x" (EInt 1), SAssign "y" (EInt 2)]

  it "aceita fim de linha do Windows" $
    prog "x = 1\r\n# nota\r\nsegue\r\n" `shouldBe` Right [SAssign "x" (EInt 1), SContinue]

  it "lê se sem sinão" $
    prog "se x então segue cabousse" `shouldBe` Right [SIf x [SContinue] Nothing]

  it "lê se com sinão" $
    prog "se x então segue sinão poparrar cabousse"
      `shouldBe` Right [SIf x [SContinue] (Just [SBreak])]

  it "o sinão pertence ao se mais interno ainda aberto" $
    prog "se x então se x então segue cabousse sinão poparrar cabousse"
      `shouldBe` Right [SIf x [SIf x [SContinue] Nothing] (Just [SBreak])]

  it "lê enquanto" $
    prog "enquanto x < 3 faça x = x + 1 cabousse"
      `shouldBe` Right [SWhile (EBinOp Lt x (EInt 3)) [SAssign "x" (EBinOp Add x (EInt 1))]]

  it "lê pracada" $
    prog "pracada item em xs faça espia(item) cabousse"
      `shouldBe` Right [SFor "item" (EVar "xs") [SCall "espia" [EVar "item"]]]

  it "lê função com parâmetros e retorno" $
    prog "função dobro(Numero x) -> Numero devolve x * 2 cabousse"
      `shouldBe` Right [SFun "dobro" [(TInt, "x")] TInt [SReturn (EBinOp Mul x (EInt 2))]]

  it "lê função sem parâmetros que não devolve nada" $
    prog "função oi() -> Nadica espia(\"oi\") cabousse"
      `shouldBe` Right [SFun "oi" [] TUnit [SCall "espia" [EStr "oi"]]]

  it "rejeita declaração sem valor" $
    prog "Numero x" `shouldSatisfy` isLeft

  it "rejeita Nadica como tipo de variável" $
    prog "Nadica x = 1" `shouldSatisfy` isLeft

  it "rejeita expressão solta que não é chamada" $ do
    prog "1 + 2" `shouldSatisfy` isLeft
    prog "x" `shouldSatisfy` isLeft

  it "rejeita função dentro de bloco" $
    prog "se x então função f() -> Nadica cabousse cabousse" `shouldSatisfy` isLeft

  it "rejeita função sem tipo de retorno" $
    prog "função f() cabousse" `shouldSatisfy` isLeft

  it "rejeita laço sem faça" $
    prog "enquanto x segue cabousse" `shouldSatisfy` isLeft

  it "rejeita se sem então" $
    prog "se x segue cabousse" `shouldSatisfy` isLeft

  it "rejeita pracada sem em" $
    prog "pracada item xs faça segue cabousse" `shouldSatisfy` isLeft

  it "rejeita Ruma sem de" $
    prog "Ruma Numero xs = []" `shouldSatisfy` isLeft

  it "rejeita parâmetro sem nome e vírgula sobrando" $ do
    prog "função f(Numero) -> Numero devolve 1 cabousse" `shouldSatisfy` isLeft
    prog "função f(Numero a,) -> Numero devolve 1 cabousse" `shouldSatisfy` isLeft

  it "rejeita chamada sem fechar parêntese" $
    prog "espia(1" `shouldSatisfy` isLeft

  it "rejeita sinão e cabousse sem bloco aberto" $ do
    prog "sinão x = 1 cabousse" `shouldSatisfy` isLeft
    prog "cabousse" `shouldSatisfy` isLeft

  it "aceita os programas de exemplo" $
    mapM_ (\f -> T.readFile f >>= \src -> parseProgram f src `shouldSatisfy` isRight)
      [ "examples/01_bom_dia.frevo"
      , "examples/02_passos.frevo"
      , "examples/03_feira.frevo"
      ]
