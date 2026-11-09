module Frevo.TypeChecker (typecheckProgram, typeErrorMessage) where

import Frevo.AST
import Frevo.Statement (checkBlock)
import Frevo.TypeEnv

typecheckProgram :: [Stmt] -> Either TypeError ()
typecheckProgram prog = runTC (checkBlock prog) stdlibEnv

typeName :: Type -> String
typeName TInt = "Numero"
typeName TFloat = "Quebrado"
typeName TStr = "Prosa"
typeName TBool = "Certeza"
typeName (TArray t) = "Ruma de " ++ typeName t
typeName TUnit = "Nadica"

opName :: Op -> String
opName Add = "+"
opName Sub = "-"
opName Mul = "*"
opName Div = "/"
opName Eq = "=="
opName Le = "<="
opName Ge = ">="
opName Lt = "<"
opName Gt = ">"
opName And = "e"
opName Or = "ou"

argCount :: Int -> String
argCount 1 = "1 argumento"
argCount n = show n ++ " argumentos"

typeErrorMessage :: TypeError -> String
typeErrorMessage (TypeAt (line, col) err) =
  "linha " ++ show line ++ ", coluna " ++ show col ++ ": " ++ typeErrorMessage err
typeErrorMessage (TypeMismatch expected found) =
  "era pra ser " ++ typeName expected ++ ", mas veio " ++ typeName found
typeErrorMessage (InvalidOp op t1 t2) =
  "não dá pra usar " ++ opName op ++ " entre " ++ typeName t1 ++ " e " ++ typeName t2
typeErrorMessage (InvalidUnaryOp op t) =
  "não dá pra usar " ++ opName op ++ " na frente de " ++ typeName t
typeErrorMessage (UndefinedVar name) =
  "a variável " ++ name ++ " não foi declarada"
typeErrorMessage (UndefinedFun name) =
  "a função " ++ name ++ " não existe ou só é definida mais abaixo"
typeErrorMessage (DuplicateFun name) =
  "já existe uma função chamada " ++ name
typeErrorMessage (ArityMismatch name expected found) =
  name ++ " recebe " ++ argCount expected ++ ", mas foi chamada com " ++ show found
typeErrorMessage (ArrayHeterogeneousType t1 t2) =
  "a ruma mistura " ++ typeName t1 ++ " com " ++ typeName t2
typeErrorMessage EmptyList =
  "aqui não dá pra saber o tipo de []; declare antes, como em Ruma de Numero xs = []"
typeErrorMessage (EmptyListMismatch expected) =
  "[] só serve onde se espera uma Ruma, mas aqui se espera " ++ typeName expected
typeErrorMessage VoidListElement =
  "função Nadica não devolve valor pra botar na ruma"
typeErrorMessage (NoIterable t) =
  "pracada só anda em Ruma, mas veio " ++ typeName t
typeErrorMessage BreakOutsideLoop =
  "poparrar só pode aparecer dentro de enquanto ou pracada"
typeErrorMessage ContinueOutsideLoop =
  "segue só pode aparecer dentro de enquanto ou pracada"
typeErrorMessage ReturnOutsideFunction =
  "devolve só pode aparecer dentro de função"
typeErrorMessage (DuplicateParam fun param) =
  "a função " ++ fun ++ " tem dois parâmetros chamados " ++ param
typeErrorMessage (MissingReturn name) =
  "a função " ++ name ++ " pode chegar no cabousse sem devolve"
typeErrorMessage (InvalidArg name t) =
  name ++ " não aceita " ++ typeName t
typeErrorMessage (ArgMismatch fun index expected found) =
  "o " ++ show index ++ "º argumento de " ++ fun ++ " era pra ser " ++ typeName expected
    ++ ", mas veio " ++ typeName found
typeErrorMessage VoidReturn =
  "função Nadica não usa devolve: ela termina no cabousse"
