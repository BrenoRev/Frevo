module Frevo.AST where

data Type = TInt | TFloat | TStr | TBool | TArray Type | TUnit
  deriving (Show, Eq)

data Op = Add | Sub | Mul | Div | Eq | Le | Ge | Lt | Gt | And | Or
  deriving (Show, Eq)

data Expr
  = EInt Int
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
  deriving (Show, Eq)
