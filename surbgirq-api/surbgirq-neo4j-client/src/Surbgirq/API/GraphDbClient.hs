{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}

-- | Client for the Surbgirq neo4j graph db web API
module Surbgirq.API.GraphDbClient where

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
import qualified Servant.Client as C

-- import Surbgirq.API
-- import Surbgirq.Types

-- -- | Errors in 'ClientM' monad
-- data ClientError = InvalidBaseUrl !Text | ClientError !C.ClientError
--   deriving (Eq, Show, Generic)

-- instance Exception C.ClientError


-- myApi :: Proxy SurbgirqAPI
-- myApi = Proxy

-- -- 'client' allows you to produce operations to query an API from a client.
-- postNewBook :: Book -> ClientM Book
-- getAllBooks :: ClientM [Book]
-- (getAllBooks :<|> postNewBook) = client SurbgirqAPI

