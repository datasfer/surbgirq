{-# LANGUAGE TemplateHaskell              #-}
{-# LANGUAGE OverloadedStrings              #-}

module Surbgirq.Neo4j.Config where

import           Database.Bolt
import           Data.Default

localCfg :: BoltCfg
localCfg = def { user = "neo4j", password = "CHANGE_ME" }
