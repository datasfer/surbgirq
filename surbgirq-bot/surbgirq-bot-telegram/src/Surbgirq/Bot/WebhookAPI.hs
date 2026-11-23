{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}


module Surbgirq.Bot.WebhookAPI where

import Data.Text            (Text)

-- import Web.FBMessenger.API.Bot
-- import Web.FBMessenger.API.Bot.WebhookAPI

import Data.Aeson
import Servant

import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------

-- | POST /tg-webhook: Telegram sends the secret given to setWebhook (secret_token) in the X-Telegram-Bot-Api-Secret-Token
-- header. The body arrives as plain JSON and is decoded in the handler (Surbgirq.Bot.Server.Webhook), so an update this
-- library can't read is logged and answered 200 instead of servant's 400.
type WebHookAPI = "version" :> Get '[JSON] Version
              :<|> "tg-webhook"
                  :> Header "X-Telegram-Bot-Api-Secret-Token" Text
                  :> ReqBody '[JSON] Value
                  :> Post '[JSON] ()
          --     :<|> "fb-webhook" :>
          --          QueryParam "hub.verify_token" Text :>
          --          QueryParam "hub.challenge" Text :>
          --          Get '[PlainText] Text
          --     :<|> "fb-webhook" :>
          --          ReqBody '[JSON] RemoteEventList :>
          --          Post '[PlainText,JSON] Text
