{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Bot.State.Types where

import Data.Map.Strict (Map)
import Data.Text       (Text)
import GHC.Generics    (Generic)

import qualified Data.Map.Strict as Map

import Common.Aeson
import Data.Aeson
import Data.Default
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

data BotState = BotState
 { state'users :: [User]
 } deriving (Show, Generic)

data User = User
 { user_id   :: Int
 , firstName :: String
 , lastName  :: String
 } deriving (Show, Generic)


data UserSetting = UserSetting
 {
   armScripture :: ArmScriptureConfig
 , menuLanguage :: Language
 } deriving (Show, Generic)


data ArmScriptureConfig = ArmScriptureConfig
 {
   translation_id :: Text
 , language       :: Language
 , dialect        :: Dialect
 } deriving (Show, Generic)


instance FromJSON User
instance ToJSON User

$(deriveJSON dropPrefixOptions ''BotState)

instance Default BotState where
    def = BotState mempty
