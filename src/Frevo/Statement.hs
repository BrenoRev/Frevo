module Frevo.Statement
  ( checkBlock
  ) where

import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)

import Frevo.AST
import Frevo.Infer (check, infer)
import Frevo.TypeEnv

checkBlock :: [Stmt] -> TC ()
checkBlock [] = return ()

-- Usa 'check' (e não 'infer') para que listas vazias herdem o tipo esperado.
checkBlock (SDecl tipo nome expr : stmts) = do
  check expr tipo
  withVar nome tipo (checkBlock stmts)

checkBlock (SAssign nome expr : stmts) = do
  tVar <- infer (EVar nome)
  check expr tVar
  checkBlock stmts

checkBlock (SIf cond thenBody maybeElseBody : stmts) = do
  check cond TBool
  checkBlock thenBody
  maybe (return ()) checkBlock maybeElseBody
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

checkBlock (SCall nome args : stmts) = do
  _ <- infer (ECall nome args)
  checkBlock stmts

checkBlock (SReturn expr : stmts) = do
  mRet <- asks retType
  case mRet of
    Nothing -> throwError ReturnOutsideFunction
    Just expectedRet -> do
      check expr expectedRet
      checkBlock stmts

checkBlock (SFun _ _ _ _ : stmts) =
  checkBlock stmts
  