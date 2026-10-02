{-# LANGUAGE OverloadedStrings #-}
module Frevo.Parser where

import Frevo.AST
import Data.Text (Text)
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Control.Monad.Combinators.Expr (makeExprParser, Operator(..))

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 (L.skipLineComment "#") empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

rword :: Text -> Parser ()
rword w = (lexeme . try) (string w *> notFollowedBy alphaNumChar)

pInteger :: Parser Expr
pInteger = EInt <$> lexeme L.decimal

pFloat :: Parser Expr
pFloat = EFloat <$> lexeme L.float

pString :: Parser Expr
pString = EStr <$> lexeme (char '"' *> manyTill L.charLiteral (char '"'))

pBool :: Parser Expr
pBool = (EBool True <$ rword "Certo")
    <|> (EBool False <$ rword "Errado")

pIdentifier :: Parser String
pIdentifier = (lexeme . try) (p >>= check)
  where
    p = (:) <$> (letterChar <|> char '_') <*> many (alphaNumChar <|> char '_')
    check x = if x `elem` reservedKeywords
                then fail $ "Palavra reservada não pode ser usada como identificador: " ++ x
                else return x

reservedKeywords :: [String]
reservedKeywords =
  [ "de", "se", "sinão", "enquanto", "faça", "cabousse"
  , "pracada", "devolve", "função", "então", "nam", "e", "ou"
  , "Certo", "Errado", "Certeza", "Ruma", "Nadica", "Prosa"
  , "Quebrado", "Numero", "poparrar", "segue"
  ]

pTerm :: Parser Expr
pTerm = choice
  [ try pFloat
  , pInteger
  , pBool
  , pString
  , EVar <$> pIdentifier
  , between (symbol "(") (symbol ")") pExpr
  ]

pExpr :: Parser Expr
pExpr = makeExprParser pTerm operatorTable

operatorTable :: [[Operator Parser Expr]]
operatorTable =
  [ [ InfixL (EBinOp Mul <$ symbol "*")
    , InfixL (EBinOp Div <$ symbol "/")
    ]
  , [ InfixL (EBinOp Add <$ symbol "+")
    , InfixL (EBinOp Sub <$ symbol "-")
    ]
  , [ InfixN (EBinOp Eq <$ symbol "==")
    , InfixN (EBinOp Le <$ symbol "<=")
    , InfixN (EBinOp Ge <$ symbol ">=")
    , InfixN (EBinOp Lt <$ symbol "<")
    , InfixN (EBinOp Gt <$ symbol ">")
    ]
  , [ InfixL (EBinOp And <$ rword "e")
    , InfixL (EBinOp Or  <$ rword "ou")
    ]
  ]

pStmt :: Parser Stmt
pStmt = choice
  [ pIf
  , pWhile
  , pFor
  , pReturn
  , pAssign
  ]

pIf :: Parser Stmt
pIf = do
  _ <- rword "se" <|> rword "de"
  cond <- pExpr
  _ <- rword "então"
  thenBody <- many pStmt
  elseBody <- optional (rword "sinão" *> many pStmt)
  _ <- rword "cabousse"
  return (SIf cond thenBody elseBody)

pWhile :: Parser Stmt
pWhile = do
  _ <- rword "enquanto"
  cond <- pExpr
  _ <- rword "faça"
  body <- many pStmt
  _ <- rword "cabousse"
  return (SWhile cond body)

pFor :: Parser Stmt
pFor = do
    _ <- rword "pracada"
    var <- pIdentifier
    _ <- rword "em"
    iterable <- pExpr
    _ <- rword "faça"
    body <- many pStmt
    _ <- rword "cabousse"
    return (SFor var body)

pReturn :: Parser Stmt
pReturn = SReturn <$> (rword "devolve" *> pExpr)

pAssign :: Parser Stmt
pAssign = do
  var <- pIdentifier
  _ <- symbol "="
  val <- pExpr
  return (SAssign var val)

parseProgram :: FilePath -> Text -> Either (ParseErrorBundle Text Void) [Stmt]
parseProgram filename input = runParser (sc *> many pStmt <* eof) filename input