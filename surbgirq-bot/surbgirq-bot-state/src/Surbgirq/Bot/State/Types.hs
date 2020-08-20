{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Bot.State.Types where

import Data.Map.Strict (Map)
import Data.Text       (Text)
import GHC.Generics    (Generic)

import Common.Aeson
import Data.Aeson
import Data.Default
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

data BotState = BotState
 { state'users :: [BotUser]
 } deriving (Show, Generic)

data BotUser = BotUser
 { id :: Int
 } deriving (Show, Generic)


instance FromJSON BotUser
instance ToJSON BotUser

$(deriveJSON dropPrefixOptions ''BotState)

instance Default BotState where
    def = BotState mempty
