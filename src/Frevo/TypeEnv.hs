module Frevo.TypeEnv where

import Control.Monad.Reader
import Control.Monad.Except
import qualified Data.Map as M

import Frevo.AST

-- Definir env da ast
data Env = Env 
  { varEnv  :: M.Map String Type
  , funEnv  :: M.Map String ([Type], Type) 
  , retType :: Maybe Type
  , inLoop :: Bool                
  } deriving (Show, Eq)

emptyEnv :: Env
emptyEnv = Env M.empty M.empty Nothing False

data TypeError = 
    TypeMissMatch Type Type
    | InvalidOperation Op Type Type
    | InvalidUnaryOp Op Type
    | UndefinedVar String
    | UndefinedFun String
    | DuplicateVar String
    | DuplicateFun String
    | ArityMissmatch String Int Int
    | ArrayHeterogeneousType Type Type
    | NoIterable Type 
    | BreakOutsideLoop
    | ContinueOutsideLoop
    | ReturnOutsideFunction
    deriving (Show, Eq)

-- Rodar o env dos erros no monad
type TC a = ReaderT Env (Except TypeError) a
runTC :: TC a -> Env -> Either TypeError a
runTC checker env = runExcept (runReaderT checker env)

-- Verificar se um tipo correpsonde ao outro
expect :: Type -> Type -> TC()
expect expected found =
  if expected == found 
  then return ()
  else throwError $ TypeMissmatch expected found

-- Variavel temporaria
withVar :: String -> Type -> TC a -> TC a
withVar name ttype = local (\e -> e { varEnv = M.insert name ttype (varEnv e) })

-- Definir o contexto de retorno de uma função
withRetType :: Type -> TC a -> TC a
withRetType returnType = local (\e -> e { retType = Just returnType })

-- Definir escopo do loop
inLoopScope :: TC a -> TC a
inLoopScope = local (\e -> e { inLoop = True })