{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}


module Surbgirq.Bot.WebhookAPI where

import Data.Text            (Text)
import Web.Telegram.API.Bot (Update)

import Web.FBMessenger.API.Bot
import Web.FBMessenger.API.Bot.WebhookAPI

import Data.Aeson
import Servant

import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------

type WebHookAPI = "version" :> Get '[JSON] Version
              :<|> "goat"
                       -- :> Capture "secret" Text
                  :> ReqBody '[JSON] Update
                  :> Post '[JSON] ()
              :<|> "webhook" :>
                   QueryParam "hub.verify_token" Text :>
                   QueryParam "hub.challenge" Text :>
                   Get '[PlainText] Text
              :<|> "webhook" :>
                   ReqBody '[JSON] RemoteEventList :>
                   Post '[PlainText,JSON] Text
