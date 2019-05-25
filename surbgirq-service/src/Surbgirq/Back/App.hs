{-# LANGUAGE DataKinds     #-}

{-# LANGUAGE TypeOperators #-}
module Surbgirq.Back.App (
   app
 , module Env
) where

import Servant

import Control.Monad.IO.Class
import Control.Monad.Logger
import Control.Monad.Reader

import Network.Wai                          (Application)
import Network.Wai.Middleware.Cors          (simpleCors)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)

import qualified Surbgirq.Back.App.Env as Env

import Surbgirq.Back.Api
import Surbgirq.Back.App.Env
import Surbgirq.Back.Server

------------------------------------------------------------
--
------------------------------------------------------------

-- | transform AppM to Handler
nt :: ServerEnv -> AppM a -> Handler a
-- nt s = flip runReaderT s . unAppM
nt e = runStdoutLoggingT . flip runReaderT e . unAppM

app :: ServerEnv -> Application
app env = simpleCors $ logStdoutDev $
          serve api $ hoistServer api (nt env) server
