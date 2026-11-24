{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE TemplateHaskell #-}

{-|
Module      : Types.Settings
Description : Settings types

Settings types
-}

module Types.BotSettings where

import Data.String

import Data.Text (Text)

import qualified Data.Text as T

import Common.Aeson

------------------------------------------------------------
--
------------------------------------------------------------

-- | Bots settings
data BotSettings = BotSettings
  {
    surbgirq'bots          :: !BotSpec
  } deriving (Show)

data BotSpec = BotSpec
  {
    bot'telegram  :: TelegramBotConfig
  -- ^ telegram bot settings
  } deriving(Show)

data TelegramBotConfig = TelegramBotConfig
    { telegramBotConfig'dbName      :: String
    , telegramBotConfig'botApiHost  :: String
    -- ^ the Telegram Bot API server (TELEGRAM_API_HOST)
    , telegramBotConfig'botApiPort  :: Int
    -- ^ its port (TELEGRAM_API_PORT)
    , telegramBotConfig'graphApiUrl :: String
    -- ^ surbgirq-graph-api's root, without /api (GRAPH_API_URL)
    , telegramBotConfig'defaultBible :: Text
    -- ^ the Bible for a reference without a translation word, when the user hasn't chosen one (BOT_DEFAULT_BIBLE)
    , telegramBotConfig'defaultNarek :: Text
    -- ^ the same for Narek (BOT_DEFAULT_NAREK)
    , telegramBotConfig'listenHost  :: String
    -- ^ where the webhook server listens (BOT_LISTEN_HOST)
    , telegramBotConfig'listenPort  :: Int
    -- ^ its port (BOT_LISTEN_PORT)
    } deriving (Show)


$(deriveJSON dropPrefixOptions     ''TelegramBotConfig)
$(deriveJSON dropPrefixOptions     ''BotSpec)
$(deriveJSON dropPrefixOptions     ''BotSettings)
