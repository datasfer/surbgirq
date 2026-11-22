{-# LANGUAGE ApplicativeDo     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Main where

import qualified Data.Text as T

import Options.Applicative

import Data.Aeson  (FromJSON)
import Data.Monoid ((<>))

import Common.Aeson
import Common.Yaml
import Sigterm
import Surbgirq.Bot.ClientRequests (graphApiClient)
import Surbgirq.Bot.Telegram
import Types.BotSettings

------------------------------------------------------------
-- Start Telegram bot webhook
------------------------------------------------------------

main :: IO ()
main = do
  installSigtermHandler
  bot@BotSettings{..} <- getBotSettings "Bots Config"
  let dbName = telegramBotConfig'dbName $ bot'telegram surbgirq'bots
      botApiHost = telegramBotConfig'botApiHost $ bot'telegram surbgirq'bots
      botApiPort = telegramBotConfig'botApiPort $ bot'telegram surbgirq'bots
      graphApiUrl = telegramBotConfig'graphApiUrl $ bot'telegram surbgirq'bots

  putStrLn "Please, enter Telegram bot's API token:"
  putStrLn $ mconcat [" with db: ", dbName]
  putStrLn $ show bot
--  getEnvToken "TELEGRAM_BOT_TOKEN" >>= run
--  token <- T.pack <$> getLine
  graphApi <- graphApiClient graphApiUrl
  startApp graphApi dbName botApiHost botApiPort  -- run $ token


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
