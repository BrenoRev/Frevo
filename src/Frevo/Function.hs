-- Recebe tipos já inferidos, não expressões: assim Infer e Statement importam
-- este módulo sem que ele precise importar os dois de volta.
module Frevo.Function
  ( checkCallExpr
  , checkCallStmt
  , checkReturn
  , checkList
  , stdlibSignatures
  , polymorphicBuiltins
  ) where

import Control.Monad (when, zipWithM_)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import qualified Data.Map as M
import Frevo.AST
import Frevo.TypeEnv

-- Assinatura fixa: entram no ambiente como qualquer função do usuário.
stdlibSignatures :: M.Map String ([Type], Type)
stdlibSignatures = M.fromList
  [ ("pergunta", ([TStr], TStr))
  , ("encanga", ([TStr, TStr], TStr))
  ]

-- Aceitam mais de um tipo e a linguagem não tem polimorfismo, então cada uma
-- é um caso embutido em checkCallStmt.
polymorphicBuiltins :: [String]
polymorphicBuiltins = ["espia", "quantoTem"]

checkCallStmt :: String -> [Type] -> TC Type
checkCallStmt "espia" [_] = return TUnit
checkCallStmt "quantoTem" [TArray _] = return TInt
checkCallStmt "quantoTem" [TStr] = return TInt
checkCallStmt "quantoTem" [t] = throwError (InvalidArg "quantoTem" t)
checkCallStmt name args
  | name `elem` polymorphicBuiltins = throwError (ArityMismatch name 1 (length args))
  | otherwise = checkSignature name args

-- Dentro de expressão, a chamada tem de produzir valor: Nadica não entra em
-- conta, lista, argumento nem devolve.
checkCallExpr :: String -> [Type] -> TC Type
checkCallExpr name args = do
  ret <- checkCallStmt name args
  when (ret == TUnit) $ throwError (NoValue name)
  return ret

checkSignature :: String -> [Type] -> TC Type
checkSignature name args = do
  funs <- asks funEnv
  case M.lookup name funs of
    Nothing -> throwError (UndefinedFun name)
    Just (params, ret) -> do
      when (length params /= length args) $
        throwError (ArityMismatch name (length params) (length args))
      zipWithM_ expect params args
      return ret

checkReturn :: Type -> TC ()
checkReturn found = do
  expected <- asks retType
  case expected of
    Nothing -> throwError ReturnOutsideFunction
    Just t -> expect t found

-- [] sozinho não diz o tipo dos elementos; quem diz é a declaração
-- (Ruma de Numero xs = []), tratada em Statement.
checkList :: [Type] -> TC Type
checkList [] = throwError EmptyList
checkList (t : ts) = do
  mapM_ (expect t) ts
  return (TArray t)
