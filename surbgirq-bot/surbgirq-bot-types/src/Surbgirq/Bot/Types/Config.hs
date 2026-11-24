{-# LANGUAGE DeriveGeneric #-}

module Surbgirq.Bot.Types.Config where

import Control.Concurrent.STM
import Data.IORef

import Data.Text            (Text)
import GHC.Generics         (Generic)
import Network.HTTP.Client  (Manager)
import Servant.Client       (ClientEnv)
import Surbgirq.Types       (TranslationID)
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
  -- ^ the webhook's secret token (TELEGRAM_WEBHOOK_SECRET): every POST /tg-webhook must carry it
  , botApiHost          :: Text
  -- ^ telegram bot api server host
  , botApiPort          :: Int
  -- ^ telegram bot api server port
  , apiCachTime         :: Maybe Int
  -- ^ api wide cach time
  , graphApi            :: ClientEnv
  -- ^ the client for surbgirq-graph-api, made once at start-up (GRAPH_API_URL)
  , defaultBible        :: TranslationID
  -- ^ the Bible for a reference without a translation word, when the user hasn't chosen one (BOT_DEFAULT_BIBLE)
  , defaultNarek        :: TranslationID
  -- ^ the same for Narek (BOT_DEFAULT_NAREK)

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


