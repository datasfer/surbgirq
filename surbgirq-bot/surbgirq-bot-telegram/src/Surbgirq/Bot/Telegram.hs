{-# LANGUAGE AllowAmbiguousTypes        #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE ViewPatterns               #-}
module Surbgirq.Bot.Telegram
    ( startApp
    , StartSettings (..)
    , app
    ) where
import Control.Monad                 (replicateM, when)
import Data.Char                     (isNumber)
import Data.List                     (intercalate, intersperse)
import Data.List.Split               (chunksOf)
import Data.String                   (fromString)
import Data.Text                     (Text, empty)
import Data.Version                  (makeVersion, showVersion)
import GHC.Generics                  hiding (from)
import Network.HTTP.Client           (Manager, newManager)
import Network.HTTP.Client.TLS       (tlsManagerSettings)
import Text.InterpolatedString.Perl6 (qc)
import Text.Read                     (readMaybe)

import Data.IORef

import qualified Data.Text      as T
import qualified Data.Text.Lazy as TL

import Lucid

import Control.Concurrent.STM
import Control.Monad.Except
import Control.Monad.Reader
import Data.Aeson
import Data.Default
import Data.Maybe
import Data.Monoid
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import Servant.Client                (ClientEnv)
import Servant.Server
import System.Environment
import Text.Regex.Posix

import Surbgirq.Bot.App
import Surbgirq.Bot.Server.TelegramAPI
import Surbgirq.Bot.Server.Webhook   (logLine)
import Surbgirq.Bot.Types
import Surbgirq.Types                (TranslationID)

------------------------------------------------------------
--
------------------------------------------------------------


-- if Settings.telegram_base_url != "https://api.telegram.org/bot":
--         r = requests.get(f"https://api.telegram.org/bot{Settings.telegram_token}/logOut")
--         logger.info("Using local bot API, logout result: %s", r.text)
-- print "API endpoint: %s", bot.base_url

-- (Moving to a local Bot API server: log the bot out of the cloud one first,
-- https://api.telegram.org/bot<token>/logOut; see docs/bot.md.)

-- | What the bot needs at start-up: bot-settings.yaml, where an environment variable overrides each value,
-- and the two secrets, read from the environment only (see .env.example).
data StartSettings = StartSettings
  { start'telegramApiHost :: String
  -- ^ the Telegram Bot API server: Telegram's own, or a local telegram-bot-api (TELEGRAM_API_HOST)
  , start'telegramApiPort :: Int
  -- ^ its port (TELEGRAM_API_PORT)
  , start'graphApi        :: ClientEnv
  -- ^ the client for surbgirq-graph-api (GRAPH_API_URL)
  , start'defaultBible    :: TranslationID
  -- ^ the Bible for a reference without a translation word, when the user hasn't chosen one (BOT_DEFAULT_BIBLE)
  , start'defaultNarek    :: TranslationID
  -- ^ the same for Narek (BOT_DEFAULT_NAREK)
  , start'listenHost      :: String
  -- ^ where the webhook server listens (BOT_LISTEN_HOST)
  , start'listenPort      :: Int
  -- ^ its port (BOT_LISTEN_PORT)
  , start'token           :: Text
  -- ^ the bot's token, without the "bot" prefix (TELEGRAM_BOT_TOKEN)
  , start'webhookSecret   :: Text
  -- ^ the webhook's secret token (TELEGRAM_WEBHOOK_SECRET)
  }

startApp :: StartSettings -> IO ()
startApp StartSettings{..} = do
  manager' <- newManager tlsManagerSettings
  fbManager <- newManager tlsManagerSettings
  ref <- liftIO $ newIORef (0 :: Int)
  state <- newTVarIO def

  let fbVerifyToken = "123456"
      fbPageToken = "REMOVED-FACEBOOK-TOKEN"

      config = BotConfig
        { telegramToken = Token $ "bot" <> start'token
        , webhookSecret = start'webhookSecret
        , botApiHost = T.pack start'telegramApiHost
        , botApiPort = start'telegramApiPort
        , apiCachTime = Just 333 --  amount of time in seconds that the result may be cached on the server.
        , graphApi = start'graphApi
        , defaultBible = start'defaultBible
        , defaultNarek = start'defaultNarek
        , facebookVerifyToken = fbVerifyToken
        , facebookPageToken = fbPageToken
        , manager = manager'
        , facebookManager = fbManager
        , ref = ref
        , state = state
        }
      warpSettings = setOnException logWarpException
                   $ setHost (fromString start'listenHost) $ setPort start'listenPort defaultSettings
      -- what Warp prints by itself (a failure outside the update handling) goes through the same one-line log, which
      -- replaces anything shaped like a bot token
      logWarpException _ e = when (defaultShouldDisplayException e) $ logLine $ "Warp: " <> show e

  putStrLn $ concat [ "Surbgirq bot: listening on ", start'listenHost, ":", show start'listenPort
                    , "; Telegram at ", start'telegramApiHost, ":", show start'telegramApiPort ]
  runSettings warpSettings $ app config
