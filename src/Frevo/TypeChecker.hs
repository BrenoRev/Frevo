module Frevo.TypeChecker (typecheckProgram, alwaysReturns) where

import Control.Monad (foldM, when)
import Control.Monad.Except (throwError)
import Control.Monad.Reader (local)
import Data.List (nub, (\\))
import qualified Data.Map as M
import Frevo.AST
import Frevo.Function (polymorphicBuiltins, stdlibSignatures)
import Frevo.Statement (checkBlock)
import Frevo.TypeEnv

data FunDef = FunDef String [(Type, String)] Type [Stmt]

typecheckProgram :: [Stmt] -> Either TypeError ()
typecheckProgram prog = runTC (checkProgram prog) emptyEnv

-- Todas as assinaturas entram antes de qualquer corpo: uma função pode chamar
-- a si mesma ou outra definida mais abaixo no arquivo.
checkProgram :: [Stmt] -> TC ()
checkProgram prog = do
  let (funs, topLevel) = splitProgram prog
  sigs <- foldM addSignature stdlibSignatures funs
  local (\env -> env { funEnv = sigs }) $ do
    mapM_ checkFun funs
    checkBlock topLevel

splitProgram :: [Stmt] -> ([FunDef], [Stmt])
splitProgram = foldr split ([], [])
  where
    split (SFun name params ret body) (funs, stmts) = (FunDef name params ret body : funs, stmts)
    split stmt (funs, stmts) = (funs, stmt : stmts)

addSignature :: M.Map String ([Type], Type) -> FunDef -> TC (M.Map String ([Type], Type))
addSignature sigs (FunDef name params ret _)
  | M.member name sigs || name `elem` polymorphicBuiltins = throwError (DuplicateFun name)
  | otherwise = return (M.insert name (map fst params, ret) sigs)

-- O corpo enxerga só os parâmetros: variável do nível de topo não entra na função.
checkFun :: FunDef -> TC ()
checkFun (FunDef name params ret body) = do
  checkParams name (map snd params)
  let scope env = env { varEnv = M.fromList [(x, t) | (t, x) <- params], retType = Just ret }
  local scope (checkBlock body)
  when (ret /= TUnit && not (alwaysReturns body)) $ throwError (MissingReturn name)

checkParams :: String -> [String] -> TC ()
checkParams fun names = case names \\ nub names of
  [] -> return ()
  repeated : _ -> throwError (DuplicateParam fun repeated)

-- Conservadora: um laço pode rodar zero vezes, então devolve dentro de
-- enquanto ou pracada não garante retorno; se sem sinão também não.
alwaysReturns :: [Stmt] -> Bool
alwaysReturns = any returns
  where
    returns (SReturn _) = True
    returns (SIf _ thenBody (Just elseBody)) = alwaysReturns thenBody && alwaysReturns elseBody
    returns _ = False
