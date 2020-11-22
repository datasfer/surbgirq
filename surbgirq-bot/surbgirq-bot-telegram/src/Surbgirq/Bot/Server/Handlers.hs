{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE ViewPatterns      #-}

module Surbgirq.Bot.Server.Handlers where


import qualified Data.Text as T

import Control.Monad.Reader

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Handlers.Channels
import Surbgirq.Bot.Server.Handlers.Messages
import Surbgirq.Bot.Server.Handlers.Queries

import Web.Telegram.API.Bot (Update(..))

------------------------------------------------------------
--
------------------------------------------------------------

handleUpdate :: Update -> Bot ()
handleUpdate update = do
    liftIO $ putStrLn "------- Update Start  -------------------"
    liftIO $ putStrLn $ "update from bot -> " ++ (show $ update)
    liftIO $ putStrLn "------- ////End  -------------------"

    case update of
      Update { message = Just msg } -> handleMessage msg
      Update { channel_post = Just msg } -> handleChannelPost msg
      Update { inline_query = Just iq } -> handleInlineQuery iq
      Update { callback_query = Just cbq } -> handleCallbackQuery cbq
      _ -> liftIO $ putStrLn $ "Handle update failed. " ++ show update








