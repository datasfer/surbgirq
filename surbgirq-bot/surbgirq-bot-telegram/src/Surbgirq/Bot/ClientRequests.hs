{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Bot.ClientRequests
Description : calls to surbgirq-graph-api, the REST API over the Neo4j graph

One client for the graph API, made once at start-up from GRAPH_API_URL ('graphApiClient'), and the calls
the bot and the verse explorer make with it.
-}

module Surbgirq.Bot.ClientRequests (
   graphApiClient
 , getBooksHandler
 , getVerseRangeHandler
 , getOneVerseHandler
 , getBookSectionsHandler
 , getChapterSectionsHandler
 , getChapterOneSectionHandler
 , getChapterVerseNumberHandler
 ) where


import Data.List               (dropWhileEnd, isSuffixOf)
import Network.HTTP.Client     (newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.Client          (BaseUrl (..), ClientEnv, ClientM, mkClientEnv, parseBaseUrl, runClientM)
import System.Exit             (die)

import Surbgirq.API.GraphDBClient
import Surbgirq.Types

------------------------------------------------------------
-- The client
------------------------------------------------------------

-- | The client for surbgirq-graph-api at the given URL: the API's root, without @/api@ (the routes add
-- it). It stops the program with a message naming GRAPH_API_URL when the URL isn't usable. Both @http@
-- and @https@ work.
graphApiClient :: String -> IO ClientEnv
graphApiClient url =
  case (parseBaseUrl url :: Maybe BaseUrl) of
    Nothing -> die $ "GRAPH_API_URL is not a valid http or https URL: " <> url
    Just base
      | "/api" `isSuffixOf` dropWhileEnd (== '/') (baseUrlPath base) ->
          die $ "GRAPH_API_URL must be the API's root, without /api at the end (the routes add it): " <> url
      | otherwise -> do
          mgr <- newManager tlsManagerSettings
          pure (mkClientEnv mgr base)

-- | Runs one call. A failed call still ends in 'error' until the bot learns to always answer 200
-- (Revival, step 3).
runGraphCall :: ClientEnv -> ClientM a -> IO a
runGraphCall env request = do
  res <- runClientM request env
  case res of
    Left e  -> error $ show e
    Right a -> pure a

------------------------------------------------------------
-- The calls
------------------------------------------------------------

getBooksHandler :: ClientEnv -> TranslationID -> IO [Book]
getBooksHandler env translation =
  runGraphCall env $ getAllBooks' translation

getVerseRangeHandler :: ClientEnv -> TranslationID -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum -> IO [Verse]
getVerseRangeHandler env translation girq ch v1 v2 =
  runGraphCall env $ getVerseRange' translation girq ch v1 v2

getOneVerseHandler :: ClientEnv -> TranslationID -> Girq -> ChapterNum -> VerseNum -> IO [Verse]
getOneVerseHandler env translation girq ch v1 =
  runGraphCall env $ getOneVerse' translation girq ch v1

-- | Sections
getBookSectionsHandler :: ClientEnv -> TranslationID -> Girq -> IO [Section]
getBookSectionsHandler env translation girq =
  runGraphCall env $ getBookSections' translation girq

getChapterSectionsHandler :: ClientEnv -> TranslationID -> Girq -> ChapterNum -> IO [Section]
getChapterSectionsHandler env translation girq ch =
  runGraphCall env $ getChapterSections' translation girq ch

getChapterOneSectionHandler :: ClientEnv -> TranslationID -> Girq -> ChapterNum -> SectionNum -> IO [Section]
getChapterOneSectionHandler env translation girq ch sec =
  runGraphCall env $ getChapterOneSection' translation girq ch sec

getChapterVerseNumberHandler :: ClientEnv -> TranslationID -> Girq -> ChapterNum -> IO Int
getChapterVerseNumberHandler env translation girq ch =
  runGraphCall env $ getChapterVerseNumber' translation girq ch
