
module Surbgirq.Bot.Server.Webhook where

import Data.Version                    (makeVersion, showVersion)
import Surbgirq.Bot.Server.TelegramAPI (Token(..), Update)


import Control.Monad.Except
import Control.Monad.Reader
import Servant.Server

import Data.IORef

import qualified Data.ByteString.Lazy.Char8 as C
import qualified Data.Text                  as T

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server.Handlers
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

              let b = True -- (EQ == compare secret token)

              if b
                 then handleUpdate update
                 else throwError err403


