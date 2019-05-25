{-# LANGUAGE DataKinds   #-}
{-# LANGUAGE TypeOperators   #-}

module Surbgirq.API.WebSocket where

import Servant.API
import Servant.API.WebSocket (WebSocket)

------------------------------------------------------------
-- Bex web sockets endpoints
------------------------------------------------------------


type NotifyNewBlockWsEndpoint = "channels" :> "notify-new" :> WebSocket


type BexWebSocketAPI = "block" :> (
        NotifyNewBlockWsEndpoint
  )
