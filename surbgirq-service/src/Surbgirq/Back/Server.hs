{-# LANGUAGE TypeOperators #-}

module Surbgirq.Back.Server where

import Servant

import Surbgirq.Back.Api
import Surbgirq.Back.App.Env
import Surbgirq.Back.Server.Rest
import Surbgirq.Back.Server.WebSocket

------------------------------------------------------------
--
------------------------------------------------------------

server :: ServerT BexAPI AppM
server =  (getApiInfoHandler :<|> getBooksHandler :<|> getChapterHandler)
          :<|> notifyNewBlock
