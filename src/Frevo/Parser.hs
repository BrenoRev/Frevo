{-# LANGUAGE OverloadedStrings #-}
module Frevo.Parser where

import Control.Monad (when)
import Control.Monad.Combinators.Expr (Operator (..), makeExprParser)
import Data.Char (isDigit)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void)
import Frevo.AST
import Frevo.Lexer
import Text.Megaparsec
import Text.Megaparsec.Char (char)
import qualified Text.Megaparsec.Char.Lexer as L

-- Número colado em letra ("2pac") é erro, não um número seguido de um nome.
number :: Parser a -> Parser a
number p = lexeme (p <* notFollowedBy identChar)

pInteger :: Parser Expr
pInteger = EInt <$> number L.decimal

-- O try fica só no token: "1" sozinho falha aqui depois de consumir e tem de
-- voltar para pInteger. O L.float lê o expoente como Int, que dá a volta com
-- expoente gigante (1e18446744073709551617 virava 10.0); por isso a gramática
-- limita o expoente a três dígitos, e com ele só o infinito sobra para recusar.
pFloat :: Parser Expr
pFloat = do
  start <- getOffset
  (text, x) <- try (number (match L.float))
  let failAtStart msg = region (setErrorOffset start) (fail msg)
  when (exponentDigits text > 3) $ failAtStart "o expoente tem no máximo três dígitos"
  when (isInfinite x) $ failAtStart "número fora da faixa de Quebrado"
  return (EFloat x)

exponentDigits :: Text -> Int
exponentDigits = T.length . T.filter isDigit . T.dropWhile (`notElem` ['e', 'E'])

pString :: Parser Expr
pString = EStr <$> lexeme (char '"' *> manyTill L.charLiteral (char '"'))

pBool :: Parser Expr
pBool = EBool True <$ rword "Certo" <|> EBool False <$ rword "Errado"

pArgs :: Parser [Expr]
pArgs = parens (pExpr `sepBy` symbol ",")

pCallOrVar :: Parser Expr
pCallOrVar = do
  name <- pIdentifier
  ECall name <$> pArgs <|> pure (EVar name)

pTerm :: Parser Expr
pTerm = choice
  [ pFloat
  , pInteger
  , pBool
  , pString
  , EList <$> brackets (pExpr `sepBy` symbol ",")
  , pCallOrVar
  , parens pExpr
  ]

pExpr :: Parser Expr
pExpr = makeExprParser pTerm operatorTable <?> "expressão"

-- Da maior para a menor precedência.
operatorTable :: [[Operator Parser Expr]]
operatorTable =
  [ [ Prefix (ENeg <$ symbol "-") ]
  , [ binary Mul "*", binary Div "/" ]
  , [ binary Add "+", binary Sub "-" ]
    -- "<=" e ">=" vêm antes de "<" e ">", senão o símbolo curto casa primeiro.
  , [ comparison Eq "==", comparison Le "<=", comparison Ge ">="
    , comparison Lt "<", comparison Gt ">" ]
  , [ Prefix (ENot <$ rword "nam") ]
  , [ InfixL (EBinOp And <$ rword "e") ]
  , [ InfixL (EBinOp Or <$ rword "ou") ]
  ]
  where
    binary op s = InfixL (EBinOp op <$ symbol s)
    comparison op s = InfixN (EBinOp op <$ symbol s)

pType :: Parser Type
pType = choice
  [ TInt <$ rword "Numero"
  , TFloat <$ rword "Quebrado"
  , TStr <$ rword "Prosa"
  , TBool <$ rword "Certeza"
  , TArray <$> (rword "Ruma" *> rword "de" *> pType)
  ]

-- A posição é lida antes do comando, então aponta a primeira palavra dele.
located :: Parser Stmt -> Parser Stmt
located p = do
  pos <- getSourcePos
  SAt (unPos (sourceLine pos), unPos (sourceColumn pos)) <$> p

pStmt :: Parser Stmt
pStmt = located $ choice
  [ pIf
  , pWhile
  , pFor
  , SReturn <$> (rword "devolve" *> pExpr)
  , SBreak <$ rword "poparrar"
  , SContinue <$ rword "segue"
  , SDecl <$> pType <*> pIdentifier <* symbol "=" <*> pExpr
  , pAssignOrCall
  ]

pBlock :: Parser [Stmt]
pBlock = many pStmt

pIf :: Parser Stmt
pIf = do
  rword "se"
  cond <- pExpr
  rword "então"
  thenBody <- pBlock
  elseBody <- optional (rword "sinão" *> pBlock)
  rword "cabousse"
  return (SIf cond thenBody elseBody)

pWhile :: Parser Stmt
pWhile = do
  rword "enquanto"
  cond <- pExpr
  rword "faça"
  body <- pBlock
  rword "cabousse"
  return (SWhile cond body)

pFor :: Parser Stmt
pFor = do
  rword "pracada"
  var <- pIdentifier
  rword "em"
  iterable <- pExpr
  rword "faça"
  body <- pBlock
  rword "cabousse"
  return (SFor var iterable body)

pAssignOrCall :: Parser Stmt
pAssignOrCall = do
  name <- pIdentifier
  SAssign name <$> (symbol "=" *> pExpr) <|> SCall name <$> pArgs

pFun :: Parser Stmt
pFun = do
  rword "função"
  name <- pIdentifier
  params <- parens (((,) <$> pType <*> pIdentifier) `sepBy` symbol ",")
  _ <- symbol "->"
  ret <- pType <|> TUnit <$ rword "Nadica"
  body <- pBlock
  rword "cabousse"
  return (SFun name params ret body)

parseProgram :: FilePath -> Text -> Either (ParseErrorBundle Text Void) [Stmt]
parseProgram = runParser (sc *> many (located pFun <|> pStmt) <* eof)
