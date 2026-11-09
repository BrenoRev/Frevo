import qualified Frevo.ErroSpec
import qualified Frevo.ExprSpec
import qualified Frevo.InferSpec
import qualified Frevo.LexerSpec
import qualified Frevo.StatementSpec
import qualified Frevo.StmtSpec
import qualified Frevo.TypeSpec
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "léxico" Frevo.LexerSpec.spec
  describe "expressões" Frevo.ExprSpec.spec
  describe "comandos" Frevo.StmtSpec.spec
  describe "erros e casos de borda" Frevo.ErroSpec.spec
  describe "ambiente de tipos" Frevo.TypeSpec.spec
  describe "inferência de tipos" Frevo.InferSpec.spec
  describe "checagem de comandos" Frevo.StatementSpec.spec
