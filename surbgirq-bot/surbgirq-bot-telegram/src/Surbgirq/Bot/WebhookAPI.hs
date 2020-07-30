{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}


module Surbgirq.Bot.WebhookAPI where

import Web.Telegram.API.Bot (Update)

import Data.Aeson
import Servant

import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------

type BotAPI = "version" :> Get '[JSON] Version
              :<|> "goat"
--              :> Capture "secret" Text
              :> ReqBody '[JSON] Update
              :> Post '[JSON] ()
