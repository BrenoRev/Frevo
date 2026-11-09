module Frevo.AST where

-- Linha e coluna em que um comando começa.
type Pos = (Int, Int)

data Type = TInt | TFloat | TStr | TBool | TArray Type | TUnit
  deriving (Show, Eq)

data Op = Add | Sub | Mul | Div | Eq | Le | Ge | Lt | Gt | And | Or
  deriving (Show, Eq)

data Expr
  = EInt Integer
  | EFloat Double
  | EStr String
  | EBool Bool
  | EVar String
  | EList [Expr]
  | ECall String [Expr]
  | ENeg Expr
  | ENot Expr
  | EBinOp Op Expr Expr
  deriving (Show, Eq)

data Stmt
  = SDecl Type String Expr
  | SAssign String Expr
  | SCall String [Expr]
  | SIf Expr [Stmt] (Maybe [Stmt])
  | SWhile Expr [Stmt]
  | SFor String Expr [Stmt]
  | SReturn Expr
  | SBreak
  | SContinue
  | SFun String [(Type, String)] Type [Stmt]
  -- O parser embrulha cada comando com a posição dele; quem monta a AST à mão
  -- pode omitir.
  | SAt Pos Stmt
  deriving (Show, Eq)
