module Surbgirq.Back.Server.WebSocket(
 notifyNewBlock
 ) where
import Control.Concurrent     (threadDelay)
import Control.Monad          (forever)
import Control.Monad.IO.Class (liftIO)
import Data.Text              (pack)
import Network.WebSockets     (forkPingThread)

import qualified Network.WebSockets as WS


import Surbgirq.Back.App.Env

------------------------------------------------------------
--  Web Socket Enpoints implementations
------------------------------------------------------------


notifyNewBlock :: WS.Connection -> AppM ()
notifyNewBlock c = do
  liftIO $ forkPingThread c 10
  _ <- forever $ liftIO $ WS.sendTextData c (pack $ show 1000) >> threadDelay 1000000
  return ()
