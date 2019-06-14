{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

module Surbgirq.Neo4j.Config where

import Data.Text (Text)

import Data.Default
import Database.Bolt


localCfg :: BoltCfg
localCfg = def { user = "neo4j", password = "CHANGE_ME" }



