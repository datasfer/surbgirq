{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Surbgirq.Neo4j.Config
Description : Neo4j config

Neo4j db configuration
-}

module Surbgirq.Neo4j.Config where

import Data.Default
import Database.Bolt

------------------------------------------------------------
--
------------------------------------------------------------

-- TODO: read from config file
-- | Neo4j db config
localCfg :: BoltCfg
localCfg = def { user = "neo4j", password = "CHANGE_ME" }



