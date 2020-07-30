{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}

module Surbgirq.Bot.Server.Updates where


import qualified Data.Text as T

import Control.Monad.Reader
import Web.Telegram.API.Bot

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Channels
import Surbgirq.Bot.Server.Messages
import Surbgirq.Bot.Server.Queries

------------------------------------------------------------
--
------------------------------------------------------------

handleUpdate :: Update -> Bot ()
handleUpdate update = do
    liftIO $ putStrLn $ "update from bot -> " ++ (show $ update)
    case update of
      Update { message = Just msg } -> handleMessage msg
      Update { channel_post = Just msg } -> handleChannelPost msg
      Update { inline_query = Just iq } -> handleInlineQuery iq
      Update { callback_query = Just cbq } -> handleCallbackQuery cbq
      _ -> liftIO $ putStrLn $ "Handle update failed. " ++ show update








