{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}



module Surbgirq.Bot.Server.Channels where

import qualified Data.Text as T

import Control.Monad.Reader
import Web.Telegram.API.Bot

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Responses
import Surbgirq.Bot.Types

------------------------------------------------------------
--
------------------------------------------------------------

-- Anything that comes in on the channel
handleChannelPost :: Message -> Bot ()
handleChannelPost Message{..} = do
  BotConfig{..} <- ask
  onCommand messageText

  where
    chatId = ChatId $ chat_id chat
    Just messageText = text

    onCommand (T.stripPrefix "/help" -> Just _) = sendHelpMessage chatId
    onCommand _                                 = return ()



