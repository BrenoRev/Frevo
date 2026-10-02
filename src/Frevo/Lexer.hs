{-# LANGUAGE OverloadedStrings #-}
module Frevo.Lexer where

import Data.Text (Text)
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 (L.skipLineComment "#") empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

brackets :: Parser a -> Parser a
brackets = between (symbol "[") (symbol "]")

identChar :: Parser Char
identChar = alphaNumChar <|> char '_'

-- Sem o notFollowedBy, "se" casaria com o começo de "segue" ou "sementes".
rword :: Text -> Parser ()
rword w = (lexeme . try) (string w *> notFollowedBy identChar)

reservedKeywords :: [String]
reservedKeywords =
  [ "se", "então", "sinão", "cabousse", "enquanto", "faça", "pracada", "em"
  , "poparrar", "segue", "função", "devolve", "e", "ou", "nam"
  , "Certo", "Errado", "Numero", "Quebrado", "Prosa", "Certeza"
  , "Ruma", "de", "Nadica"
  ]

pIdentifier :: Parser String
pIdentifier = (lexeme . try) (getOffset >>= \start -> name >>= check start) <?> "nome"
  where
    name = (:) <$> (letterChar <|> char '_') <*> many identChar
    -- Volta o offset para o erro apontar o começo da palavra, não o fim.
    check start x
      | x `elem` reservedKeywords =
          setOffset start *> fail ("palavra reservada não pode ser usada como nome: " ++ x)
      | otherwise = return x
