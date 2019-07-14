{-# LANGUAGE OverloadedStrings #-}

module Neo4j.Data where


import Test.Tasty
import Test.Tasty.HUnit


import Database.Bolt

import Data.Default
import Surbgirq.Neo4j
-- import Surbgirq.Types.Girq

tests :: TestTree
tests = testGroup "network test"
  [ testGroup "mock"
    [ testCase "delayed write"  testBooks
    ]
  ]
config :: BoltCfg
config = def {user = "neo4j", password = "CHANGE_ME"}


testBooks :: IO ()
testBooks  = do
  pipe <- connect config
  result <- run pipe queryBooks
  -- assertEqual ("Get Books ") ([]) result
  asstasertBool "Books exists" (not $ null result )
  return ()
