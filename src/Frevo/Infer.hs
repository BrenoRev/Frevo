module Frevo.Infer (infer, check) where

import Control.Monad (when, zipWithM_)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import qualified Data.Map as M
import Frevo.AST
import Frevo.TypeEnv

-- Lista vazia não sintetiza o tipo dos elementos sozinha; é verificada
-- quando o contexto já informa o Ruma de T esperado.
check :: Expr -> Type -> TC ()
check (EList elems) (TArray elemType)
  | isValueType elemType && all isEmptyList elems =
      mapM_ (`check` elemType) elems
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
infer (ECall name args) = do
  funs <- asks funEnv
  case M.lookup name funs of
    Nothing -> throwError (UndefinedFun name)
    Just (params, ret) -> do
      when (length params /= length args) $
        throwError (ArityMismatch name (length params) (length args))
      zipWithM_ check args params
      return ret
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

isValueType :: Type -> Bool
isValueType TUnit = False
isValueType (TArray t) = isValueType t
isValueType _ = True

isEmptyList :: Expr -> Bool
isEmptyList (EList elems) = all isEmptyList elems
isEmptyList _ = False

inferList :: [Expr] -> TC Type
inferList elems =
  case filter (not . isEmptyList) elems of
    [] -> throwError EmptyList
    firstConcrete : _ -> do
      t <- infer firstConcrete
      when (t == TUnit) $ throwError VoidListElement
      mapM_ (checkElem t) elems
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
