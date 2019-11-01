{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

{-|
Module      : Surbgirq.API.WebSocket
Description : Web socket endpoints

Web socket endpoint strucutre, at this moment not used
-}

module Surbgirq.API.WebSocket (
   SurbgirqWebSocketAPI(..)
    )where

import Servant.API
import Servant.API.WebSocket (WebSocket)

------------------------------------------------------------
-- Surbgirq web sockets endpoints
------------------------------------------------------------


type NotifyDailyReadEndpoint = "channels" :> "notify-dailty-read" :> WebSocket


type SurbgirqWebSocketAPI = "girq" :> NotifyDailyReadEndpoint
