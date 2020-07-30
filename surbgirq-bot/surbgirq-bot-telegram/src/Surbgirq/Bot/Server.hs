{-# LANGUAGE DataKinds #-}

{-|
Module      : Surbgirq.Bot.Server
Description : endpoint handlers to call the local neo4j db acccess api

Implement local api call endpoints handlers
-}

module Surbgirq.Bot.Server (
   getBooksHandler
 , getVerseRangeHandler
 , getOneVerseHandler

 -- , bookChapterNums
 -- , bookChapterSectionNums
 -- , bookChapterVerseNums
 ) where


import Network.HTTP.Client     (Manager, defaultManagerSettings, newManager)
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Servant.Client


-- import Surbgirq.API.Client
import Surbgirq.API.GraphDBClient
import Surbgirq.Types

------------------------------------------------------------
--
------------------------------------------------------------


getBooksHandler :: IO [Book]
getBooksHandler = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getAllBooks' -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a



getVerseRangeHandler :: Dialect -> Girq -> ChapterNum -> VerseNum -> Maybe VerseNum -> IO [Verse]
getVerseRangeHandler dialect girq ch v1 v2 = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getVerseRange' dialect girq ch v1 v2 -- mgr
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a


getOneVerseHandler :: Dialect -> Girq -> ChapterNum -> VerseNum -> IO [Verse]
getOneVerseHandler dialect girq ch v1 = do
  env <-  mkClientEnv <$> newManager defaultManagerSettings <*> parseBaseUrl "http://localhost:33010"
  mgr <-  newManager tlsManagerSettings
  mres <- flip runClientM env $ getOneVerse' dialect girq ch v1
  case mres of
    Left e  -> error $ show e -- throwIO $ ClientError e
    Right a -> pure a
