module Frevo.Interpreter
  ( RuntimeError (..)
  , Console (..)
  , runProgram
  , runtimeErrorMessage
  ) where

import Control.Monad.Except (ExceptT, catchError, runExceptT, throwError)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ReaderT, asks, runReaderT)
import Control.Monad.State.Strict (StateT, evalStateT, gets, modify)
import Data.List (intercalate)
import qualified Data.Map.Strict as M
import Data.Maybe (mapMaybe)
import Numeric (showFFloat)
import Frevo.AST

-- Campos estritos: sem isso, "total = total + 1" num laço longo empilha contas
-- por fazer até estourar a memória.
data Value
  = VInt !Integer
  | VFloat !Double
  | VStr String
  | VBool !Bool
  | VList [Value]
  | VUnit
  deriving (Show, Eq)

-- Stuck é o programa travado da semântica operacional: só acontece se o type
-- checker deixar passar um programa mal tipado.
data RuntimeError
  = DivByZero
  | NoInput
  | Stuck String
  | RuntimeAt Pos RuntimeError
  deriving (Show, Eq)

-- Teclado e tela entram como parâmetro: o Main passa os de verdade e os
-- testes passam listas.
data Console = Console
  { writeOut :: String -> IO ()
  , readIn :: IO (Maybe String)
  }

data Function = Function [String] [Stmt]

-- scopes vai do mais interno ao mais externo.
data Store = Store
  { scopes :: [M.Map String Value]
  , functions :: M.Map String Function
  }

type Eval a = ReaderT Console (StateT Store (ExceptT RuntimeError IO)) a

-- O que sobra de executar um comando: seguir para o próximo ou desviar o fluxo.
data Outcome = Normal | Break | Continue | Return Value

runProgram :: Console -> [Stmt] -> IO (Either RuntimeError ())
runProgram console prog = runExceptT (evalStateT (runReaderT top console) emptyStore)
  where
    emptyStore = Store [M.empty] M.empty
    top = do
      _ <- execStmts prog
      return ()

execStmts :: [Stmt] -> Eval Outcome
execStmts [] = return Normal
execStmts (stmt : rest) = do
  outcome <- exec stmt
  case outcome of
    Normal -> execStmts rest
    _ -> return outcome

-- Erro não precisa fechar o escopo: ele encerra o programa.
inScope :: Eval a -> Eval a
inScope action = do
  modify (\s -> s { scopes = M.empty : scopes s })
  result <- action
  modify (\s -> s { scopes = drop 1 (scopes s) })
  return result

exec :: Stmt -> Eval Outcome
exec (SAt pos stmt) = atPos pos (exec stmt)
exec (SDecl _ name expr) = do
  value <- eval expr
  declare name value
  return Normal
exec (SAssign name expr) = do
  value <- eval expr
  assign name value
  return Normal
exec (SCall name args) = do
  _ <- evalCall name args
  return Normal
exec (SIf cond thenBody elseBody) = do
  c <- evalBool cond
  if c
    then inScope (execStmts thenBody)
    else maybe (return Normal) (inScope . execStmts) elseBody
exec loop@(SWhile cond body) = do
  c <- evalBool cond
  if c then loopStep (return ()) body (exec loop) else return Normal
exec (SFor var iterable body) = do
  items <- eval iterable
  case items of
    VList values -> forEach var body values
    _ -> throwError (Stuck "pracada fora de Ruma")
exec (SReturn expr) = Return <$> eval expr
exec SBreak = return Break
exec SContinue = return Continue
exec (SFun name params _ body) = do
  let fun = Function (map snd params) body
  modify (\s -> s { functions = M.insert name fun (functions s) })
  return Normal

-- Uma volta do laço: prepara o escopo, roda o corpo e decide entre a próxima
-- volta (next) e a saída.
loopStep :: Eval () -> [Stmt] -> Eval Outcome -> Eval Outcome
loopStep setup body next = do
  outcome <- inScope (setup >> execStmts body)
  case outcome of
    Break -> return Normal
    Return value -> return (Return value)
    _ -> next

-- A lista é avaliada uma vez só, antes da primeira volta.
forEach :: String -> [Stmt] -> [Value] -> Eval Outcome
forEach _ _ [] = return Normal
forEach var body (item : items) =
  loopStep (declare var item) body (forEach var body items)

declare :: String -> Value -> Eval ()
declare name value = modify (\s -> s { scopes = insertTop (scopes s) })
  where
    insertTop (top : outer) = M.insert name value top : outer
    insertTop [] = [M.singleton name value]

-- Atribuição muda a variável no escopo mais interno que a tem, que pode ser
-- um de fora do bloco atual.
assign :: String -> Value -> Eval ()
assign name value = do
  frames <- gets scopes
  case break (M.member name) frames of
    (inner, frame : outer) -> do
      let updated = inner ++ M.insert name value frame : outer
      modify (\s -> s { scopes = updated })
    (_, []) -> throwError (Stuck ("atribuição a " ++ name))

lookupVar :: String -> Eval Value
lookupVar name = do
  frames <- gets scopes
  case mapMaybe (M.lookup name) frames of
    value : _ -> return value
    [] -> throwError (Stuck ("variável " ++ name))

atPos :: Pos -> Eval a -> Eval a
atPos pos action = catchError action (throwError . locate)
  where
    locate err@(RuntimeAt _ _) = err
    locate err = RuntimeAt pos err

eval :: Expr -> Eval Value
eval (EInt n) = return (VInt n)
eval (EFloat x) = return (VFloat x)
eval (EStr s) = return (VStr s)
eval (EBool b) = return (VBool b)
eval (EVar name) = lookupVar name
eval (EList elems) = VList <$> mapM eval elems
eval (ECall name args) = evalCall name args
eval (ENeg expr) = do
  value <- eval expr
  case value of
    VInt n -> return (VInt (negate n))
    VFloat x -> return (VFloat (negate x))
    _ -> throwError (Stuck "- em valor que não é número")
eval (ENot expr) = VBool . not <$> evalBool expr
-- e/ou em curto-circuito: o lado direito só é avaliado se decidir o resultado.
eval (EBinOp And left right) = do
  l <- evalBool left
  if l then VBool <$> evalBool right else return (VBool False)
eval (EBinOp Or left right) = do
  l <- evalBool left
  if l then return (VBool True) else VBool <$> evalBool right
eval (EBinOp op left right) = do
  l <- eval left
  r <- eval right
  binOp op l r

evalBool :: Expr -> Eval Bool
evalBool expr = do
  value <- eval expr
  case value of
    VBool b -> return b
    _ -> throwError (Stuck "condição que não é Certeza")

binOp :: Op -> Value -> Value -> Eval Value
binOp Eq l r = return (VBool (l == r))
binOp Div (VInt _) (VInt 0) = throwError DivByZero
binOp Div (VFloat _) (VFloat 0) = throwError DivByZero
binOp op (VInt a) (VInt b) = numOp VInt div op a b
binOp op (VFloat a) (VFloat b) = numOp VFloat (/) op a b
binOp _ _ _ = throwError (Stuck "operação entre valores de tipos errados")

-- Numero usa div, que arredonda para baixo como o // do Python.
numOp :: (Num a, Ord a) => (a -> Value) -> (a -> a -> a) -> Op -> a -> a -> Eval Value
numOp wrap divide op a b = case op of
  Add -> return (wrap (a + b))
  Sub -> return (wrap (a - b))
  Mul -> return (wrap (a * b))
  Div -> return (wrap (divide a b))
  Lt -> return (VBool (a < b))
  Gt -> return (VBool (a > b))
  Le -> return (VBool (a <= b))
  Ge -> return (VBool (a >= b))
  _ -> throwError (Stuck "operador lógico entre números")

evalCall :: String -> [Expr] -> Eval Value
evalCall name args = do
  values <- mapM eval args
  call name values

call :: String -> [Value] -> Eval Value
call "espia" [value] = do
  write (render value ++ "\n")
  return VUnit
call "pergunta" [VStr prompt] = do
  write prompt
  input <- asks readIn
  answer <- liftIO input
  maybe (throwError NoInput) (return . VStr) answer
call "encanga" [VStr a, VStr b] = return (VStr (a ++ b))
call "quantoTem" [VList values] = return (VInt (toInteger (length values)))
call "quantoTem" [VStr s] = return (VInt (toInteger (length s)))
call name values = do
  funs <- gets functions
  case M.lookup name funs of
    Just (Function params body)
      | length params == length values -> callUser params body values
    _ -> throwError (Stuck ("chamada de " ++ name))

-- O corpo roda numa pilha só com os parâmetros, como o type checker supôs; a
-- pilha de quem chamou volta no fim.
callUser :: [String] -> [Stmt] -> [Value] -> Eval Value
callUser params body values = do
  caller <- gets scopes
  modify (\s -> s { scopes = [M.fromList (zip params values)] })
  outcome <- execStmts body
  modify (\s -> s { scopes = caller })
  case outcome of
    Return value -> return value
    _ -> return VUnit

write :: String -> Eval ()
write text = do
  out <- asks writeOut
  liftIO (out text)

render :: Value -> String
render (VInt n) = show n
render (VFloat x) = showFFloat Nothing x ""
render (VStr s) = s
render (VBool True) = "Certo"
render (VBool False) = "Errado"
render (VList values) = "[" ++ intercalate ", " (map renderItem values) ++ "]"
render VUnit = "Nadica"

-- Dentro de uma ruma, a prosa aparece entre aspas para não se confundir com
-- a vírgula que separa os itens.
renderItem :: Value -> String
renderItem (VStr s) = "\"" ++ s ++ "\""
renderItem value = render value

runtimeErrorMessage :: RuntimeError -> String
runtimeErrorMessage (RuntimeAt (line, col) err) =
  "linha " ++ show line ++ ", coluna " ++ show col ++ ": " ++ runtimeErrorMessage err
runtimeErrorMessage DivByZero = "divisão por zero"
runtimeErrorMessage NoInput = "pergunta ficou sem resposta: a entrada acabou"
runtimeErrorMessage (Stuck what) =
  "erro interno, o checador de tipos deixou passar: " ++ what
