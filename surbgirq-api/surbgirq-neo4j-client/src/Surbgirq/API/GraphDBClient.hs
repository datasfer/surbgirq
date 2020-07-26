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
import Surbgirq.API

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------


type GraphDBLocalAPI =
         "scripture" :> "books" :> Get '[JSON] [Book]
--    :<|> GetVerseRange -- /chapter/verse/matthew/1/1/10"
       :<|> "scripture" :> Capture "dialect" Dialect
                 :> "books" :> Capture "girq" Girq
                 :> "chapters" :> Capture "ch" ChapterNum
                 :> "verses" :> Capture "verseFrom" VerseNum
--                 :> "to" :> Capture "verseTo" VerseNum
                 :> QueryParam "to" VerseNum
                 :> Get '[JSON] [Verse]

  
--    :<|> "chapters" :> Get '[JSON] [Chapter]
 --   :<|> "chapter" :> Capture "num" ChapterNum :> Get '[JSON] Chapter

-- curl -X GET "https://localhost:33011/scripture/books/Matthew/chapters/3/verses/1/to/12?language=Grabar" -H "accept: */*"

graphDBAPI :: Proxy GraphDBLocalAPI
graphDBAPI = Proxy


neo4jApiBaseUrl :: BaseUrl
neo4jApiBaseUrl = BaseUrl Https "127.0.0.1" 33011 "/api"

getAllBooks' :: ClientM [Book]
getVerseRange' :: Dialect -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum -> ClientM [Verse]
                

(getAllBooks' :<|> getVerseRange') = client graphDBAPI




getAllBooks
  :: Manager
  -> IO (Either ClientError [Book])
getAllBooks mgr = runClientM getAllBooks'
                                   (ClientEnv mgr neo4jApiBaseUrl Nothing)



getVerseRange
  :: Manager
  -> Dialect -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum 
  -> IO (Either ClientError [Verse])
getVerseRange mgr dialect girq ch from to = runClientM (getVerseRange' dialect girq ch from to) 
                                   (ClientEnv mgr neo4jApiBaseUrl Nothing)
