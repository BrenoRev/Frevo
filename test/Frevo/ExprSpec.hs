{-# LANGUAGE OverloadedStrings #-}
module Frevo.ExprSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text)
import Data.Void (Void)
import Frevo.AST
import Frevo.Lexer (sc)
import Frevo.Parser
import Test.Hspec
import Text.Megaparsec

expr :: Text -> Either (ParseErrorBundle Text Void) Expr
expr = parse (sc *> pExpr <* eof) "t"

a, b, c :: Expr
a = EVar "a"
b = EVar "b"
c = EVar "c"

spec :: Spec
spec = do
  it "multiplicação tem precedência sobre soma" $
    expr "1 + 2 * 3" `shouldBe` Right (EBinOp Add (EInt 1) (EBinOp Mul (EInt 2) (EInt 3)))

  it "parênteses mudam a precedência" $
    expr "(1 + 2) * 3" `shouldBe` Right (EBinOp Mul (EBinOp Add (EInt 1) (EInt 2)) (EInt 3))

  it "subtração e divisão associam à esquerda" $ do
    expr "a - b - c" `shouldBe` Right (EBinOp Sub (EBinOp Sub a b) c)
    expr "a / b / c" `shouldBe` Right (EBinOp Div (EBinOp Div a b) c)

  it "comparação fica abaixo da aritmética" $
    expr "a + 1 <= b" `shouldBe` Right (EBinOp Le (EBinOp Add a (EInt 1)) b)

  it "distingue <= de < e >= de >" $ do
    expr "a <= b" `shouldBe` Right (EBinOp Le a b)
    expr "a < b" `shouldBe` Right (EBinOp Lt a b)
    expr "a >= b" `shouldBe` Right (EBinOp Ge a b)
    expr "a > b" `shouldBe` Right (EBinOp Gt a b)

  it "e tem precedência sobre ou" $
    expr "a ou b e c" `shouldBe` Right (EBinOp Or a (EBinOp And b c))

  it "nam nega a comparação inteira" $
    expr "nam a == b" `shouldBe` Right (ENot (EBinOp Eq a b))

  it "menos unário liga mais forte que qualquer binário" $ do
    expr "-a * 2" `shouldBe` Right (EBinOp Mul (ENeg a) (EInt 2))
    expr "1 - -2" `shouldBe` Right (EBinOp Sub (EInt 1) (ENeg (EInt 2)))

  it "lê chamada de função com e sem argumentos" $ do
    expr "soma(1, a)" `shouldBe` Right (ECall "soma" [EInt 1, a])
    expr "agora()" `shouldBe` Right (ECall "agora" [])

  it "lê lista vazia, simples e aninhada" $ do
    expr "[]" `shouldBe` Right (EList [])
    expr "[1, a]" `shouldBe` Right (EList [EInt 1, a])
    expr "[[1], []]" `shouldBe` Right (EList [EList [EInt 1], EList []])

  it "rejeita comparação encadeada" $
    expr "a < b < c" `shouldSatisfy` isLeft

  it "rejeita prefixo repetido" $ do
    expr "nam nam a" `shouldSatisfy` isLeft
    expr "- -a" `shouldSatisfy` isLeft

  it "rejeita operador sem operando" $ do
    expr "1 +" `shouldSatisfy` isLeft
    expr "* 2" `shouldSatisfy` isLeft

  it "rejeita parêntese, colchete e argumento incompletos" $ do
    expr "(1 + 2" `shouldSatisfy` isLeft
    expr "[1, ]" `shouldSatisfy` isLeft
    expr "f(1,)" `shouldSatisfy` isLeft
