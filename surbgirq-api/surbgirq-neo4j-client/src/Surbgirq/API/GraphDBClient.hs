{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators     #-}
-- | Client for the Surbgirq neo4j graph db web API
module Surbgirq.API.GraphDBClient
    ( getAllBooks'
    , getVerseRange'
    , getOneVerse'
    , getChapterSections'
    , getChapterOneSection'
    , getBookSections'
    , getChapterVerseNumber'
    )where

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

import Surbgirq.API
import Surbgirq.Types

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

-- | Api schema of .net core web api, that expose neo4j data
-- haskell neo4j driver doesnot support neo4j 4.* this is the reason
-- we develope net core web api to get neo4j data
type GraphDBLocalAPI =
         "scripture" :> "translation" :> Capture "translation" TranslationID :> "books" :> Get '[JSON] [Book]
--    :<|> GetVerseRange -- /chapter/verse/matthew/1/1/10"
       :<|> "scripture" :> Capture "translation" TranslationID
                 :> "books" :> Capture "girq" Girq
                 :> "chapters" :> Capture "ch" ChapterNum
                 :> "verses" :> Capture "verseFrom" VerseNum
--                 :> "to" :> Capture "verseTo" VerseNum
                 :> QueryParam "v2" VerseNum
                 :> Get '[JSON] [Verse]
       :<|> "scripture" :> Capture "translation" TranslationID
                 :> "books" :> Capture "girq" Girq
                 :> "chapters" :> Capture "ch" ChapterNum
                 :> "oneverse" :> Capture "verseNum" VerseNum
                 :> Get '[JSON] [Verse]
       :<|> "scripture" :> Capture "translation" TranslationID :> Summary "Get chapter's sections"
                 :> "books" :> Capture "girq" Girq
                 :> "chapters" :> Capture "ch" ChapterNum
                 :> "sections"
                 :> Get '[JSON] [Section]
       :<|> "scripture" :> Capture "translation" TranslationID :> Summary "Get chapter's sections by sec num"
                 :> "books" :> Capture "girq" Girq
                 :> "chapters" :> Capture "ch" ChapterNum
                 :> "sections" :> Capture "secNum" SectionNum
                 :> Get '[JSON] [Section]
       :<|> "scripture" :> Capture "translation" TranslationID :> Summary "Get Book's section"
                 :> "books" :> Capture "girq" Girq
                 :> "sections"
                 :> Get '[JSON] [Section]
       :<|> "scripture" :> "book" :> Summary "Get book's chapter's verse count"
                 :> Capture "girq" Girq
                 :> "chapter" :> Capture "ch" ChapterNum
                 :> "verses" :> "count"
                 :> Get '[JSON] Int


--    :<|> "chapters" :> Get '[JSON] [Chapter]
 --   :<|> "chapter" :> Capture "num" ChapterNum :> Get '[JSON] Chapter

-- curl -X GET "https://localhost:33011/scripture/books/Matthew/chapters/3/verses/1/to/12?language=Grabar" -H "accept: */*"

graphDBAPI :: Proxy GraphDBLocalAPI
graphDBAPI = Proxy


neo4jApiBaseUrl :: BaseUrl
neo4jApiBaseUrl = BaseUrl Https "127.0.0.1" 33011 "/api"

getAllBooks' :: TranslationID -> ClientM [Book]
getVerseRange' :: TranslationID -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum -> ClientM [Verse]
getOneVerse' :: TranslationID -> Girq -> ChapterNum -> VerseNum -> ClientM [Verse]
getChapterSections' :: TranslationID -> Girq -> ChapterNum -> ClientM [Section]
getChapterOneSection' :: TranslationID -> Girq -> ChapterNum -> SectionNum -> ClientM [Section]
getBookSections' :: TranslationID -> Girq ->  ClientM [Section]
getChapterVerseNumber' :: Girq -> ChapterNum -> ClientM Int

( getAllBooks'
 :<|> getVerseRange'
 :<|> getOneVerse'
 :<|> getChapterSections'
 :<|> getChapterOneSection'
 :<|> getBookSections'
 :<|> getChapterVerseNumber'
    ) = client graphDBAPI




-- getAllBooks
--   :: Manager
--   -> IO (Either ClientError [Book])
-- getAllBooks mgr = runClientM getAllBooks'
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)



-- getVerseRange
--   :: Manager
--   -> Dialect -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum
--   -> IO (Either ClientError [Verse])
-- getVerseRange mgr dialect girq ch from to = runClientM (getVerseRange' dialect girq ch from to)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)


-- getOneVerse
--   :: Manager
--   -> Dialect -> Girq -> ChapterNum -> VerseNum
--   -> IO (Either ClientError [Verse])
-- getOneVerse mgr dialect girq ch from = runClientM (getOneVerse' dialect girq ch from)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)



-- getBookSections
--   :: Manager
--   -> Dialect -> Girq
--   -> IO (Either ClientError [Section])
-- getBookSections mgr dialect girq = runClientM (getBookSections' dialect girq)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)

-- getChapterSections
--   :: Manager
--   -> Dialect -> Girq -> ChapterNum
--   -> IO (Either ClientError [Section])
-- getChapterSections mgr dialect girq ch = runClientM (getChapterSections' dialect girq ch)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)

-- getChapterOneSection
--   :: Manager
--   -> Dialect -> Girq -> ChapterNum -> SectionNum
--   -> IO (Either ClientError [Section])
-- getChapterOneSection mgr dialect girq ch sec = runClientM (getChapterOneSection' dialect girq ch sec)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)


-- getChapterVerseNumber
--   :: Manager
--   -> Girq -> ChapterNum
--   -> IO (Either ClientError Int)
-- getChapterVerseNumber mgr girq ch = runClientM (getChapterVerseNumber' girq ch)
--                                    (ClientEnv mgr neo4jApiBaseUrl Nothing)
