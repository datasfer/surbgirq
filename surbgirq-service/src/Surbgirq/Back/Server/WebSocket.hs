{-|
Module      : Surbgirq.Back.Server.WebSocket
Description : Web Socket Service

Web Socket Service
-}

module Surbgirq.Back.Server.WebSocket(
  notifyNewX
 ) where
import Control.Concurrent     (threadDelay)
import Control.Monad          (forever)
import Control.Monad.IO.Class (liftIO)
import Data.Text              (pack)
import Network.WebSockets     (withPingThread)

import qualified Network.WebSockets as WS


import Surbgirq.Back.App.Env

------------------------------------------------------------
--  Web Socket Enpoints implementations
------------------------------------------------------------

-- | web socket handler sample
notifyNewX :: WS.Connection -> AppM ()
notifyNewX c = do
  liftIO . withPingThread c 10 (pure ()) . forever $ do
    _ <- forever $ liftIO $ WS.sendTextData c (pack $ show 1000) >> threadDelay 1000000
    return ()
