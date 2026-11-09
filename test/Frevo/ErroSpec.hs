{-# LANGUAGE OverloadedStrings #-}
module Frevo.ErroSpec (spec) where

import Data.Text (Text)
import qualified Data.Text as T
import Frevo.AST
import Frevo.Parser
import Test.Hspec
import Text.Megaparsec (errorBundlePretty)

-- A mensagem do Megaparsec começa por "arquivo:linha:coluna:".
erro :: Text -> String
erro src = either errorBundlePretty (const "sem erro") (parseProgram "t" src)

spec :: Spec
spec = do
  it "bloco sem cabousse acusa o fim do arquivo" $
    erro "se x então\n  y = 1\n" `shouldStartWith` "t:3:1:"

  it "operador sem operando aponta onde faltou o valor" $
    erro "x = 1 + )" `shouldStartWith` "t:1:9:"

  it "prosa não fechada aponta o fim da linha" $
    erro "x = \"abc" `shouldStartWith` "t:1:9:"

  it "devolve sem expressão aponta logo depois da palavra" $
    erro "devolve" `shouldStartWith` "t:1:8:"

  it "palavra reservada como nome aponta o começo dela" $ do
    erro "Numero se = 1" `shouldStartWith` "t:1:8:"
    erro "Numero se = 1" `shouldContain` "palavra reservada"

  it "identificador com _ não vira comando segue" $
    erro "se x então segue_ cabousse" `shouldStartWith` "t:1:19:"

  it "erro em linha do meio do arquivo reporta a linha certa" $
    erro "x = 1\ny = 2\nz = = 3\n" `shouldStartWith` "t:3:5:"

  it "comentário não esconde erro na mesma linha" $
    erro "x = # falta o valor\n" `shouldStartWith` "t:2:1:"

  it "Quebrado fora da faixa aponta o começo do número" $ do
    erro "x = 1e400" `shouldStartWith` "t:1:5:"
    erro "x = 1e400" `shouldContain` "fora da faixa"

  it "expoente com mais de três dígitos é rejeitado, em vez de dar a volta" $ do
    erro "x = 1e1000" `shouldStartWith` "t:1:5:"
    erro "x = 1e0001" `shouldContain` "três dígitos"
    erro "x = 1e18446744073709551617" `shouldStartWith` "t:1:5:"
    erro "x = 1.5e-0001" `shouldStartWith` "t:1:5:"

  it "aceita arquivo vazio" $
    parseProgram "t" "" `shouldBe` Right []

  it "aceita arquivo só com comentários e linhas em branco" $
    parseProgram "t" "# nada\n\n  # aqui\n" `shouldBe` Right []

  it "aceita expressão com 100 parênteses aninhados" $
    parseProgram "t" ("x = " <> T.replicate 100 "(" <> "1" <> T.replicate 100 ")")
      `shouldBe` Right [SAt (1, 1) (SAssign "x" (EInt 1))]

  it "aceita 100 blocos aninhados" $
    fmap length (parseProgram "t" (T.replicate 100 "se Certo então " <> T.replicate 100 "cabousse "))
      `shouldBe` Right 1
