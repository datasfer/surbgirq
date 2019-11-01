{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

{-|
Module      : Surbgirq.Back.App
Description : Transform servant api to wai web applicaton

Transform servant api to wai web applicaton
-}

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

import Servant.Swagger.UI
import Servant.Swagger.UI.JensOleG

import Surbgirq.Back.Api
import Surbgirq.Back.App.Env
import Surbgirq.Back.Server
import Surbgirq.Back.Swagger.Doc


------------------------------------------------------------
--
------------------------------------------------------------

-- | transform AppM to Handler
nt :: ServerEnv -> AppM a -> Handler a
-- nt s = flip runReaderT s . unAppM
nt e = runStdoutLoggingT . flip runReaderT e . unAppM

app :: ServerEnv -> Application
app env = simpleCors $ logStdoutDev $
          serve (Proxy :: Proxy SurbgirqAPISwagger) $
          -- jensolegSwaggerSchemaUIServer swaggerDoc
          swaggerSchemaUIServer swaggerDoc
        :<|> (hoistServer api (nt env) surbgirqServer)


