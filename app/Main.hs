module Main where

import qualified Data.Text as T
import qualified Data.Text.IO.Utf8 as T
import Frevo.Parser (parseProgram)
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStr, hPutStrLn, hSetEncoding, stderr, stdout, utf8)
import Text.Megaparsec (errorBundlePretty)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  case args of
    [path] -> do
      -- O Bloco de Notas do Windows grava um BOM no começo do arquivo.
      source <- T.dropWhile (== '\xFEFF') <$> T.readFile path
      case parseProgram path source of
        Right ast -> mapM_ print ast
        Left err -> do
          hPutStrLn stderr "Oxe, num entendi essa parte:"
          hPutStr stderr (errorBundlePretty err)
          exitFailure
    _ -> do
      hPutStrLn stderr "Uso: Frevo <arquivo.frevo>"
      exitFailure
