{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}


module Surbgirq.Bot.State.Types where

import Data.Map.Strict (Map)
import Data.Set        (Set)
import Data.Text       (Text)
import GHC.Generics    (Generic)

import qualified Data.Map.Strict as Map
import qualified Data.Set        as Set

import Common.Aeson
import Data.Aeson
import Data.Default
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------

type UserConfigMap = Map UserId UserSettings

data BotState = BotState
 { state'users   :: [BotAppUser]
 , state'configs :: UserConfigMap

 } deriving (Show, Generic)

data BotAppUser = BotAppUser
 { userId    :: UserId
 , firstName :: String
 , lastName  :: String
 } deriving (Show, Generic)


data UserSettings = UserSettings
 { config'bible            :: Text
 , config'parallelBibles   :: Set Text
 , config'narek            :: Text
 , config'parallelNarek    :: Set Text
 , config'subscriptionMode :: Bool

 , config'menuLanguage     :: Language
 } deriving (Show, Generic)

newtype UserId = UserId { unUserId :: Int }
    deriving (Show, Read, Eq, Ord, Generic)

instance Default BotState where
    def = BotState mempty mempty

instance Default UserSettings where
    def = UserSettings "e1994#" mempty "gevNarek#" mempty False EN

$(deriveJSON dropPrefixOptions ''BotState)

instance FromJSON BotAppUser
instance ToJSON BotAppUser
instance ToJSONKey UserId
instance FromJSONKey UserId
instance ToJSON UserId
instance FromJSON UserId
instance ToJSON UserSettings
instance FromJSON UserSettings
