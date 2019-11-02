{-|
Module      : Surbgirq.Neo4j.Store
Description : Neo4j Store state

Init data strucutre to hold Neo4j poll and etc
-}

module Surbgirq.Neo4j.Store where

import Data.Pool (Pool, createPool)

------------------------------------------------------------
--
------------------------------------------------------------

-- | create pool of connections (4 stripes, 500 ms timeout, 1 resource per stripe)
constructState :: BoltCfg -> IO ServerState
constructState bcfg = do pool <- createPool (connect bcfg) close 4 500 1
                         return (ServerState pool)
