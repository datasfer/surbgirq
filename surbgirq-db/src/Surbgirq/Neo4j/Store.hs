{-# LANGUAGE OverloadedStrings #-}


module Surbgirq.Neo4j.Store where


import Data.Pool (Pool, createPool)

-- |Create pool of connections (4 stripes, 500 ms timeout, 1 resource per stripe)
constructState :: BoltCfg -> IO ServerState
constructState bcfg = do pool <- createPool (connect bcfg) close 4 500 1
                         return (ServerState pool)
