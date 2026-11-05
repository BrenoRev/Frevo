module Frevo.TypeSpec (spec) where

import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import qualified Data.Map as M
import Frevo.AST
import Frevo.TypeEnv
import Test.Hspec

spec :: Spec
spec = do
  describe "ambiente de tipos" $ do
    it "inicia vazio, sem retorno e fora de laço" $
      emptyEnv `shouldBe` Env M.empty M.empty Nothing False

    it "executa uma computação no ambiente informado" $
      runTC (asks varEnv) emptyEnv `shouldBe` Right M.empty

    it "propaga erros da computação" $
      runTC (throwError (UndefinedVar "x") :: TC ()) emptyEnv
        `shouldBe` Left (UndefinedVar "x")

  describe "expect" $ do
    it "aceita tipos iguais" $
      runTC (expect TInt TInt) emptyEnv `shouldBe` Right ()

    it "retorna erro com tipo esperado e encontrado" $
      runTC (expect TBool TInt) emptyEnv
        `shouldBe` Left (TypeMisMatch TBool TInt)

  describe "escopo de variáveis" $ do
    it "expõe a variável dentro do escopo e a remove ao sair" $ do
      let action = do
            scoped <- withVar "x" TInt (asks varEnv)
            outside <- asks varEnv
            pure (scoped, outside)
      runTC action emptyEnv `shouldBe` Right (M.singleton "x" TInt, M.empty)

    it "sombreia uma variável no escopo interno e restaura a externa" $ do
      let env = emptyEnv { varEnv = M.singleton "x" TStr }
          action = do
            inner <- withVar "x" TInt (asks varEnv)
            outer <- asks varEnv
            pure (inner, outer)
      runTC action env
        `shouldBe` Right (M.singleton "x" TInt, M.singleton "x" TStr)

    it "preserva as demais partes do ambiente" $ do
      let env =
            Env
              { varEnv = M.empty
              , funEnv = M.singleton "f" ([TInt], TBool)
              , retType = Just TStr
              , inLoop = True
              }
          expected = env { varEnv = M.singleton "x" TInt }
      runTC (withVar "x" TInt (asks id)) env `shouldBe` Right expected

  describe "contexto de retorno" $ do
    it "define o tipo de retorno apenas dentro do escopo" $ do
      let action = do
            inside <- withRetType TInt (asks retType)
            outside <- asks retType
            pure (inside, outside)
      runTC action emptyEnv `shouldBe` Right (Just TInt, Nothing)

    it "restaura o tipo de retorno externo após o escopo interno" $ do
      let env = emptyEnv { retType = Just TStr }
          action = do
            inside <- withRetType TInt (asks retType)
            outside <- asks retType
            pure (inside, outside)
      runTC action env `shouldBe` Right (Just TInt, Just TStr)

  describe "contexto de laço" $ do
    it "marca o escopo interno como laço e restaura o estado externo" $ do
      let action = do
            inside <- inLoopScope (asks inLoop)
            outside <- asks inLoop
            pure (inside, outside)
      runTC action emptyEnv `shouldBe` Right (True, False)

    it "mantém o contexto externo quando já está dentro de um laço" $ do
      let env = emptyEnv { inLoop = True }
          action = do
            inside <- inLoopScope (asks inLoop)
            outside <- asks inLoop
            pure (inside, outside)
      runTC action env `shouldBe` Right (True, True)
