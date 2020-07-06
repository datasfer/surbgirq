{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}
-- | Client for the Surbgirq neo4j graph db web API
module Surbgirq.API.GraphDBClient where

import Control.Applicative
import Control.Monad
import Control.Monad.IO.Class
-- import Control.Monad.Trans.Either
-- import Data.Aeson
import Data.Monoid
import Data.Proxy
import GHC.Generics
import Servant.API
import Servant.Client

import Data.Text           (Text)
import Network.HTTP.Client (Manager)

import qualified Data.Text    as T
import qualified Data.Text.IO as T

import Surbgirq.Types
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------


type GraphDBLocalAPI =
         "Scripture" :> "books" :> Get '[JSON] [Book]
--    :<|> "chapters" :> Get '[JSON] [Chapter]
 --   :<|> "chapter" :> Capture "num" ChapterNum :> Get '[JSON] Chapter


graphDBAPI :: Proxy GraphDBLocalAPI
graphDBAPI = Proxy


neo4jApiBaseUrl :: BaseUrl
neo4jApiBaseUrl = BaseUrl Https "127.0.0.1" 33011 "/api"

getAllBooks' :: ClientM [Book]
getAllBooks' = client graphDBAPI



getAllBooks
  :: Manager
  -> IO (Either ClientError [Book])
getAllBooks mgr = runClientM getAllBooks'
                                   (ClientEnv mgr neo4jApiBaseUrl Nothing)



