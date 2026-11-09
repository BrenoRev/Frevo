module Main where

import Control.Exception (Handler (..), IOException, catches)
import qualified Data.Text as T
import Data.Text.Encoding.Error (UnicodeException)
import qualified Data.Text.IO.Utf8 as T
import Frevo.AST (Stmt)
import Frevo.Interpreter (Console (..), runProgram, runtimeErrorMessage)
import Frevo.Parser (parseProgram)
import Frevo.TypeChecker (typecheckProgram, typeErrorMessage)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO
import Text.Megaparsec (errorBundlePretty)

main :: IO ()
main = do
  mapM_ (`hSetEncoding` utf8) [stdin, stdout, stderr]
  hSetNewlineMode stdin universalNewlineMode
  args <- getArgs
  case args of
    ["--ast", path] -> loadProgram path >>= mapM_ print
    [path] -> loadProgram path >>= checkAndRun
    _ -> failWith "Uso: Frevo [--ast] <arquivo.frevo>" ""

loadProgram :: FilePath -> IO [Stmt]
loadProgram path = do
  raw <- T.readFile path `catches` [Handler (cannotOpen path), Handler (notUtf8 path)]
  -- O Bloco de Notas do Windows grava um BOM no começo do arquivo.
  let source = T.dropWhile (== '\xFEFF') raw
  case parseProgram path source of
    Right prog -> return prog
    Left err -> failWith "Oxe, num entendi essa parte:" (errorBundlePretty err)

-- Abrir (arquivo que não existe, pasta, sem permissão) e decodificar falham
-- com exceções de tipos diferentes; cada uma tem a sua mensagem.
cannotOpen :: FilePath -> IOException -> IO a
cannotOpen path _ =
  failWith ("Oxe, não deu pra abrir " ++ path ++ ".") "Confira se o arquivo existe e se dá pra ler ele.\n"

notUtf8 :: FilePath -> UnicodeException -> IO a
notUtf8 path _ =
  failWith ("Oxe, " ++ path ++ " não está em UTF-8.") "Salve o arquivo de novo escolhendo a codificação UTF-8.\n"

-- A checagem vem antes de qualquer execução: programa mal tipado não roda
-- nem a primeira linha.
checkAndRun :: [Stmt] -> IO ()
checkAndRun prog = case typecheckProgram prog of
  Left err -> failWith "Vixe, os tipos num batem:" (typeErrorMessage err ++ "\n")
  Right () -> do
    result <- runProgram terminal prog
    case result of
      Right () -> return ()
      Left err -> failWith "Eita, deu ruim rodando o programa:" (runtimeErrorMessage err ++ "\n")

terminal :: Console
terminal = Console { writeOut = writeFlushed, readIn = readLineOrEnd }

-- Sem o flush, o texto de pergunta só apareceria depois da resposta.
writeFlushed :: String -> IO ()
writeFlushed text = do
  putStr text
  hFlush stdout

readLineOrEnd :: IO (Maybe String)
readLineOrEnd = do
  end <- isEOF
  if end then return Nothing else Just <$> getLine

failWith :: String -> String -> IO a
failWith title detail = do
  hPutStrLn stderr title
  hPutStr stderr detail
  exitFailure
