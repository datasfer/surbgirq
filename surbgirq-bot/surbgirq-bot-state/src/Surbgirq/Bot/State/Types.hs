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

type UserConfigMap = Map UserId UserSetting

data BotState = BotState
 { state'users   :: [BotUser]
 , state'configs :: UserConfigMap

 } deriving (Show, Generic)

data BotUser = BotUser
 { userId    :: UserId
 , firstName :: String
 , lastName  :: String
 } deriving (Show, Generic)


data UserSetting = UserSetting
 {
   armScripture :: ScriptureConfig
 , menuLanguage :: Language
 } deriving (Show, Generic)

newtype UserId = UserId { unUserId :: Int }
    deriving (Show, Read, Eq, Ord, Generic)


data ScriptureConfig = ScriptureConfig
 {
   bible            :: Text
 , parallelBibles   :: [Text]
 , narek            :: Text
 , parallelNarek    :: [Text]
 , subscriptionMode :: Bool
 } deriving (Show, Generic)




instance Default BotState where
    def = BotState mempty mempty

instance Default UserSetting where
    def = UserSetting def EN

instance Default ScriptureConfig where
    def = ScriptureConfig mempty mempty mempty mempty False

$(deriveJSON dropPrefixOptions ''BotState)

instance FromJSON BotUser
instance ToJSON BotUser
instance ToJSONKey UserId
instance FromJSONKey UserId
instance ToJSON UserId
instance FromJSON UserId
instance ToJSON UserSetting
instance FromJSON UserSetting
instance ToJSON ScriptureConfig
instance FromJSON ScriptureConfig
