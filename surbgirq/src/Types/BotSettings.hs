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

newtype TelegramBotConfig = TelegramBotConfig
    { telegramBotConfig'dbName :: String
    } deriving (Show)


$(deriveJSON dropPrefixOptions     ''BotSettings)
$(deriveJSON dropPrefixOptions     ''TelegramBotConfig)
$(deriveJSON dropPrefixOptions     ''BotSpec)
