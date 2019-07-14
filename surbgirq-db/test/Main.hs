import Test.Tasty

import qualified Neo4j.Data

main :: IO ()
main = defaultMain $ testGroup "Neo4j store"
  [ Neo4j.Data.tests
  ]
