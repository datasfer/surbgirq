{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}

module Surbgirq.Bot.Server.Handlers where


import qualified Data.Text as T

import Control.Monad.Reader

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Handlers.CallbackQueries
import Surbgirq.Bot.Server.Handlers.Channels
import Surbgirq.Bot.Server.Handlers.InlineQueries
import Surbgirq.Bot.Server.Handlers.Messages

import Web.Telegram.API.Bot (Update(..))

------------------------------------------------------------
--
------------------------------------------------------------

handleUpdate :: Update -> Bot ()
handleUpdate update = do
    case update of
      Update { message = Just msg } -> handleMessage msg
      Update { channel_post = Just msg } -> handleChannelPost msg
      Update { inline_query = Just iq } -> handleInlineQuery iq
      Update { callback_query = Just cbq } -> handleCallbackQuery cbq
      _ -> liftIO $ putStrLn "Unhandled update type"








