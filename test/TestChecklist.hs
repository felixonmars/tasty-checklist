{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}

module Main where

import Data.Parameterized.Context ( pattern Empty, pattern (:>) )
import Test.Tasty
import Test.Tasty.ExpectedFailure
import Test.Tasty.HUnit
import Test.Tasty.Checklist


main :: IO ()
main = defaultMain $ testGroup "Checklist testing"
       [
         expectFail $
         testCase "simple checklist" $
         withChecklist "simple" $ do
           let tst :: Int -> Bool
               tst = (> 3)
           check "one" tst 1
           check "two" tst 2
           check "five" tst 5
           check "three" tst 3
           check "four" tst 4

       , expectFail $
         testCase "simple checklist with retraction" $
         withChecklist "simple retracted" $ do
           let tst :: Int -> Bool
               tst = (> 3)
           check "one" tst 1
           check "two" tst 2
           check "five" tst 5
           check "three" tst 3
           check "four" tst 4
           discardCheck "two"

       , testCase "someFun 7 result" $
         withChecklist "someFun 7" $
         someFun 7 `checkValues`
         (Empty
          :> Val "foo" foo 42
          :> Val "baz" baz "The answer to the universe"
          :> Val "shown" show "The answer to the universe is 42!"
          :> Val "odd answer" oddAnswer False
         )

       , expectFailBecause "2 values don't match" $
         testCase "someFun 3 result" $
         withChecklist "someFun" $
         someFun 3 `checkValues`
         (Empty
          :> Val "foo" foo 42
          :> Val "baz" baz "The answer to the universe"
          :> Val "shown" show "The answer to the universe is 42!"
          :> Val "odd answer" oddAnswer False
         )

       , testCase "noshow object" $
         withChecklist "opaque object" $
         genOpaque `checkValues`
         (Empty
          :> Val "displayed" display "[[19]]"
          :> Val "answer" answer 19
          :> Val "revealed" reveal 19
          :> Val "the answer" answer 19
         )

       , expectFailBecause "revealed test is bad" $
         testCase "noshow object bad comparison" $
         withChecklist "opaque object bad expected" $
         genOpaque `checkValues`
         (Empty
          :> Val "displayed" display "[[19]]"
          :> Val "answer" answer 19
          :> Val "revealed" reveal 18
          :> Val "the answer" answer 19
         )

       ]

----------------------------------------------------------------------

data Struct = MyStruct { foo :: Int
                       , bar :: Char
                       , baz :: String }

instance Show Struct where
   show s = baz s <> " is " <> (show $ foo s) <> (bar s : [])

instance TestShow Struct  -- uses the Show instance

someFun :: Int -> Struct
someFun n = MyStruct (n * 6)
              (if n * 6 == 42 then '!' else '?')
              "The answer to the universe"

oddAnswer :: Struct -> Bool
oddAnswer = odd . foo

----------------------------------------------------------------------

data Opaque = Hidden { answer :: Int }

genOpaque :: Opaque
genOpaque = Hidden 19

reveal :: Opaque -> Int
reveal = answer

display :: Opaque -> String
display o = "[[" <> show (answer o) <> "]]"

-- Note that Opaque doesn't have a standard Show instance, but a
-- TestShow can be provided to suffice for testing.

instance TestShow Opaque where
  testShow = display
