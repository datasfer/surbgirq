{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import           Data.Char          (isAlphaNum, isAscii, isDigit)
import qualified Data.Text          as T
import           System.Environment (lookupEnv)
import           System.Exit        (die)

import Options.Applicative

import Data.Aeson  (FromJSON)

import Common.Aeson
import Common.Yaml
import Sigterm
import Surbgirq.Bot.ClientRequests (graphApiClient)
import Surbgirq.Bot.Telegram
import Surbgirq.Types              (TranslationID, findTransByAbbr)
import Types.BotSettings

------------------------------------------------------------
-- Start Telegram bot webhook
------------------------------------------------------------

-- | The settings come from config/bot-settings.yaml, where an environment variable overrides each value;
-- the two secrets come from the environment only (see .env.example). Nothing secret is printed.
main :: IO ()
main = do
  installSigtermHandler
  BotSettings{..} <- getBotSettings "Bots Config"
  let tg = bot'telegram surbgirq'bots
  token <- requireSecret "TELEGRAM_BOT_TOKEN" isBotToken
             "doesn't look like a bot token: digits, a colon, then the key, without the \"bot\" prefix"
  secret <- requireSecret "TELEGRAM_WEBHOOK_SECRET" isWebhookSecret
              "must be 1 to 256 characters: letters, digits, _ and -"
  graphApi <- graphApiClient (telegramBotConfig'graphApiUrl tg)
  defaultBible <- requireTranslation "BOT_DEFAULT_BIBLE" (telegramBotConfig'defaultBible tg)
  defaultNarek <- requireTranslation "BOT_DEFAULT_NAREK" (telegramBotConfig'defaultNarek tg)
  putStrLn $ "Surbgirq bot: the graph API at " <> telegramBotConfig'graphApiUrl tg
             <> "; default texts " <> show defaultBible <> " and " <> show defaultNarek
  startApp StartSettings
    { start'telegramApiHost = telegramBotConfig'botApiHost tg
    , start'telegramApiPort = telegramBotConfig'botApiPort tg
    , start'graphApi        = graphApi
    , start'defaultBible    = defaultBible
    , start'defaultNarek    = defaultNarek
    , start'listenHost      = telegramBotConfig'listenHost tg
    , start'listenPort      = telegramBotConfig'listenPort tg
    , start'token           = token
    , start'webhookSecret   = secret
    }


-- | A secret from the environment. It stops the program with a message naming the variable when the value
-- is missing, empty or malformed; the message never shows the value. Surrounding spaces and a trailing CR
-- (a .env file saved on Windows) are stripped.
requireSecret :: String -> (T.Text -> Bool) -> String -> IO T.Text
requireSecret name isValid problem = do
  value <- fmap (T.strip . T.pack) <$> lookupEnv name
  case value of
    Nothing -> die $ name <> " is not set (see .env.example)"
    Just v
      | T.null v        -> die $ name <> " is empty (see .env.example)"
      | not (isValid v) -> die $ name <> " " <> problem
      | otherwise       -> pure v

-- | A default translation from bot-settings.yaml, or from its environment variable. It stops the program with a message
-- naming the variable when the value isn't a translation the bot knows; the value isn't secret, so the message shows it.
requireTranslation :: String -> T.Text -> IO TranslationID
requireTranslation name value =
  case findTransByAbbr (T.strip value) of
    Just translation -> pure translation
    Nothing          -> die $ name <> " is not a translation the bot knows: \"" <> T.unpack value
                              <> "\" (an ID such as v1805-T or e1994-T; see docs/bot.md)"

-- | Digits (the bot's ID), a colon, then the key: ASCII letters, digits, _ and -.
isBotToken :: T.Text -> Bool
isBotToken t =
  let (botId, rest) = T.breakOn ":" t
      key           = T.drop 1 rest
  in  not (T.null botId) && T.all isDigit botId && T.length key >= 30 && T.all isTokenChar key

-- | Telegram's rule for a webhook's secret_token: 1 to 256 characters, ASCII letters, digits, _ and -.
isWebhookSecret :: T.Text -> Bool
isWebhookSecret t = T.length t <= 256 && T.all isTokenChar t

isTokenChar :: Char -> Bool
isTokenChar c = (isAscii c && isAlphaNum c) || c == '_' || c == '-'


data CmdOptions = CmdOptions
               { cmdConfigPath :: FilePath
               }

getBotSettings :: (FromJSON a) => String -> IO a
getBotSettings cmdHeader = do
  cmd <- customExecParser (prefs showHelpOnError)
            $ info (helper <*> parser)
              (  fullDesc
              <> header cmdHeader
              <> progDesc ""
              )
  case cmd of
    CmdOptions{..} -> do
      botSettings     <- readYaml cmdConfigPath
      return botSettings


parser :: Parser CmdOptions
parser = do
  cmdConfigPath <- strArgument
    (  metavar "PATH"
    <> help "Path to bots settings"
    <> value "config/bot-settings.yaml"
    <> showDefault
    )
  return CmdOptions{..}
