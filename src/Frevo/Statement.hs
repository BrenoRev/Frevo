module Frevo.Statement
  ( checkBlock
  ) where

import Control.Monad (when)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import qualified Data.Map as M

import Frevo.AST
import Frevo.Infer (check, infer)
import Frevo.TypeEnv

checkBlock :: [Stmt] -> TC ()
checkBlock [] = return ()

-- Usa 'check' (e não 'infer') para que listas vazias herdem o tipo esperado.
checkBlock (SDecl ty name expr : stmts) = do
  check expr ty
  withVar name ty (checkBlock stmts)

checkBlock (SAssign name expr : stmts) = do
  tVar <- infer (EVar name)
  check expr tVar
  checkBlock stmts

checkBlock (SIf cond thenBody maybeElseBody : stmts) = do
  check cond TBool
  checkBlock thenBody
  mapM_ checkBlock maybeElseBody
  checkBlock stmts

checkBlock (SWhile cond body : stmts) = do
  check cond TBool
  inLoopScope (checkBlock body)
  checkBlock stmts

checkBlock (SFor var iterable body : stmts) = do
  tIter <- infer iterable
  case tIter of
    TArray tElem -> inLoopScope (withVar var tElem (checkBlock body))
    _            -> throwError (NoIterable tIter)
  checkBlock stmts

checkBlock (SBreak : stmts) = do
  loop <- asks inLoop
  if loop
    then checkBlock stmts
    else throwError BreakOutsideLoop

checkBlock (SContinue : stmts) = do
  loop <- asks inLoop
  if loop
    then checkBlock stmts
    else throwError ContinueOutsideLoop

checkBlock (SCall name args : stmts) = do
  _ <- infer (ECall name args)
  checkBlock stmts

checkBlock (SReturn expr : stmts) = do
  mRet <- asks retType
  case mRet of
    Nothing -> throwError ReturnOutsideFunction
    Just expectedRet -> do
      check expr expectedRet
      checkBlock stmts

-- A função entra em Γ antes do corpo, para permitir recursão, e só vale
-- dali em diante: é a ordem em que o interpretador vai executar o programa.
checkBlock (SFun name params ret body : stmts) = do
  funs <- asks funEnv
  when (M.member name funs) $ throwError (DuplicateFun name)
  withFun name (map fst params) ret $ do
    withFunScope params ret (checkBlock body)
    checkBlock stmts
