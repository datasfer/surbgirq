
module Surbgirq.Bot.Server.Webhook where

import Data.Version         (makeVersion, showVersion)
import Web.Telegram.API.Bot (Token(..), Update)


import Control.Monad.Except
import Control.Monad.Reader
import Servant.Server

import qualified Data.Text as T

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Updates
import Surbgirq.Bot.Types
------------------------------------------------------------
--
------------------------------------------------------------


returnVersion :: Bot Version
returnVersion = return version'
  where
    version' = Version $ T.pack $ showVersion $ makeVersion [1,2,3]


handleWebhook :: Update -> Bot ()
handleWebhook update = do
              liftIO $ print "Hook comes"
              Token token <- asks telegramToken
              let b = True -- (EQ == compare secret token)
              liftIO $ print $ show b
--              liftIO $ print $ show secret
              liftIO $ print $ show token

              if b
                 then handleUpdate update
                 else throwError err403
