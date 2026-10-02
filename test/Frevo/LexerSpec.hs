{-# LANGUAGE OverloadedStrings #-}
module Frevo.LexerSpec (spec) where

import Data.Either (isLeft)
import Data.Text (Text, pack, unpack)
import Data.Void (Void)
import Frevo.AST
import Frevo.Lexer
import Frevo.Parser
import Test.Hspec
import Text.Megaparsec

ident :: Text -> Either (ParseErrorBundle Text Void) String
ident = parse (sc *> pIdentifier <* eof) "t"

expr :: Text -> Either (ParseErrorBundle Text Void) Expr
expr = parse (sc *> pExpr <* eof) "t"

spec :: Spec
spec = do
  it "aceita nome com letra, dígito, acento e sublinhado" $ do
    ident "soma_2" `shouldBe` Right "soma_2"
    ident "_média" `shouldBe` Right "_média"

  it "aceita nome que começa por palavra reservada" $
    mapM_ (\w -> ident w `shouldBe` Right (unpack w))
      ["sementes", "segue_", "eu", "outro", "empresa", "Numeros", "enquantoIsso"]

  it "rejeita toda palavra reservada como nome" $
    mapM_ (\w -> ident (pack w) `shouldSatisfy` isLeft) reservedKeywords

  it "rejeita nome que começa por dígito" $
    ident "2pac" `shouldSatisfy` isLeft

  it "descarta espaço, quebra de linha e comentário" $
    parseProgram "t" "# começo\n\n   # outro\nsegue # fim\n" `shouldBe` Right [SContinue]

  it "lê os literais de cada tipo básico" $ do
    expr "42" `shouldBe` Right (EInt 42)
    expr "1.75" `shouldBe` Right (EFloat 1.75)
    expr "\"oxe\"" `shouldBe` Right (EStr "oxe")
    expr "Certo" `shouldBe` Right (EBool True)
    expr "Errado" `shouldBe` Right (EBool False)

  it "lê escape dentro de prosa" $
    expr "\"a\\n\\\"b\\\"\"" `shouldBe` Right (EStr "a\n\"b\"")

  it "lê quebrado com expoente" $ do
    expr "1e3" `shouldBe` Right (EFloat 1000)
    expr "2.5e-1" `shouldBe` Right (EFloat 0.25)

  it "rejeita quebrado sem dígito depois do ponto" $
    expr "1." `shouldSatisfy` isLeft

  it "rejeita número colado em letra" $ do
    expr "2pac" `shouldSatisfy` isLeft
    expr "1.5x" `shouldSatisfy` isLeft

  it "rejeita prosa não fechada" $
    expr "\"abc" `shouldSatisfy` isLeft
