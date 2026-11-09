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
    TypeMismatch Type Type
    | InvalidOp Op Type Type
    | InvalidUnaryOp Op Type
    | UndefinedVar String
    | UndefinedFun String
    | DuplicateFun String
    | ArityMismatch String Int Int
    | ArrayHeterogeneousType Type Type
    | EmptyList
    | EmptyListMismatch Type
    | VoidListElement
    | NoIterable Type
    | BreakOutsideLoop
    | ContinueOutsideLoop
    | ReturnOutsideFunction
    deriving (Show, Eq)

type TC a = ReaderT Env (Except TypeError) a
runTC :: TC a -> Env -> Either TypeError a
runTC checker env = runExcept (runReaderT checker env)

expect :: Type -> Type -> TC ()
expect expected found =
  if expected == found
  then return ()
  else throwError $ TypeMismatch expected found

-- local desfaz a inserção ao sair do bloco: é isso que dá o escopo léxico.
withVar :: String -> Type -> TC a -> TC a
withVar name ttype = local (\e -> e { varEnv = M.insert name ttype (varEnv e) })

withRetType :: Type -> TC a -> TC a
withRetType returnType = local (\e -> e { retType = Just returnType })

inLoopScope :: TC a -> TC a
inLoopScope = local (\e -> e { inLoop = True })

withFun :: String -> [Type] -> Type -> TC a -> TC a
withFun name params ret = local (\e -> e { funEnv = M.insert name (params, ret) (funEnv e) })

-- O corpo só enxerga os parâmetros: uma global pode ser redeclarada com outro
-- tipo depois da definição, e o corpo teria sido checado com o tipo antigo.
withFunScope :: [(Type, String)] -> Type -> TC a -> TC a
withFunScope params ret = local enterBody
  where
    paramVars = M.fromList [(name, ty) | (ty, name) <- params]
    enterBody e = e { varEnv = paramVars, retType = Just ret }
