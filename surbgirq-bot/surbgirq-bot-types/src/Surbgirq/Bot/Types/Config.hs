{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Bot.Types.Config where

import Control.Concurrent.STM
import Data.IORef

import Data.Text            (Text)
import GHC.Generics         (Generic)
import Network.HTTP.Client  (Manager)
import Servant.Client       (ClientEnv)
import Web.Telegram.API.Bot (Token)

import Data.Aeson

import Surbgirq.Bot.State
------------------------------------------------------------
--
------------------------------------------------------------

type State = TVar BotState

data BotConfig = BotConfig
  {
  -- * Api wide settins
    telegramToken       :: Token
  -- ^ telegram bot token
  , webhookSecret       :: Text
  -- ^ the webhook's secret token (TELEGRAM_WEBHOOK_SECRET); its check comes next (README, Known issues)
  , botApiHost          :: Text
  -- ^ telegram bot api server host
  , botApiPort          :: Int
  -- ^ telegram bot api server port
  , apiCachTime         :: Maybe Int
  -- ^ api wide cach time
  , graphApi            :: ClientEnv
  -- ^ the client for surbgirq-graph-api, made once at start-up (GRAPH_API_URL)

  , facebookVerifyToken :: Text
  , facebookPageToken   :: Text
  , manager             :: Manager
  , facebookManager     :: Manager
  , ref                 :: IORef Int
  , state               :: State

  }


data Version = Version
  { version :: Text
  } deriving (Show, Generic)

instance ToJSON Version


