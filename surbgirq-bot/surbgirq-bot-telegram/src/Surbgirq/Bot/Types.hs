{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Bot.Types where

import Data.IORef

import Data.Text            (Text)
import GHC.Generics         (Generic)
import Network.HTTP.Client  (Manager)
import Web.Telegram.API.Bot (Token)

import Data.Aeson

------------------------------------------------------------
--
------------------------------------------------------------


data BotConfig = BotConfig
  { telegramToken       :: Token
  , facebookVerifyToken :: Text
  , facebookPageToken   :: Text
  , manager             :: Manager
  , facebookManager     :: Manager
  , ref                 :: IORef Int
  }

data Version = Version
  { version :: Text
  } deriving (Show, Generic)

instance ToJSON Version


