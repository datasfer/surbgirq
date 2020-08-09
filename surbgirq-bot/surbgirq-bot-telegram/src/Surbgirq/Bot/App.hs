


module Surbgirq.Bot.App where

import Control.Monad.Reader (runReaderT)
import Servant
import Servant.Server       (Application, Handler)

import Surbgirq.Bot.Monad
import Surbgirq.Bot.Server
import Surbgirq.Bot.Types
import Surbgirq.Bot.WebhookAPI

------------------------------------------------------------
--
------------------------------------------------------------

app :: BotConfig -> Application
app config = serve botApi $ initBotServer config


nt :: BotConfig -> Bot a -> Handler a
nt s = flip runReaderT s . runBot


initBotServer :: BotConfig -> Server WebHookAPI
initBotServer config = hoistServer botApi (nt config) botServer
    -- where transform :: BotConfig -> Bot -> Handler
    --       transform config = NT (flip runReaderT config . runBot)


botApi :: Proxy WebHookAPI
botApi = Proxy



