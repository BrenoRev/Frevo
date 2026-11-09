module Frevo.Statement
  ( checkBlock
  ) where

import Control.Monad (when)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (asks)
import Data.List (nub, (\\))
import qualified Data.Map as M

import Frevo.AST
import Frevo.Infer (check, infer)
import Frevo.TypeEnv

checkBlock :: [Stmt] -> TC ()
checkBlock [] = return ()

-- O resto do bloco fica dentro do atPos porque a declaração vale para ele;
-- como cada comando do resto tem a própria posição, o erro dele não é afetado.
checkBlock (SAt pos stmt : stmts) = atPos pos (checkBlock (stmt : stmts))

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
    -- devolve sempre leva expressão, então numa função Nadica ele só serviria
    -- para o truque devolve espia(x); a função termina no cabousse.
    Just TUnit -> throwError VoidReturn
    Just expectedRet -> do
      check expr expectedRet
      checkBlock stmts

-- A função entra em Γ antes do corpo, para permitir recursão, e só vale
-- dali em diante: é a ordem em que o interpretador vai executar o programa.
checkBlock (SFun name params ret body : stmts) = do
  funs <- asks funEnv
  when (M.member name funs || name `elem` polymorphicBuiltins) $
    throwError (DuplicateFun name)
  checkParams name (map snd params)
  withFun name (map fst params) ret $ do
    withFunScope params ret (checkBlock body)
    when (ret /= TUnit && not (alwaysReturns body)) $
      throwError (MissingReturn name)
    checkBlock stmts

checkParams :: String -> [String] -> TC ()
checkParams fun names = case names \\ nub names of
  [] -> return ()
  repeated : _ -> throwError (DuplicateParam fun repeated)

-- Conservadora: um laço pode rodar zero vezes, então devolve dentro de
-- enquanto ou pracada não garante retorno; se sem sinão também não.
alwaysReturns :: [Stmt] -> Bool
alwaysReturns = any returns
  where
    returns (SAt _ stmt) = returns stmt
    returns (SReturn _) = True
    returns (SIf _ thenBody (Just elseBody)) = alwaysReturns thenBody && alwaysReturns elseBody
    returns _ = False
