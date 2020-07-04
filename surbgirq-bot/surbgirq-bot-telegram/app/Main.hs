module Main where

import qualified Data.Text as T

import Surbgirq.Bot.Telegram

main :: IO ()
main = do
  putStrLn "Please, enter Telegram bot's API token:"
--  getEnvToken "TELEGRAM_BOT_TOKEN" >>= run
--  token <- T.pack <$> getLine
  startApp -- run $ token
