module Frevo.Infer (infer, check) where

import Control.Monad (when)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import qualified Data.Map as M
import Frevo.AST
import Frevo.TypeEnv

-- Lista vazia não sintetiza o tipo dos elementos sozinha; é verificada
-- quando o contexto já informa o Ruma de T esperado.
check :: Expr -> Type -> TC ()
check (EList elems) (TArray elemType)
  | all isEmptyList elems = mapM_ (`check` elemType) elems
check expr expected
  | isEmptyList expr = throwError (EmptyListMismatch expected)
check expr expected = do
  found <- infer expr
  expect expected found

infer :: Expr -> TC Type
infer (EInt _) = return TInt
infer (EFloat _) = return TFloat
infer (EStr _) = return TStr
infer (EBool _) = return TBool
infer (EVar name) = do
  vars <- asks varEnv
  case M.lookup name vars of
    Just t -> return t
    Nothing -> throwError (UndefinedVar name)
infer (EList elems) = inferList elems
infer (ECall name args) = inferCall name args
infer (ENeg expr) = do
  t <- infer expr
  case t of
    TInt -> return TInt
    TFloat -> return TFloat
    _ -> throwError (InvalidUnaryOp Sub t)
infer (ENot expr) = do
  t <- infer expr
  expect TBool t
  return TBool
infer (EBinOp Eq left right)
  | isEmptyList right && not (isEmptyList left) = do
      t1 <- infer left
      check right t1
      return TBool
  | isEmptyList left && not (isEmptyList right) = do
      t2 <- infer right
      check left t2
      return TBool
infer (EBinOp op left right) = do
  t1 <- infer left
  t2 <- infer right
  inferBinOp op t1 t2

inferCall :: String -> [Expr] -> TC Type
inferCall "espia" [arg] = do
  t <- infer arg
  when (t == TUnit) $ throwError (InvalidArg "espia" t)
  return TUnit
inferCall "quantoTem" [arg] = do
  t <- infer arg
  case t of
    TArray _ -> return TInt
    TStr -> return TInt
    _ -> throwError (InvalidArg "quantoTem" t)
inferCall name args
  | name `elem` polymorphicBuiltins = throwError (ArityMismatch name 1 (length args))
inferCall name args = do
  funs <- asks funEnv
  case M.lookup name funs of
    Nothing -> throwError (UndefinedFun name)
    Just (params, ret) -> do
      when (length params /= length args) $
        throwError (ArityMismatch name (length params) (length args))
      sequence_ (zipWith3 (checkArg name) [1 ..] args params)
      return ret

-- Compara o tipo do próprio argumento, sem capturar erro: um erro dentro de
-- uma chamada interna, como em f(g("x")), continua sendo de g.
checkArg :: String -> Int -> Expr -> Type -> TC ()
checkArg fun index arg param
  | isEmptyList arg = check arg param
  | otherwise = do
      found <- infer arg
      when (found /= param) $ throwError (ArgMismatch fun index param found)

isEmptyList :: Expr -> Bool
isEmptyList (EList elems) = all isEmptyList elems
isEmptyList _ = False

-- O primeiro elemento concreto é inferido uma vez só e fica fora do mapM_:
-- inferi-lo de novo dobraria o custo a cada nível de aninhamento.
inferList :: [Expr] -> TC Type
inferList elems =
  case span isEmptyList elems of
    (_, []) -> throwError EmptyList
    (before, firstConcrete : after) -> do
      t <- infer firstConcrete
      when (t == TUnit) $ throwError VoidListElement
      mapM_ (checkElem t) (before ++ after)
      return (TArray t)

checkElem :: Type -> Expr -> TC ()
checkElem expected expr
  | isEmptyList expr = check expr expected
  | otherwise = do
      found <- infer expr
      when (found == TUnit) $ throwError VoidListElement
      when (expected /= found) $
        throwError (ArrayHeterogeneousType expected found)

-- Nadica só existe como retorno de função sem valor, nunca como operando de ==.
inferBinOp :: Op -> Type -> Type -> TC Type
inferBinOp op TInt TInt
  | op `elem` [Add, Sub, Mul, Div] = return TInt
  | op `elem` [Lt, Gt, Le, Ge] = return TBool
inferBinOp op TFloat TFloat
  | op `elem` [Add, Sub, Mul, Div] = return TFloat
  | op `elem` [Lt, Gt, Le, Ge] = return TBool
inferBinOp Eq t1 t2
  | t1 == t2 && t1 /= TUnit = return TBool
inferBinOp And TBool TBool = return TBool
inferBinOp Or TBool TBool = return TBool
inferBinOp op t1 t2 = throwError (InvalidOp op t1 t2)
