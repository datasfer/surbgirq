{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeFamilies #-}

-- | Client for the Surbgirq web API
module Surbgirq.API.Client where

import Data.Proxy
import Data.Text
import Network.HTTP.Client     (defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.API
import Servant.Client


import Control.Exception
import Control.Monad.Catch
import Control.Monad.Except
import Control.Monad.Reader
import Data.Bifunctor
import Data.ByteString               (ByteString)
import Data.Proxy
import Data.Text                     (Text)
import GHC.Generics
import Servant.API
import Text.InterpolatedString.Perl6 (qc)

import Network.HTTP.Client hiding (Proxy)

import qualified Data.Text      as T


import Servant.Client

import Servant.API.Generic
import Servant.Client.Generic
-- import Servant.Server.Generic

    
import Surbgirq.API
import Surbgirq.Types


-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------

       

api :: Proxy (ToServantApi BookAPI)
api = genericApi (Proxy :: Proxy BookAPI)


