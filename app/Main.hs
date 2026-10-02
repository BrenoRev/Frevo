module Main where

import Frevo.Parser
import qualified Data.Text.IO as TIO
import Text.Megaparsec (errorBundlePretty)
import System.Environment (getArgs)
import System.IO (IOMode(ReadMode), hSetEncoding, stdout, utf8, withFile)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  args <- getArgs
  case args of
    [] -> putStrLn "Passe o caminho de um arquivo para rodar o parser."
    (fileName:_) -> withFile fileName ReadMode $ \handle -> do
      hSetEncoding handle utf8
      content <- TIO.hGetContents handle
      case parseProgram fileName content of
        Left err  -> putStrLn (errorBundlePretty err)
        Right ast -> print ast