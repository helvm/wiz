module Wiz.EvalApplySpec where

import qualified Data.Map as Map
import           Test.Hspec
import           Text.Parsec (parse)
import qualified Wiz.EvalApply as W
import           Wiz.Parser
import           Wiz.Types
import           Wiz.Environment

import Data.Maybe (fromMaybe)
import Text.ParserCombinators.Parsec.Error (
  ParseError,
  Message,
  errorMessages,
  messageEq )

parseForm str = do
  let res = parse pForm "(source)" str
  case res of
    Left err -> error "Something gone wrong!"
    Right f  -> return f

testForm programFile form expectedResults = do
  prg <- loadProgram programFile
  env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
  expr <- parseForm form
  results <- W.eval expr env
  snd results `shouldBe` expectedResults

testForm' programFile form expectedForm = do
  prg <- loadProgram programFile
  env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
  expr <- parseForm form
  expectedExpr <- parseForm expectedForm
  expectedResults <- W.eval expectedExpr env
  results <- W.eval expr env
  snd results `shouldBe` snd expectedResults

spec = describe "main" $ do
  
  describe "parse" $ do
    it "parses form /1 (number)" $
      parse pForm "(test)" "1" `shouldBe` Right (FExpr (Number 1))
  
    it "parses form /2" $
      parse pForm "(test)" "(1 2)" `shouldBe`
        Right (FExpr (List [Number 1, Number 2]))

    it "parses form /3" $
      parse pForm "(test)" "(let ((a 10)) a)" `shouldBe`
        Right (FExpr (List
                      [Symbol "let",
                       List [List [Symbol "a", Number 10]], Symbol "a"]))

    it "parses form /4" $
      parse pForm "(test)" "(let ((a 10) (b 20)) a)" `shouldBe`
        Right (FExpr (List
                      [Symbol "let",
                       List [List [Symbol "a", Number 10],
                             List [Symbol "b", Number 20]], Symbol "a"]))

    it "parses form /5" $
      parse pForm "(test)" "(<= 1 2)" `shouldBe`
        Right (FExpr (List
                      [Operator "<=",
                       Number 1,
                       Number 2]))

  describe "eval" $ do

    it "quoted list" $
      testForm'
        "init.scm"
        "(car '(Harry had a heap of apples))"
        "'Harry"

    it "eval atom?" $
      testForm'
        "init.scm"
        "(atom? 'a)"
        "#t"

    it "eval atom? /2" $
      testForm'
        "init.scm"
        "(atom? (car '(Harry had a heap of apples)))"
        "#t"

    it "eval atom? /3" $
      testForm'
        "init.scm"
        "(atom? '(a b c))"
        "#f"

    it "eval numeric expressions as integers" $
      testForm'
        "init.scm"
        "1"
        "1"

    it "eval simple arithmetic operations" $
      testForm'
        "init.scm"
        "(+ 2 2)"
        "4"

    it "eval simple comparison operator" $
      testForm'
        "init.scm"
        "(< 1 2)"
        "#t"

    it "eval simple comparison operator /2" $
      testForm'
        "init.scm"
        "(> 1 2)"
        "#f"

    it "eval simple comparison operator /3" $
      testForm'
        "init.scm"
        "(> 3 2 5)"
        "#f"

    it "eval simple comparison operator /3" $
      testForm'
        "init.scm"
        "(> 3 3 5)"
        "#f"

    it "eval function calls /square" $
      testForm'
        "test/square.scm"
        "(square 10)"
        "100"

    it "eval recursive function calls /fact" $
      testForm'
        "init.scm"
        "(fact 10)"
        "3628800"

    it "eval recursive function calls /map" $
      testForm'
        "init.scm"
        "(map fact '(1 2 3))"
        "(1 2 6)"

    it "eval another recursive function calls /length" $
      testForm'
        "init.scm"
        "(length '(1 2 3))"
        "3"

    it "eval (let) form" $
      testForm'
        "init.scm"
        "(let ((a 10) (b 20)) a)"
        "10"

    it "eval (let) form /2" $
      testForm'
        "init.scm"
        "(let ((a 10) (b 20)) (+ a b))"
        "30"

    it "eval closure form" $
      testForm'
        "init.scm"
        "(add1 10)"
        "11"

    it "procedure returning closure" $
       testForm'
        "test/closure.scm"
        "(m 10)"
        "20"

    it "count change example" $ do
      prg <- loadProgram "init.scm"
      prg' <- loadProgram "test/count-change.scm"
      env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
      env' <- W.runProgram env $ fromMaybe (Program []) prg'
      expr <- parseForm "(count-change 100)"
      results <- W.eval expr env'
      results `shouldBe` (env', Just (E $ Number 292))

  describe "set! instructions" $ do
    it "eval set!" $
      testForm'
        "test/set.scm"
        "a"
        "20"

    it "eval set-car!" $
      testForm'
        "test/set-car.scm"
        "list"
        "(2 2 3)"

    it "eval set-cdr!" $ do
      prg <- loadProgram "init.scm"
      prg' <- loadProgram "test/set-cdr.scm"
      env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
      env' <- W.runProgram env $ fromMaybe (Program []) prg'
      expr <- parseForm "list"
      results <- W.eval expr env'
      snd results `shouldBe` Just (E $ List [Number 1, Number 20, Number 30])

    it "eval set-cdr! (it preserves list length as calculated by length)" $ do
      prg <- loadProgram "init.scm"
      prg' <- loadProgram "test/set-cdr.scm"
      env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
      env' <- W.runProgram env $ fromMaybe (Program []) prg'
      expr <- parseForm "(length list)"
      results <- W.eval expr env'
      snd results `shouldBe` Just (E $ Number 3)

    it "eval set-cdr!" $ do
      prg <- loadProgram "test/set-cdr-2.scm"
      env <- W.runProgram emptyEnv $ fromMaybe (Program []) prg
      expr <- parseForm "list"
      results <- W.eval expr env
      snd results `shouldBe` Just (E $ List [Number 1, Number 20])
