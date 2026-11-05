module Frevo.TypeEnv where

import Control.Monad.Reader
import Control.Monad.Except
import qualified Data.Map as M

import Frevo.AST

data Env = Env 
  { varEnv  :: M.Map String Type
  , funEnv  :: M.Map String ([Type], Type) 
  , retType :: Maybe Type
  , inLoop :: Bool                
  } deriving (Show, Eq)

emptyEnv :: Env
emptyEnv = Env M.empty M.empty Nothing False

data TypeError = 
    TypeMisMatch Type Type
    | InvalidOp Op Type Type
    | UndefinedVar String
    | UndefinedFun String
    | DuplicateFun String
    | ArityMismatch String Int Int
    | ArrayHeterogeneousType Type Type
    | NoIterable Type 
    | BreakOutsideLoop
    | ContinueOutsideLoop
    | ReturnOutsideFunction
    deriving (Show, Eq)

type TC a = ReaderT Env (Except TypeError) a
runTC :: TC a -> Env -> Either TypeError a
runTC checker env = runExcept (runReaderT checker env)

expect :: Type -> Type -> TC()
expect expected found =
  if expected == found 
  then return ()
  else throwError $ TypeMisMatch expected found

-- local desfaz a inserção ao sair do bloco: é isso que dá o escopo léxico.
withVar :: String -> Type -> TC a -> TC a
withVar name ttype = local (\e -> e { varEnv = M.insert name ttype (varEnv e) })

withRetType :: Type -> TC a -> TC a
withRetType returnType = local (\e -> e { retType = Just returnType })

inLoopScope :: TC a -> TC a
inLoopScope = local (\e -> e { inLoop = True })