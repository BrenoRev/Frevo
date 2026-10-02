import qualified Frevo.ErroSpec
import qualified Frevo.ExprSpec
import qualified Frevo.LexerSpec
import qualified Frevo.StmtSpec
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "léxico" Frevo.LexerSpec.spec
  describe "expressões" Frevo.ExprSpec.spec
  describe "comandos" Frevo.StmtSpec.spec
  describe "erros e casos de borda" Frevo.ErroSpec.spec
