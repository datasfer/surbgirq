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

import Data.Text               (Text)
import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)

import Servant


import Surbgirq.API.GraphDBClient
import Surbgirq.Bot.FB.Server.Webhook
import Surbgirq.Bot.Server.Webhook
import Surbgirq.Types

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Handlers
import Surbgirq.Bot.WebhookAPI


------------------------------------------------------------
--
------------------------------------------------------------

botServer :: Text -> Text -> ServerT WebHookAPI Bot
botServer verifyTokenStored pageTokenStored  = returnVersion :<|> handleWebhook :<|> webhook_verify verifyTokenStored :<|> webhook_message pageTokenStored


