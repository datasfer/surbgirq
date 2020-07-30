{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Bot.Types where


import Data.Text            (Text)
import GHC.Generics         (Generic)
import Network.HTTP.Client  (Manager)
import Web.Telegram.API.Bot (Token)

import Data.Aeson

------------------------------------------------------------
--
------------------------------------------------------------


data BotConfig = BotConfig
  { telegramToken :: Token
  , manager       :: Manager
  }

data Version = Version
  { version :: Text
  } deriving (Show, Generic)

instance ToJSON Version


