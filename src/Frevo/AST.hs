module Frevo.AST where

data Type
    = TInt
    | TFloat
    | TStr
    | TBool
    | TArray
    | TUnit
    deriving (Show, Eq)

data Op = Add | Sub | Mul | Div | Eq | Le | Ge | Lt | Gt | And | Or
  deriving (Show, Eq)

data Expr
  = EInt Int
  | EFloat Double
  | EStr String
  | EBool Bool
  | EVar String
  | EBinOp Op Expr Expr
  deriving (Show, Eq)

data Stmt
  = SAssign String Expr
  | SIf Expr [Stmt] (Maybe [Stmt])
  | SWhile Expr [Stmt]
  | SFor String Expr [Stmt]
  | SReturn Expr
  deriving (Show, Eq)