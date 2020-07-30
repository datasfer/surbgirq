{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

{-|
Module      : Surbgirq.Bot.Server
Description : endpoint handlers of telegram bot

Implement local api call endpoints handlers
-}

module Surbgirq.Bot.Server (
                             botServer
                           )where

import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant


import Surbgirq.API.GraphDBClient
import Surbgirq.Bot.Server.Webhook
import Surbgirq.Types

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Updates
import Surbgirq.Bot.WebhookAPI


------------------------------------------------------------
--
------------------------------------------------------------

botServer :: ServerT BotAPI Bot
botServer = returnVersion :<|> handleWebhook


