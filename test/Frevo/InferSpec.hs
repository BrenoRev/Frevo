{-# LANGUAGE OverloadedStrings #-}
module Frevo.InferSpec (spec) where

import qualified Data.Map as M
import Data.Text (Text)
import Frevo.AST
import Frevo.Infer (check, infer)
import Frevo.Lexer (sc)
import Frevo.Parser (pExpr)
import Frevo.TypeEnv
import Test.Hspec
import Text.Megaparsec (eof, parse)

testEnv :: Env
testEnv = emptyEnv
  { varEnv = M.fromList
      [ ("passos", TInt)
      , ("energia", TInt)
      , ("total", TFloat)
      , ("preco", TFloat)
      , ("limite", TFloat)
      , ("nome", TStr)
      , ("cansado", TBool)
      , ("notas", TArray TInt)
      ]
  , funEnv = M.fromList
      [ ("soma", ([TInt, TInt], TInt))
      , ("somaLista", ([TArray TInt], TInt))
      , ("encanga", ([TStr, TStr], TStr))
      , ("avisa", ([], TUnit))
      ]
  }

inferExpr :: Expr -> Either TypeError Type
inferExpr expr = runTC (infer expr) testEnv

checkExpr :: Expr -> Type -> Either TypeError ()
checkExpr expr expected = runTC (check expr expected) testEnv

checkSrc :: Text -> Maybe (Either TypeError Type)
checkSrc src = case parse (sc *> pExpr <* eof) "t" src of
  Left _ -> Nothing
  Right expr -> Just (inferExpr expr)

spec :: Spec
spec = do
  describe "literais" $ do
    it "infere Numero, Quebrado, Prosa e Certeza" $ do
      inferExpr (EInt 42) `shouldBe` Right TInt
      inferExpr (EFloat 1.75) `shouldBe` Right TFloat
      inferExpr (EStr "oxe") `shouldBe` Right TStr
      inferExpr (EBool True) `shouldBe` Right TBool
      inferExpr (EBool False) `shouldBe` Right TBool

  describe "variáveis" $ do
    it "consulta o tipo da variável no ambiente" $ do
      inferExpr (EVar "passos") `shouldBe` Right TInt
      inferExpr (EVar "total") `shouldBe` Right TFloat
      inferExpr (EVar "nome") `shouldBe` Right TStr
      inferExpr (EVar "cansado") `shouldBe` Right TBool
      inferExpr (EVar "notas") `shouldBe` Right (TArray TInt)

    it "rejeita variável não declarada" $
      inferExpr (EVar "inexistente") `shouldBe` Left (UndefinedVar "inexistente")

  describe "operadores unários" $ do
    it "aceita menos unário em Numero e Quebrado" $ do
      inferExpr (ENeg (EInt 10)) `shouldBe` Right TInt
      inferExpr (ENeg (EFloat 2.5)) `shouldBe` Right TFloat
      inferExpr (ENeg (EVar "passos")) `shouldBe` Right TInt
      inferExpr (ENeg (EVar "total")) `shouldBe` Right TFloat

    it "rejeita menos unário em Prosa, Certeza e Ruma" $ do
      inferExpr (ENeg (EStr "oi")) `shouldBe` Left (InvalidUnaryOp Sub TStr)
      inferExpr (ENeg (EBool True)) `shouldBe` Left (InvalidUnaryOp Sub TBool)
      inferExpr (ENeg (EVar "notas")) `shouldBe` Left (InvalidUnaryOp Sub (TArray TInt))

    it "aceita negação lógica nam apenas em Certeza" $ do
      inferExpr (ENot (EBool False)) `shouldBe` Right TBool
      inferExpr (ENot (EVar "cansado")) `shouldBe` Right TBool

    it "rejeita negação lógica nam em tipos não booleanos" $ do
      inferExpr (ENot (EInt 1)) `shouldBe` Left (TypeMismatch TBool TInt)
      inferExpr (ENot (EFloat 1.0)) `shouldBe` Left (TypeMismatch TBool TFloat)
      inferExpr (ENot (EStr "Certo")) `shouldBe` Left (TypeMismatch TBool TStr)

  describe "operadores aritméticos" $ do
    it "aceita +, -, * e / entre dois Numero" $ do
      inferExpr (EBinOp Add (EInt 1) (EInt 2)) `shouldBe` Right TInt
      inferExpr (EBinOp Sub (EInt 5) (EInt 3)) `shouldBe` Right TInt
      inferExpr (EBinOp Mul (EInt 4) (EInt 2)) `shouldBe` Right TInt
      inferExpr (EBinOp Div (EInt 8) (EInt 2)) `shouldBe` Right TInt

    it "aceita +, -, * e / entre dois Quebrado" $ do
      inferExpr (EBinOp Add (EFloat 1.5) (EFloat 2.5)) `shouldBe` Right TFloat
      inferExpr (EBinOp Sub (EFloat 5.0) (EFloat 3.0)) `shouldBe` Right TFloat
      inferExpr (EBinOp Mul (EFloat 4.0) (EFloat 2.0)) `shouldBe` Right TFloat
      inferExpr (EBinOp Div (EFloat 8.0) (EFloat 2.0)) `shouldBe` Right TFloat

    it "rejeita aritmética misturando Numero e Quebrado" $ do
      inferExpr (EBinOp Add (EInt 1) (EFloat 2.0)) `shouldBe` Left (InvalidOp Add TInt TFloat)
      inferExpr (EBinOp Sub (EFloat 2.0) (EInt 1)) `shouldBe` Left (InvalidOp Sub TFloat TInt)
      inferExpr (EBinOp Mul (EInt 2) (EFloat 3.0)) `shouldBe` Left (InvalidOp Mul TInt TFloat)
      inferExpr (EBinOp Div (EFloat 6.0) (EInt 2)) `shouldBe` Left (InvalidOp Div TFloat TInt)

    it "rejeita aritmética em Prosa, Certeza e Ruma" $ do
      inferExpr (EBinOp Add (EStr "a") (EStr "b")) `shouldBe` Left (InvalidOp Add TStr TStr)
      inferExpr (EBinOp Sub (EBool True) (EBool False)) `shouldBe` Left (InvalidOp Sub TBool TBool)
      inferExpr (EBinOp Add (EVar "notas") (EVar "notas")) `shouldBe` Left (InvalidOp Add (TArray TInt) (TArray TInt))

  describe "operadores relacionais e de igualdade" $ do
    it "aceita <, <=, > e >= entre dois Numero" $ do
      inferExpr (EBinOp Lt (EInt 1) (EInt 2)) `shouldBe` Right TBool
      inferExpr (EBinOp Le (EInt 1) (EInt 2)) `shouldBe` Right TBool
      inferExpr (EBinOp Gt (EInt 2) (EInt 1)) `shouldBe` Right TBool
      inferExpr (EBinOp Ge (EInt 2) (EInt 1)) `shouldBe` Right TBool

    it "aceita <, <=, > e >= entre dois Quebrado" $ do
      inferExpr (EBinOp Lt (EFloat 1.0) (EFloat 2.0)) `shouldBe` Right TBool
      inferExpr (EBinOp Le (EFloat 1.0) (EFloat 2.0)) `shouldBe` Right TBool
      inferExpr (EBinOp Gt (EFloat 2.0) (EFloat 1.0)) `shouldBe` Right TBool
      inferExpr (EBinOp Ge (EFloat 2.0) (EFloat 1.0)) `shouldBe` Right TBool

    it "rejeita <, <=, > e >= entre tipos diferentes ou não numéricos" $ do
      inferExpr (EBinOp Lt (EInt 1) (EFloat 2.0)) `shouldBe` Left (InvalidOp Lt TInt TFloat)
      inferExpr (EBinOp Gt (EStr "a") (EStr "b")) `shouldBe` Left (InvalidOp Gt TStr TStr)
      inferExpr (EBinOp Le (EBool True) (EBool False)) `shouldBe` Left (InvalidOp Le TBool TBool)

    it "aceita == entre valores do mesmo tipo" $ do
      inferExpr (EBinOp Eq (EInt 1) (EInt 1)) `shouldBe` Right TBool
      inferExpr (EBinOp Eq (EFloat 1.0) (EFloat 1.0)) `shouldBe` Right TBool
      inferExpr (EBinOp Eq (EStr "a") (EStr "a")) `shouldBe` Right TBool
      inferExpr (EBinOp Eq (EBool True) (EBool False)) `shouldBe` Right TBool
      inferExpr (EBinOp Eq (EVar "notas") (EList [EInt 1])) `shouldBe` Right TBool

    it "aceita == entre Ruma e lista vazia" $ do
      inferExpr (EBinOp Eq (EVar "notas") (EList [])) `shouldBe` Right TBool
      inferExpr (EBinOp Eq (EList []) (EVar "notas")) `shouldBe` Right TBool

    it "rejeita == entre tipos diferentes ou entre Nadica" $ do
      inferExpr (EBinOp Eq (EInt 1) (EFloat 1.0)) `shouldBe` Left (InvalidOp Eq TInt TFloat)
      inferExpr (EBinOp Eq (EStr "1") (EInt 1)) `shouldBe` Left (InvalidOp Eq TStr TInt)
      inferExpr (EBinOp Eq (ECall "avisa" []) (ECall "avisa" [])) `shouldBe` Left (InvalidOp Eq TUnit TUnit)
      inferExpr (EBinOp Eq (EList [ECall "avisa" []]) (EList [ECall "avisa" []])) `shouldBe` Left VoidListElement

  describe "operadores lógicos" $ do
    it "aceita e e ou entre dois Certeza" $ do
      inferExpr (EBinOp And (EBool True) (EBool False)) `shouldBe` Right TBool
      inferExpr (EBinOp Or (EBool False) (EVar "cansado")) `shouldBe` Right TBool

    it "rejeita e e ou com operandos não booleanos" $ do
      inferExpr (EBinOp And (EInt 1) (EBool True)) `shouldBe` Left (InvalidOp And TInt TBool)
      inferExpr (EBinOp Or (EBool False) (EStr "oi")) `shouldBe` Left (InvalidOp Or TBool TStr)

  describe "listas e chamadas em expressões" $ do
    it "infere lista homogênea e lista aninhada" $ do
      inferExpr (EList [EInt 1, EInt 2, EInt 3]) `shouldBe` Right (TArray TInt)
      inferExpr (EList [EList [EStr "a"], EList [EStr "b"]]) `shouldBe` Right (TArray (TArray TStr))

    it "aceita lista vazia contra Ruma de T esperada e rejeita sem tipo esperado" $ do
      checkExpr (EList []) (TArray TInt) `shouldBe` Right ()
      inferExpr (EList []) `shouldBe` Left EmptyList

    it "infere lista aninhada contendo lista vazia" $ do
      inferExpr (EList [EList [], EList [EInt 1]]) `shouldBe` Right (TArray (TArray TInt))
      inferExpr (EList [EList [EInt 1], EList []]) `shouldBe` Right (TArray (TArray TInt))

    it "rejeita lista com elementos de tipos diferentes" $
      inferExpr (EList [EInt 1, EFloat 2.0]) `shouldBe` Left (ArrayHeterogeneousType TInt TFloat)

    it "rejeita lista com elemento Nadica" $
      inferExpr (EList [ECall "avisa" []]) `shouldBe` Left VoidListElement

    it "rejeita elemento Nadica mesmo depois de uma lista vazia" $
      inferExpr (EList [EList [], ECall "avisa" []]) `shouldBe` Left VoidListElement

    it "rejeita lista vazia onde o tipo esperado não é Ruma" $ do
      checkExpr (EList []) TInt `shouldBe` Left (EmptyListMismatch TInt)
      inferExpr (EBinOp Eq (EInt 1) (EList [])) `shouldBe` Left (EmptyListMismatch TInt)

    it "rejeita lista vazia misturada com elementos que não são Ruma" $
      inferExpr (EList [EInt 1, EList []]) `shouldBe` Left (EmptyListMismatch TInt)

    it "rejeita lista vazia aninhada mais fundo que o tipo esperado" $ do
      inferExpr (EBinOp Eq (EVar "notas") (EList [EList []])) `shouldBe` Left (EmptyListMismatch TInt)
      inferExpr (ECall "somaLista" [EList [EList []]]) `shouldBe` Left (EmptyListMismatch TInt)

    it "infere o tipo de retorno na chamada de função" $ do
      inferExpr (ECall "soma" [EInt 1, EInt 2]) `shouldBe` Right TInt
      inferExpr (ECall "encanga" [EStr "oi, ", EVar "nome"]) `shouldBe` Right TStr

    it "aceita lista vazia como argumento de parâmetro Ruma de T" $
      inferExpr (ECall "somaLista" [EList []]) `shouldBe` Right TInt

    it "rejeita chamada de função não declarada" $
      inferExpr (ECall "naoExiste" []) `shouldBe` Left (UndefinedFun "naoExiste")

    it "rejeita chamada com número errado de argumentos" $
      inferExpr (ECall "soma" [EInt 1]) `shouldBe` Left (ArityMismatch "soma" 2 1)

    it "rejeita chamada com argumento de tipo incompatível" $
      inferExpr (ECall "soma" [EInt 1, EFloat 2.0]) `shouldBe` Left (ArgMismatch "soma" 2 TInt TFloat)

    it "prioriza erro de aridade quando aridade e tipo do argumento falham juntos" $
      inferExpr (ECall "soma" [EFloat 1.5]) `shouldBe` Left (ArityMismatch "soma" 2 1)

  describe "expressões compostas da linguagem" $ do
    it "infere expressões reais dos exemplos após o parser" $ do
      checkSrc "energia > 50 e nam cansado" `shouldBe` Just (Right TBool)
      checkSrc "total + preco > limite" `shouldBe` Just (Right TBool)
      checkSrc "soma(passos, 1) * 2" `shouldBe` Just (Right TInt)
      checkSrc "passos + total" `shouldBe` Just (Left (InvalidOp Add TInt TFloat))
